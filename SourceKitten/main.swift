//
//  main.swift
//  sourcekitten
//
//  Created by JP Simard on 10/15/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

import Foundation
import XPC

// MARK: Helper Functions

/**
Print error message to STDERR
*/
func error(message: String) {
    let stderr = NSFileHandle.fileHandleWithStandardError()
    stderr.writeData(message.dataUsingEncoding(NSUTF8StringEncoding)!)
    exit(1)
}

/**
Run `xcodebuild clean build -dry-run` along with any passed in build arguments.
Return STDERR and STDOUT as a combined string.
*/
func run_xcodebuild() -> String? {
    let task = NSTask()
    task.launchPath = "/usr/bin/xcodebuild"

    // Forward arguments to xcodebuild
    var arguments = Process.arguments
    arguments.removeAtIndex(0)
    arguments.extend(["clean", "build", "-dry-run"])
    task.arguments = arguments

    let pipe = NSPipe()
    task.standardOutput = pipe
    task.standardError = pipe

    task.launch()

    let file = pipe.fileHandleForReading
    let xcodebuildOutput = NSString(data: file.readDataToEndOfFile(), encoding: NSUTF8StringEncoding)
    file.closeFile()

    return xcodebuildOutput
}

/**
Parses the compiler arguments needed to compile the Swift aspects of an Xcode project
*/
func swiftc_arguments_from_xcodebuild_output(xcodebuildOutput: NSString) -> [String]? {
    let regex = NSRegularExpression(pattern: "/usr/bin/swiftc.*", options: NSRegularExpressionOptions(0), error: nil)!
    let range = NSRange(location: 0, length: xcodebuildOutput.length)
    let regexMatch = regex.firstMatchInString(xcodebuildOutput, options: NSMatchingOptions(0), range: range)

    if let regexMatch = regexMatch {
        let escapedSpacePlaceholder = "\u{0}"
        var args = xcodebuildOutput
            .substringWithRange(regexMatch.range)
            .stringByReplacingOccurrencesOfString("\\ ", withString: escapedSpacePlaceholder)
            .componentsSeparatedByString(" ")

        args.removeAtIndex(0) // Remove swiftc

        args.map {
            $0.stringByReplacingOccurrencesOfString(escapedSpacePlaceholder, withString: " ")
        }

        return args.filter { $0 != "-parseable-output" }
    }

    return nil
}

/**
Print XML-formatted docs for the specified Xcode project
*/
func print_docs_for_swift_compiler_args(arguments: [String]) {
    println("<jazzy>") // Opening XML tag

    sourcekitd_initialize()

    // Only create the XPC array of compiler arguments once, to be reused for each request
    let compilerArgs = (arguments as NSArray).newXPCObject()

    // Filter the array of compiler arguments to extract the Xcode project's Swift files
    let swiftFiles = arguments.filter {
        $0.rangeOfString(".swift", options: (.BackwardsSearch | .AnchoredSearch)) != nil
    }

    // Print docs for each Swift file
    for file in swiftFiles {
        // Keep track of XML documentation we've already printed
        var seenDocs = Array<String>()

        // Construct a SourceKit request for getting the "full_as_xml" docs
        let cursorInfoRequest = xpc_dictionary_create(nil, nil, 0)
        xpc_dictionary_set_uint64(cursorInfoRequest, "key.request", sourcekitd_uid_get_from_cstr("source.request.cursorinfo"))
        xpc_dictionary_set_value(cursorInfoRequest, "key.compilerargs", compilerArgs)
        xpc_dictionary_set_string(cursorInfoRequest, "key.sourcefile", file)

        let fileLength = countElements(String(contentsOfFile: file, encoding: NSUTF8StringEncoding, error: nil)!)

        // Send "cursorinfo" SourceKit request for each cursor position in the current file.
        //
        // This is the same request triggered by Option-clicking a token in Xcode,
        // so we are also generating documentation for code that is external to the current project,
        // which is why we filter out docs from outside this file.
        for cursor in 0..<Int64(fileLength) {
            xpc_dictionary_set_int64(cursorInfoRequest, "key.offset", cursor)

            // Send request and wait for response
            let response = sourcekitd_send_request_sync(cursorInfoRequest)
            if !sourcekitd_response_is_error(response) {
                // Grab XML from response
                let xml = xpc_dictionary_get_string(response, "key.doc.full_as_xml")
                if xml != nil {
                    // Print XML docs if we haven't already & only if it relates to the current file we're documenting
                    let xmlString = String(UTF8String: xml)!
                    if !contains(seenDocs, xmlString) && xmlString.rangeOfString(" file=\"\(file)\"") != nil {
                        println(xmlString)
                        seenDocs.append(xmlString)
                    }
                }
            }
        }
    }

    println("</jazzy>") // Closing XML tag
}

// MARK: Main Program

/**
Print XML-formatted docs for the specified Xcode project,
or Xcode output if no Swift compiler arguments were found.
*/
func main() {
    if let xcodebuildOutput = run_xcodebuild() {
        if let swiftcArguments = swiftc_arguments_from_xcodebuild_output(xcodebuildOutput) {
            print_docs_for_swift_compiler_args(swiftcArguments)
        } else {
            error(xcodebuildOutput)
        }
    } else {
        error("Xcode build output could not be read")
    }
}

main()

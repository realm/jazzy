//
//  main.swift
//  sourcekitten
//
//  Created by JP Simard on 10/15/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

import Foundation
import XPC

// MARK: Syntax

/**
Print syntax highlighting information as JSON to STDOUT

:param: file Path to the file to parse for syntax highlighting information
*/
func printSyntaxHighlighting(#file: String) {
    // Construct a SourceKit request for getting general info about the Swift file passed as argument
    let request = xpc_dictionary_create(nil, nil, 0)
    xpc_dictionary_set_uint64(request, "key.request", sourcekitd_uid_get_from_cstr("source.request.editor.open"))
    xpc_dictionary_set_string(request, "key.name", "")
    xpc_dictionary_set_string(request, "key.sourcefile", file)

    // Initialize SourceKit XPC service
    sourcekitd_initialize()

    // Send SourceKit request
    let response = sourcekitd_send_request_sync(request)
    printSyntaxHighlighting(response)
}

/**
Print syntax highlighting information as JSON to STDOUT

:param: text Swift source code to parse for syntax highlighting information
*/
func printSyntaxHighlighting(#text: String) {
    // Construct a SourceKit request for getting general info about the Swift source text passed as argument
    let request = xpc_dictionary_create(nil, nil, 0)
    xpc_dictionary_set_uint64(request, "key.request", sourcekitd_uid_get_from_cstr("source.request.editor.open"))
    xpc_dictionary_set_string(request, "key.name", "")
    xpc_dictionary_set_string(request, "key.sourcetext", text)

    // Initialize SourceKit XPC service
    sourcekitd_initialize()

    // Send SourceKit request
    let response = sourcekitd_send_request_sync(request)
    printSyntaxHighlighting(response)
}

/**
Print syntax highlighting information as JSON to STDOUT

:param: sourceKitResponse XPC object returned from SourceKit "editor.open" call
*/
func printSyntaxHighlighting(sourceKitResponse: xpc_object_t) {
    // Get syntaxmap XPC data
    let xpcData = xpc_dictionary_get_value(sourceKitResponse, "key.syntaxmap")
    // Convert XPC data to NSData
    let data = NSData(bytes: xpc_data_get_bytes_ptr(xpcData), length: Int(xpc_data_get_length(xpcData)))

    // Get number of syntax tokens
    var tokens = 0
    data.getBytes(&tokens, range: NSRange(location: 8, length: 8))
    tokens = tokens >> 4

    println("[")

    for i in 0..<tokens {
        let parserOffset = 16 * i

        var uid = UInt64(0)
        data.getBytes(&uid, range: NSRange(location: 16 + parserOffset, length: 8))
        let type = String(UTF8String: sourcekitd_uid_get_string_ptr(uid))!

        var offset = 0
        data.getBytes(&offset, range: NSRange(location: 24 + parserOffset, length: 4))

        var length = 0
        data.getBytes(&length, range: NSRange(location: 28 + parserOffset, length: 4))
        length = length >> 1

        print("  {\n    \"type\": \"\(type)\",\n    \"offset\": \(offset),\n    \"length\": \(length)\n  }")

        if i != tokens-1 {
            println(",")
        } else {
            println()
        }
    }

    println("]")
}

// MARK: - Model

/**
Structure to represent 'MARK:'-style section in source code
*/
struct Section {
    let file: String
    let name: String
    let line: UInt
    let hasSeparator: Bool
    let characterIndex: UInt

    func xmlValue() -> String {
        return "<Section file=\"\(file)\" line=\"\(line)\" hasSeparator=\"\(hasSeparator)\">\(name)</Section>"
    }
}

// MARK: - Helper Functions

/**
Print error message to STDERR

:param: error message to print
*/
func error(message: String) {
    let stderr = NSFileHandle.fileHandleWithStandardError()
    stderr.writeData(message.dataUsingEncoding(NSUTF8StringEncoding)!)
    exit(1)
}

/**
Replace all UIDs in a SourceKit response dictionary with their string values.

:param:   dictionary         `NSDictionary` to convert
:param:   declarationOffsets inout `Array` of (`Int64`, `String`) tuples. First value is offset of declaration.
                             Second value is declaration kind (i.e. `source.lang.swift.decl.function.free`).
:returns:                    Input `NSDictionary` with UID's replaced with their string values.
*/
func replaceUIDsWithStringsInDictionary(dictionary: NSDictionary,
    inout #declarationOffsets: [(Int64, String)]) -> NSDictionary {
    let keys = dictionary.allKeys as [String]
    let newDictionary = NSMutableDictionary(dictionary: dictionary)
    for key in keys {
        if key == "key.substructure" || key == "key.attributes" {
            let substructures = dictionary[key] as [NSDictionary]
            let newSubstructures = NSMutableArray()
            for structure in substructures {
                newSubstructures.addObject(replaceUIDsWithStringsInDictionary(structure, declarationOffsets: &declarationOffsets))
            }
            newDictionary[key] = newSubstructures
        } else if dictionary[key]?.isKindOfClass(NSNumber) == true {
            let value = dictionary[key] as NSNumber
            let uintValue = value.unsignedLongLongValue
            if uintValue > 4_300_000_000 { // UID's are all higher than 4.3M
                if let utf8String = sourcekitd_uid_get_string_ptr(uintValue) as UnsafePointer<Int8>? {
                    let uidString = String(UTF8String: utf8String)!
                    newDictionary[key] = uidString
                }
            }
        }
        if key == "key.kind" {
            let kind = newDictionary[key] as String
            if kind.rangeOfString("source.lang.swift.decl.") != nil {
                let offset = (newDictionary["key.nameoffset"] as NSNumber).longLongValue
                if offset > 0 {
                    declarationOffsets.append(offset, kind)
                }
            }
        }
    }
    return newDictionary
}

/**
Run `xcodebuild clean build -dry-run` along with any passed in build arguments.
Return STDERR and STDOUT as a combined string.

:param: processArguments array of arguments to pass to `xcodebuild`
:returns: xcodebuild STDERR+STDOUT output
*/
func run_xcodebuild(processArguments: [String]) -> String? {
    let task = NSTask()
    task.currentDirectoryPath = "/Users/jp/Projects/sourcekitten"
    task.launchPath = "/usr/bin/xcodebuild"

    // Forward arguments to xcodebuild
    var arguments = processArguments
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

:param: xcodebuildOutput output of `xcodebuild` to be parsed for swift compiler arguments
:returns: array of swift compiler arguments
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

:param: arguments compiler arguments to pass to SourceKit
:param: swiftFiles array of Swift file names to document
:returns: XML-formatted string of documentation for the specified Xcode project
*/
func docs_for_swift_compiler_args(arguments: [String], swiftFiles: [String]) -> String {
    sourcekitd_initialize()

    // Create the XPC array of compiler arguments once, to be reused for each request
    var xpcArguments = xpc_array_create(nil, 0)
    for argument in arguments {
        xpc_array_append_value(xpcArguments, xpc_string_create(argument))
    }

    // Construct a SourceKit request for getting general info about a Swift file
    let openRequest = xpc_dictionary_create(nil, nil, 0)
    xpc_dictionary_set_uint64(openRequest, "key.request", sourcekitd_uid_get_from_cstr("source.request.editor.open"))
    xpc_dictionary_set_string(openRequest, "key.name", "")

    var xmlDocs = [String]()

    // Print docs for each Swift file
    for file in swiftFiles {
        xpc_dictionary_set_string(openRequest, "key.sourcefile", file)

        var declarationOffsets = [Int64, String]()

        var openResponse = NSDictionary(contentsOfXPCObject: sourcekitd_send_request_sync(openRequest))
        openResponse = replaceUIDsWithStringsInDictionary(openResponse, declarationOffsets: &declarationOffsets)

        // Construct a SourceKit request for getting cursor info for current cursor position
        let cursorInfoRequest = xpc_dictionary_create(nil, nil, 0)
        xpc_dictionary_set_uint64(cursorInfoRequest, "key.request", sourcekitd_uid_get_from_cstr("source.request.cursorinfo"))
        xpc_dictionary_set_value(cursorInfoRequest, "key.compilerargs", xpcArguments)
        xpc_dictionary_set_string(cursorInfoRequest, "key.sourcefile", file)

        // Send "cursorinfo" SourceKit request for each cursor position in the current file.
        //
        // This is the same request triggered by Option-clicking a token in Xcode,
        // so we are also generating documentation for code that is external to the current project,
        // which is why we filter out docs from outside this file.
        for cursor in declarationOffsets {
            xpc_dictionary_set_int64(cursorInfoRequest, "key.offset", cursor.0)

            // Send request and wait for response
            let response = sourcekitd_send_request_sync(cursorInfoRequest)
            if !sourcekitd_response_is_error(response) && xpc_dictionary_get_count(response) > 0 {
                let xml = xpc_dictionary_get_string(response, "key.doc.full_as_xml")
                if xml != nil {
                    let xmlString = String(UTF8String: xml)!
                    xmlDocs.append(xmlString.stringByReplacingOccurrencesOfString("</Name><USR>", withString: "</Name><Kind>\(cursor.1)</Kind><USR>"))
                } else {
                    let usr = String(UTF8String: xpc_dictionary_get_string(response, "key.usr"))!
                    let name = String(UTF8String: xpc_dictionary_get_string(response, "key.name"))!
                    let decl = String(UTF8String: xpc_dictionary_get_string(response, "key.annotated_decl"))!
                    xmlDocs.append("<Other file=\"\(file)\"><Name>\(name)</Name><Kind>\(cursor.1)</Kind><USR>\(usr)</USR>\(decl)</Other>")
                }
            }
        }
    }

    var docsString = "<jazzy>\n"
    for xml in xmlDocs {
        docsString += "\(xml)\n"
    }
    docsString += "</jazzy>"
    return docsString
}

/**
Returns an array of swift file names in an array

:param: array Array to be filtered
:returns: the array of swift files
*/
func swiftFilesFromArray(array: [String]) -> [String] {
    return array.filter {
        $0.rangeOfString(".swift", options: (.BackwardsSearch | .AnchoredSearch)) != nil
    }
}

// MARK: - Main Program

/**
Print XML-formatted docs for the specified Xcode project,
or Xcode output if no Swift compiler arguments were found.
*/
func main() {
    let arguments = Process.arguments
    if arguments.count > 1 && arguments[1] == "--skip-xcodebuild" {
        var sourcekitdArguments = arguments
        sourcekitdArguments.removeAtIndex(0) // remove sourcekitten
        sourcekitdArguments.removeAtIndex(0) // remove --skip-xcodebuild
        let swiftFiles = swiftFilesFromArray(sourcekitdArguments)
        println(docs_for_swift_compiler_args(sourcekitdArguments, swiftFiles))
    } else if arguments.count == 3 && arguments[1] == "--syntax" {
        printSyntaxHighlighting(file: arguments[2])
    } else if arguments.count == 3 && arguments[1] == "--syntax-text" {
        printSyntaxHighlighting(text: arguments[2])
    } else if let xcodebuildOutput = run_xcodebuild(arguments) {
        if let swiftcArguments = swiftc_arguments_from_xcodebuild_output(xcodebuildOutput) {
            // Extract the Xcode project's Swift files
            let swiftFiles = swiftFilesFromArray(swiftcArguments)

            // FIXME: The following makes things ~30% faster, at the expense of (possibly) not supporting complex project configurations
            // Extract the minimum Swift compiler arguments needed for SourceKit
            var sourcekitdArguments = Array<String>(swiftcArguments[0..<7])
            sourcekitdArguments.extend(swiftFiles)

            println(docs_for_swift_compiler_args(sourcekitdArguments, swiftFiles))
        } else {
            error(xcodebuildOutput)
        }
    } else {
        error("Xcode build output could not be read")
    }
}

main()

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

/// SourceKit UID to String map
var uidStringMap = [UInt64: String]()

/**
Cache SourceKit requests for strings from UIDs

:param: uid UID received from sourcekitd* responses
:returns: Cached UID string if available, other
*/
func stringForSourceKitUID(uid: UInt64) -> String? {
    if uid < 4_300_000_000 {
        // UID's are all higher than 4.3M
        return nil
    } else if let string = uidStringMap[uid] {
        return string
    } else {
        if let uidCString = sourcekitd_uid_get_string_ptr(uid) as UnsafePointer<Int8>? {
            let uidString = String(UTF8String: uidCString)!
            uidStringMap[uid] = uidString
            return uidString
        }
    }
    return nil
}

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

:param: dictionary        `XPCDictionary` to mutate.
:param: cursorInfoRequest SourceKit xpc dictionary to use to send cursorinfo request.
*/
func replaceUIDsWithStringsInDictionary(inout dictionary: XPCDictionary,
    _ cursorInfoRequest: xpc_object_t? = nil) {
    for key in dictionary.keys {
        if var subArray = dictionary[key]! as? XPCArray {
            for i in 0..<subArray.count {
                var subDict = subArray[i] as XPCDictionary
                replaceUIDsWithStringsInDictionary(&subDict, cursorInfoRequest)
                subArray[i] = subDict
            }
            dictionary[key] = subArray
        } else if let uid = dictionary[key] as? UInt64 {
            if let uidString = stringForSourceKitUID(uid) {
                dictionary[key] = uidString
                if cursorInfoRequest != nil && key == "key.kind" {
                    if uidString.rangeOfString("source.lang.swift.decl.") != nil {
                        let offset = dictionary["key.nameoffset"] as Int64
                        if offset > 0 {
                            xpc_dictionary_set_int64(cursorInfoRequest, "key.offset", offset)
                            // Send request and wait for response
                            if let response = fromXPC(sourcekitd_send_request_sync(cursorInfoRequest)) as XPCDictionary? {
                                for (key, value) in response {
                                    if key == "key.kind" {
                                        // Skip kinds, since values from editor.open are more
                                        // accurate than cursorinfo
                                        continue
                                    }
                                    dictionary[key] = value
                                }
                            }
                        }
                    } else if uidString == "source.lang.swift.syntaxtype.comment.mark" {
                        let offset = dictionary["key.offset"] as Int64
                        let length = dictionary["key.length"] as Int64
                        let file = String(UTF8String: xpc_dictionary_get_string(cursorInfoRequest, "key.sourcefile"))!
                        dictionary["key.name"] = NSString(contentsOfFile: file, encoding: NSUTF8StringEncoding, error: nil)!.substringWithRange(NSRange(location: Int(offset), length: Int(length)))
                    }
                }
            }
        }
    }
}

/**
Convert XPCDictionary to JSON

:param: dictionary XPCDictionary to convert
:returns: Converted JSON
*/
func toJSON(dictionary: XPCDictionary) -> String {
    let json = toJSONPartial(dictionary)
        .stringByReplacingOccurrencesOfString(",}", withString: "}")
        .stringByReplacingOccurrencesOfString(",]", withString: "]")

    let jsonData = json[json.startIndex..<json.endIndex.predecessor()].dataUsingEncoding(NSUTF8StringEncoding)!
    let prettyJSONObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(jsonData, options: nil, error: nil)
    let prettyJSONData = NSJSONSerialization.dataWithJSONObject(prettyJSONObject!, options: .PrettyPrinted, error: nil)
    return NSString(data: prettyJSONData!, encoding: NSUTF8StringEncoding)!
}

/**
Partially convert XPCDictionary to JSON. Is not yet valid JSON. See toJSON(_:)

:param: dictionary XPCDictionary to convert
:returns: Converted JSON
*/
func toJSONPartial(dictionary: XPCDictionary) -> String {
    var json = "{"
    for (key, object) in dictionary {
        switch object {
        case let object as XPCArray:
            json += "\"\(key)\": ["
            for subDict in object {
                json += toJSONPartial(subDict as XPCDictionary)
            }
            json += "],"
        case let object as XPCDictionary:
            json += "\"\(key)\": \(toJSONPartial(object)),"
        case let object as String:
            let data = NSJSONSerialization.dataWithJSONObject([key: object], options: nil, error: nil)
            let objectJSON: String = NSString(data: data!, encoding: NSUTF8StringEncoding)!
            json += objectJSON[objectJSON.startIndex.successor()..<objectJSON.endIndex.predecessor()] + ","
        case let object as NSDate:
            json += "\"\(key)\": \"\(object)\","
        case let object as NSData:
            json += "\"\(key)\": \"\(object)\","
        case let object as UInt64:
            json += "\"\(key)\": \(object),"
        case let object as Int64:
            json += "\"\(key)\": \(object),"
        case let object as Double:
            json += "\"\(key)\": \(object),"
        case let object as Bool:
            json += "\"\(key)\": \(object),"
        case let object as NSFileHandle:
            json += "\"\(key)\": \(object.fileDescriptor),"
        default:
            // Should never happen because we've checked all XPCRepresentable types
            abort()
        }
    }
    json += "},"
    return json
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
*/
func docs_for_swift_compiler_args(arguments: [String], swiftFiles: [String]) {
    sourcekitd_initialize()

    // Create the XPC array of compiler arguments once, to be reused for each request
    let xpcArguments = xpc_array_create(nil, 0)
    for argument in arguments {
        xpc_array_append_value(xpcArguments, xpc_string_create(argument))
    }

    // Construct a SourceKit request for getting general info about a Swift file
    let openRequest = xpc_dictionary_create(nil, nil, 0)
    xpc_dictionary_set_uint64(openRequest, "key.request", sourcekitd_uid_get_from_cstr("source.request.editor.open"))
    xpc_dictionary_set_string(openRequest, "key.name", "")

    // Construct a SourceKit request for getting cursor info for current cursor position
    let cursorInfoRequest = xpc_dictionary_create(nil, nil, 0)
    xpc_dictionary_set_uint64(cursorInfoRequest, "key.request", sourcekitd_uid_get_from_cstr("source.request.cursorinfo"))
    xpc_dictionary_set_value(cursorInfoRequest, "key.compilerargs", xpcArguments)

    // Print docs for each Swift file
    for file in swiftFiles {
        xpc_dictionary_set_string(openRequest, "key.sourcefile", file)
        xpc_dictionary_set_string(cursorInfoRequest, "key.sourcefile", file)

        var openResponse: XPCDictionary = fromXPC(sourcekitd_send_request_sync(openRequest))
        openResponse.removeValueForKey("key.syntaxmap")
        replaceUIDsWithStringsInDictionary(&openResponse, cursorInfoRequest)
        println(toJSON(openResponse))
    }
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

// MARK: Structure

/**
Print file structure information as JSON to STDOUT

:param: file Path to the file to parse for structure information
*/
func printStructure(#file: String) {
    // Construct a SourceKit request for getting general info about a Swift file
    let request = xpc_dictionary_create(nil, nil, 0)
    xpc_dictionary_set_uint64(request, "key.request", sourcekitd_uid_get_from_cstr("source.request.editor.open"))
    xpc_dictionary_set_string(request, "key.name", "")
    xpc_dictionary_set_string(request, "key.sourcefile", file)

    // Initialize SourceKit XPC service
    sourcekitd_initialize()

    // Send SourceKit request
    var response: XPCDictionary = fromXPC(sourcekitd_send_request_sync(request))
    response.removeValueForKey("key.syntaxmap")
    replaceUIDsWithStringsInDictionary(&response)
    println(toJSON(response))
}

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
    // Get syntaxmap XPC data and convert to NSData
    let data: NSData = fromXPC(xpc_dictionary_get_value(sourceKitResponse, "key.syntaxmap"))!

    // Get number of syntax tokens
    var tokens = 0
    data.getBytes(&tokens, range: NSRange(location: 8, length: 8))
    tokens = tokens >> 4

    println("[")

    for i in 0..<tokens {
        let parserOffset = 16 * i

        var uid = UInt64(0)
        data.getBytes(&uid, range: NSRange(location: 16 + parserOffset, length: 8))
        let type = stringForSourceKitUID(uid)!

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

// MARK: Main Program

/**
Print XML-formatted docs for the specified Xcode project,
or Xcode output if no Swift compiler arguments were found.
*/
func main() {
    let arguments = Process.arguments
    if arguments.count > 1 && arguments[1] == "--skip-xcodebuild" {
        var sourcekitdArguments = Array<String>(arguments[2...arguments.count])
        let swiftFiles = swiftFilesFromArray(sourcekitdArguments)
        println(docs_for_swift_compiler_args(sourcekitdArguments, swiftFiles))
    } else if arguments.count == 3 && arguments[1] == "--structure" {
        printStructure(file: arguments[2])
    } else if arguments.count == 3 && arguments[1] == "--syntax" {
        printSyntaxHighlighting(file: arguments[2])
    } else if arguments.count == 3 && arguments[1] == "--syntax-text" {
        printSyntaxHighlighting(text: arguments[2])
    } else if let xcodebuildOutput = run_xcodebuild(arguments) {
        if let swiftcArguments = swiftc_arguments_from_xcodebuild_output(xcodebuildOutput) {
            // Extract the Xcode project's Swift files
            let swiftFiles = swiftFilesFromArray(swiftcArguments)

            // FIXME: The following makes things ~30% faster, at the expense of (possibly)
            // not supporting complex project configurations.
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

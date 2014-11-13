//
//  main.swift
//  sourcekitten
//
//  Created by JP Simard on 10/15/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

import Foundation
import XPC

/// Version number
let version = "0.1.8"

/// File Contents
var fileContents = NSString()

/// Documented Count
var documentedCount = 0

/// Undocumented Count
var undocumentedCount = 0

// MARK: Helper Functions

/**
Sends a request to SourceKit returns the response as an XPCDictionary.

:param: request Request to send synchronously to SourceKit
:returns: SourceKit output
*/
func sendSourceKitRequest(request: xpc_object_t?) -> XPCDictionary {
    let response = sourcekitd_send_request_sync(request)
    let responseDict: XPCDictionary = fromXPC(response)
    xpc_release(response)
    return responseDict
}

/// SourceKit UID to String map
var uidStringMap = [UInt64: String]()

/**
Cache SourceKit requests for strings from UIDs

:param: uid UID received from sourcekitd* responses
:returns: Cached UID string if available, other
*/
func stringForSourceKitUID(uid: UInt64) -> String? {
    if uid < 4_300_000_000 {
        // UID's are always higher than 4.3M
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
Print message to STDERR and exit(1)

:param: message message to print
*/
func error(message: String) {
    printSTDERR(message)
    exit(1)
}

/**
Print message to STDERR. Useful for UI messages without affecting STDOUT data.

:param: message message to print
*/
func printSTDERR(message: String) {
    let stderr = NSFileHandle.fileHandleWithStandardError()
    stderr.writeData((message + "\n").dataUsingEncoding(NSUTF8StringEncoding)!)
}

/**
Process a SourceKit editor.open response dictionary by removing undocumented tokens with no
documented children. Add cursor.info information for declarations. Add name to mark comments.

:param: dictionary        `XPCDictionary` to mutate.
:param: cursorInfoRequest SourceKit xpc dictionary to use to send cursorinfo request.
:returns: Whether or not the dictionary should be kept.
*/
func processDictionary(inout dictionary: XPCDictionary,
    _ cursorInfoRequest: xpc_object_t? = nil) -> Bool {
    var shouldKeep = false
    if dictionary["key.substructure"] == nil {
        return shouldKeep
    }

    if let substructure = dictionary["key.substructure"]! as? XPCArray {
        var newSubstructure = XPCArray()
        for i in 0..<substructure.count {
            var subDict = substructure[i] as XPCDictionary
            if let kind = subDict["key.kind"] as? String {
                if (kind.rangeOfString("source.lang.swift.decl.") != nil ||
                    kind == "source.lang.swift.syntaxtype.comment.mark") &&
                    kind != "source.lang.swift.decl.var.parameter" {
                    if processDictionary(&subDict, cursorInfoRequest) {
                        newSubstructure.append(subDict)
                    }
                }
            }
        }
        dictionary["key.substructure"] = newSubstructure
    }

    if cursorInfoRequest == nil {
        return true
    }

    if dictionary["key.kind"] == nil {
        return shouldKeep
    }
    let kind = dictionary["key.kind"] as String
    if kind != "source.lang.swift.decl.var.parameter" &&
        kind.rangeOfString("source.lang.swift.decl.") != nil {
        let offset = dictionary["key.nameoffset"] as Int64
        if offset > 0 {
            xpc_dictionary_set_int64(cursorInfoRequest, "key.offset", offset)

            // Send request and wait for response
            let response = sendSourceKitRequest(cursorInfoRequest)
            if response["key.doc.full_as_xml"] != nil {
                shouldKeep = true
                documentedCount++
            } else {
                undocumentedCount++
            }
            for (key, value) in response {
                if key == "key.kind" {
                    // Skip kinds, since values from editor.open are more
                    // accurate than cursorinfo
                    continue
                }
                dictionary[key] = value
            }
        }
    } else if kind == "source.lang.swift.syntaxtype.comment.mark" {
        let offset = dictionary["key.offset"] as Int64
        let length = dictionary["key.length"] as Int64
        let file = String(UTF8String: xpc_dictionary_get_string(cursorInfoRequest, "key.sourcefile"))!
        dictionary["key.name"] = fileContents.substringWithRange(NSRange(location: Int(offset), length: Int(length)))
        shouldKeep = true
    }
    return shouldKeep
}

/**
Find parent offsets for given documented offsets.

:param: dictionary Parent document to search for ranges.
:param: documentedTokenOffsets inout dictionary of documented token offsets mapping to their parent offsets.
:param: file File where these offsets are located.
*/
func mapOffsets(dictionary: XPCDictionary, inout documentedTokenOffsets: [Int: Int], file: String) {
    if let dictFile =  dictionary["key.filepath"] as? String {
        if dictFile == file {
            if let rangeStart = dictionary["key.nameoffset"] as? Int64 {
                if let rangeLength = dictionary["key.namelength"] as? Int64 {
                    let bodyLength = dictionary["key.bodylength"] as? Int64
                    let offsetsInRange = documentedTokenOffsets.keys.filter {
                        return $0 >= Int(rangeStart) && $0 <= Int(rangeStart + rangeLength + (bodyLength ?? 0))
                    }
                    for offset in offsetsInRange {
                        documentedTokenOffsets[offset] = Int(rangeStart)
                    }
                }
            }
        }
    }
    let substructure = dictionary["key.substructure"] as XPCArray
    for subDict in substructure {
        mapOffsets(subDict as XPCDictionary, &documentedTokenOffsets, file)
    }
}

/**
Find integer offsets of documented tokens

:param: syntaxMap Syntax Map returned from SourceKit editor.open request
:param: file File to parse
:returns: Array of documented token offsets
*/
func documentedTokenOffsets(syntaxMap: NSData, file: String) -> [Int] {
    // Get number of syntax tokens
    var tokens = 0
    syntaxMap.getBytes(&tokens, range: NSRange(location: 8, length: 8))
    tokens = tokens >> 4

    var identifierOffsets = [Int]()

    for i in 0..<tokens {
        let parserOffset = 16 * i

        var uid = UInt64(0)
        syntaxMap.getBytes(&uid, range: NSRange(location: 16 + parserOffset, length: 8))
        let type = stringForSourceKitUID(uid)!

        // Only append identifiers
        if type != "source.lang.swift.syntaxtype.identifier" {
            continue
        }
        var offset = 0
        syntaxMap.getBytes(&offset, range: NSRange(location: 24 + parserOffset, length: 4))
        identifierOffsets.append(offset)
    }

    let regex = NSRegularExpression(pattern: "(///.*\\n|\\*/\\n)", options: nil, error: nil)!
    let range = NSRange(location: 0, length: fileContents.length)
    let matches = regex.matchesInString(fileContents, options: nil, range: range)

    var offsets = [Int]()
    for match in matches {
        offsets.append(identifierOffsets.filter({ $0 >= match.range.location})[0])
    }
    return offsets
}

/**
Find integer offsets of documented tokens

:param: file File to parse
:returns: Array of documented token offsets
*/
func documentedTokenOffsets(file: String) -> [Int] {
    // Construct a SourceKit request for getting general info about the Swift file passed as argument
    let request = toXPC([
        "key.request": sourcekitd_uid_get_from_cstr("source.request.editor.open"),
        "key.name": "",
        "key.sourcefile": file])
    return documentedTokenOffsets(sendSourceKitRequest(request)["key.syntaxmap"] as NSData!, file)
}

/**
Convert XPCDictionary to JSON

:param: dictionary XPCDictionary to convert
:returns: Converted JSON
*/
func toJSON(dictionary: XPCDictionary) -> String {
    return toJSON(toAnyObject(dictionary))
}

/**
Convert XPCArray of XPCDictionary's to JSON

:param: array XPCArray of XPCDictionary's to convert
:returns: Converted JSON
*/
func toJSON(array: XPCArray) -> String {
    var anyArray = [AnyObject]()
    for item in array {
        anyArray.append(toAnyObject(item as XPCDictionary))
    }
    return toJSON(anyArray)
}

/**
JSON Object to JSON String

:param: object Object to convert to JSON.
:returns: JSON string representation of the input object.
*/
func toJSON(object: AnyObject) -> String {
    let prettyJSONData = NSJSONSerialization.dataWithJSONObject(object,
        options: .PrettyPrinted,
        error: nil)
    return NSString(data: prettyJSONData!, encoding: NSUTF8StringEncoding)!
}

/**
Convert XPCDictionary to [String: AnyObject] for conversion using NSJSONSerialization. See toJSON(_:)

:param: dictionary XPCDictionary to convert
:returns: JSON-serializable Dictionary
*/
func toAnyObject(dictionary: XPCDictionary) -> [String: AnyObject] {
    var anyDictionary = [String: AnyObject]()
    for (key, object) in dictionary {
        switch object {
        case let object as XPCArray:
            var anyArray = [AnyObject]()
            for subDict in object {
                anyArray.append(toAnyObject(subDict as XPCDictionary))
            }
            anyDictionary[key] = anyArray
        case let object as XPCDictionary:
            anyDictionary[key] = toAnyObject(object)
        case let object as String:
            anyDictionary[key] = object
        case let object as NSDate:
            anyDictionary[key] = object
        case let object as NSData:
            anyDictionary[key] = object
        case let object as UInt64:
            anyDictionary[key] = NSNumber(unsignedLongLong: object)
        case let object as Int64:
            anyDictionary[key] = NSNumber(longLong: object)
        case let object as Double:
            anyDictionary[key] = NSNumber(double: object)
        case let object as Bool:
            anyDictionary[key] = NSNumber(bool: object)
        case let object as NSFileHandle:
            anyDictionary[key] = NSNumber(int: object.fileDescriptor)
        default:
            // Should never happen because we've checked all XPCRepresentable types
            abort()
        }
    }
    return anyDictionary
}

/**
Run `xcodebuild clean build -dry-run` along with any passed in build arguments.
Return STDERR and STDOUT as a combined string.

:param: processArguments array of arguments to pass to `xcodebuild`
:returns: xcodebuild STDERR+STDOUT output
*/
func run_xcodebuild(processArguments: [String]) -> String? {
    printSTDERR("Running xcodebuild -dry-run")

    let task = NSTask()
    task.launchPath = "/usr/bin/xcodebuild"

    // Forward arguments to xcodebuild
    var arguments = processArguments
    arguments.removeAtIndex(0)
    arguments.extend(["clean", "build", "-dry-run", "CODE_SIGN_IDENTITY=", "CODE_SIGNING_REQUIRED=NO"])
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
Run sourcekitten as a new process.

:param: processArguments arguments to pass to new sourcekitten process
:returns: sourcekitten STDOUT output
*/
func run_self(processArguments: [String]) -> String {
    let task = NSTask()
    task.launchPath = NSBundle.mainBundle().executablePath!
    task.arguments = processArguments

    let pipe = NSPipe()
    task.standardOutput = pipe

    task.launch()

    let file = pipe.fileHandleForReading
    let output = NSString(data: file.readDataToEndOfFile(), encoding: NSUTF8StringEncoding)
    file.closeFile()

    return output!
}

/**
Parses the compiler arguments needed to compile the Swift aspects of an Xcode project

:param: xcodebuildOutput output of `xcodebuild` to be parsed for swift compiler arguments
:returns: array of swift compiler arguments
*/
func swiftc_arguments_from_xcodebuild_output(xcodebuildOutput: NSString) -> [String]? {
    let regex = NSRegularExpression(pattern: "/usr/bin/swiftc.*", options: nil, error: nil)!
    let range = NSRange(location: 0, length: xcodebuildOutput.length)
    let regexMatch = regex.firstMatchInString(xcodebuildOutput, options: nil, range: range)

    if let regexMatch = regexMatch {
        let escapedSpacePlaceholder = "\u{0}"
        var args = xcodebuildOutput
            .substringWithRange(regexMatch.range)
            .stringByReplacingOccurrencesOfString("\\ ", withString: escapedSpacePlaceholder)
            .componentsSeparatedByString(" ")

        args.removeAtIndex(0) // Remove swiftc

        args = args.map {
            $0.stringByReplacingOccurrencesOfString(escapedSpacePlaceholder, withString: " ")
        }

        return args.filter { $0 != "-parseable-output" }
    }

    return nil
}

/**
Print JSON and XML-formatted docs for the specified Swift file.

:param: arguments compiler arguments to pass to SourceKit
:param: file Path to Swift file to document
*/
func docs_for_swift_compiler_args(arguments: [String], file: String) {
    sourcekitd_initialize()

    // Construct SourceKit requests for getting general info about a Swift file and getting cursor info
    let openRequest = toXPC(["key.request": sourcekitd_uid_get_from_cstr("source.request.editor.open"), "key.name": ""])
    let cursorInfoRequest = toXPC(["key.request": sourcekitd_uid_get_from_cstr("source.request.cursorinfo")])

    let xpcArguments = xpc_array_create(nil, 0)
    for argument in arguments {
        xpc_array_append_value(xpcArguments, xpc_string_create(argument))
    }
    xpc_dictionary_set_value(cursorInfoRequest, "key.compilerargs", xpcArguments)

    fileContents = NSString(contentsOfFile: file, encoding: NSUTF8StringEncoding, error: nil)!

    xpc_dictionary_set_string(openRequest, "key.sourcefile", file)
    xpc_dictionary_set_string(cursorInfoRequest, "key.sourcefile", file)

    var openResponse = sendSourceKitRequest(openRequest)
    let syntaxMap = openResponse["key.syntaxmap"] as NSData
    openResponse.removeValueForKey("key.syntaxmap")

    // Map documented token offsets to the start of their range
    var offsetsMap = [Int: Int]()
    for offset in documentedTokenOffsets(syntaxMap, file) {
        offsetsMap[offset] = 0
    }
    processDictionary(&openResponse, cursorInfoRequest)
    mapOffsets(openResponse, &offsetsMap, file)
    var alreadyDocumentedOffsets = [Int]()
    for (offset, rangeStart) in offsetsMap {
        if offset == rangeStart {
            alreadyDocumentedOffsets.append(offset)
        }
    }
    for alreadyDocumentedOffset in alreadyDocumentedOffsets {
        offsetsMap.removeValueForKey(alreadyDocumentedOffset)
    }
    var reversedOffsets = [Int]()
    for offset in offsetsMap.keys {
        reversedOffsets.insert(offset, atIndex: 0)
    }
    for offset in reversedOffsets {
        xpc_dictionary_set_int64(cursorInfoRequest, "key.offset", Int64(offset))
        var response = sendSourceKitRequest(cursorInfoRequest)
        processDictionary(&response)
        if response["key.kind"] != nil &&
            (response["key.kind"] as String).rangeOfString("source.lang.swift.decl.") != nil {
                insertDoc(response, &openResponse, Int64(offsetsMap[offset]!), file)
        }
    }
    openResponse["key.doc.coverage"] = Int64(Float(100*documentedCount)/Float(documentedCount + undocumentedCount))
    println(toJSON(openResponse))
}

/**
Insert a document in a parent at the given offset.

:param: doc Document to insert
:param: parent Document to insert into
:param: offset Parent's offset
:param: file File where parent and doc are located
:returns: Whether or not the insertion succeeded
*/
func insertDoc(doc: XPCDictionary, inout parent: XPCDictionary, offset: Int64, file: String) -> Bool {
    func insertDocDirectly(doc: XPCDictionary, inout parent: XPCDictionary, offset: Int64) {
        var substructure = parent["key.substructure"] as XPCArray
        var insertIndex = substructure.count
        for (index, structure) in enumerate(substructure.reverse()) {
            if ((structure as XPCDictionary)["key.offset"] as Int64) < offset {
                break
            }
            insertIndex = substructure.count - index
        }
        substructure.insert(doc, atIndex: insertIndex)
        parent["key.substructure"] = substructure
    }
    if offset == 0 {
        insertDocDirectly(doc, &parent, offset)
        return true
    }
    if let parentFile = parent["key.filepath"] as? String {
        if parentFile == file {
            if let rangeStart = parent["key.offset"] as? Int64 {
                if rangeStart == offset {
                    insertDocDirectly(doc, &parent, offset)
                    return true
                }
            }
        }
    }
    for key in parent.keys {
        if var subArray = parent[key]! as? XPCArray {
            var success = false
            for i in 0..<subArray.count {
                var subDict = subArray[i] as XPCDictionary
                success = insertDoc(doc, &subDict, offset, file)
                subArray[i] = subDict
                if success {
                    break
                }
            }
            if success {
                parent[key] = subArray
                return true
            }
        }
    }
    return false
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
    let request = toXPC([
        "key.request": sourcekitd_uid_get_from_cstr("source.request.editor.open"),
        "key.name": "",
        "key.sourcefile": file])

    // Initialize SourceKit XPC service
    sourcekitd_initialize()

    // Send SourceKit request
    var response = sendSourceKitRequest(request)
    response.removeValueForKey("key.syntaxmap")
    processDictionary(&response)
    println(toJSON(response))
}

// MARK: Syntax

/**
Print syntax information as JSON to STDOUT

:param: file Path to the file to parse for syntax highlighting information
*/
func printSyntax(#file: String) {
    sourcekitd_initialize()
    // Construct editor.open SourceKit request
    let request = toXPC([
        "key.request": sourcekitd_uid_get_from_cstr("source.request.editor.open"),
        "key.name": "",
        "key.sourcefile": file])
    printSyntax(sendSourceKitRequest(request))
}

/**
Print syntax information as JSON to STDOUT

:param: text Swift source code to parse for syntax highlighting information
*/
func printSyntax(#text: String) {
    sourcekitd_initialize()
    // Construct editor.open SourceKit request
    let request = toXPC([
        "key.request": sourcekitd_uid_get_from_cstr("source.request.editor.open"),
        "key.name": "",
        "key.sourcetext": text])
    printSyntax(sendSourceKitRequest(request))
}

/**
Print syntax information as JSON to STDOUT

:param: sourceKitResponse XPC object returned from SourceKit "editor.open" call
*/
func printSyntax(sourceKitResponse: XPCDictionary) {
    // Get syntaxmap XPC data and convert to NSData
    let data = sourceKitResponse["key.syntaxmap"] as NSData

    // Get number of syntax tokens
    var tokens = 0
    data.getBytes(&tokens, range: NSRange(location: 8, length: 8))
    tokens = tokens >> 4

    var syntaxArray = [[String: AnyObject]]()

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

        syntaxArray.append(["type": type, "offset": offset, "length": length])
    }

    let syntaxJSONData = NSJSONSerialization.dataWithJSONObject(syntaxArray,
        options: .PrettyPrinted,
        error: nil)
    let syntaxJSON = NSString(data: syntaxJSONData!, encoding: NSUTF8StringEncoding)!
    println(syntaxJSON)
}

/**
Prints help message in console
*/
func printHelp() {
    println("Usage: sourcekitten [-h] [--skip-xcodebuild COMPILER_ARGUMENTS] [--structure /absolute/path/to/file.swift] [--syntax /absolute/path/to/file.swift] [--syntax-text SWIFT_SOURCE_TEXT] [Xcode build arguments...]\n\nVersion: \(version)")
}

// MARK: Main Program

/**
Parse command-line arguments & call the appropriate function.
*/
func main() {
    let arguments = Process.arguments
    if arguments.count > 1 && arguments[1] == "--single-file" {
        var sourcekitdArguments = Array<String>(arguments[3..<arguments.count])
        docs_for_swift_compiler_args(sourcekitdArguments, arguments[2])
        let docCoverage = Int(Float(100*documentedCount)/Float(documentedCount + undocumentedCount))
        printSTDERR("\(arguments[2].lastPathComponent) is \(docCoverage)% documented")
    } else if arguments.count == 3 && arguments[1] == "--structure" {
        printStructure(file: arguments[2])
    } else if arguments.count == 3 && arguments[1] == "--syntax" {
        printSyntax(file: arguments[2])
    } else if arguments.count == 3 && arguments[1] == "--syntax-text" {
        printSyntax(text: arguments[2])
    } else if arguments.count == 2 && arguments[1] == "-h" {
        printHelp()
    } else if let xcodebuildOutput = run_xcodebuild(arguments) {
        if let swiftcArguments = swiftc_arguments_from_xcodebuild_output(xcodebuildOutput) {
            // Spawn new processes for each Swift file because SourceKit crashes otherwise
            let swiftFiles = swiftFilesFromArray(swiftcArguments)
            println("[")
            for (index, file) in enumerate(swiftFiles) {
                printSTDERR("parsing \(file.lastPathComponent) (\(index + 1)/\(swiftFiles.count))")
                var self_arguments = ["--single-file", file]
                self_arguments.extend(swiftcArguments)
                println(run_self(self_arguments))
                if index < swiftFiles.count-1 {
                    println(",")
                }
            }
            println("]")
        } else {
            error(xcodebuildOutput)
        }
    } else {
        error("Xcode build output could not be read")
    }
}

main()

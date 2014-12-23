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
let version = "0.2.4"

/// Language Enum
enum Language {
    /// Represents Swift
    case Swift
    /// Represents Objective-C
    case ObjC
}

/// File Contents
var fileContents = NSString()

/// File Contents Line Breaks
var fileContentsLineBreaks = [Int]()

// MARK: Helper Functions

/**
Print message to STDERR. Useful for UI messages without affecting STDOUT data.

:param: message message to print.
*/
func printSTDERR(message: String) {
    if let data = (message + "\n").dataUsingEncoding(NSUTF8StringEncoding) {
        let stderr = NSFileHandle.fileHandleWithStandardError()
        stderr.writeData(data)
    }
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
Converts any path into an absolute path

:param: path An arbitrary path

:returns: path represented as an absolute path
*/
func absolutePath(path: NSString) -> String {
    if path.absolutePath {
        return path
    }
    return NSString.pathWithComponents([NSFileManager.defaultManager().currentDirectoryPath, path]).stringByStandardizingPath
}

/**
Returns offsets of all the line breaks in the fileContents global

:returns: line breaks
*/
func lineBreaks() -> [Int] {
    var lineBreaks = [Int]()
    var searchRange = NSRange(location: 0, length: fileContents.length)
    while (searchRange.length > 0) {
        searchRange.length = fileContents.length - searchRange.location
        let foundRange = fileContents.rangeOfString("\n", options: nil, range: searchRange)
        if foundRange.location != NSNotFound {
            lineBreaks.append(foundRange.location)
            searchRange.location = foundRange.location + foundRange.length
        } else {
            break
        }
    }
    return lineBreaks
}

/**
Sends a request to SourceKit returns the response as an XPCDictionary.

:param: request Request to send synchronously to SourceKit

:returns: SourceKit output
*/
func sendSourceKitRequest(request: xpc_object_t?) -> XPCDictionary {
    if let request = request {
        if let response = sourcekitd_send_request_sync(request) {
            return fromXPC(response)
        } else {
            error("SourceKit response nil for request \(request)")
        }
    }
    error("SourceKit request can't be nil")
    return XPCDictionary()
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
        if let uidString = String(UTF8String: sourcekitd_uid_get_string_ptr(uid)) {
            uidStringMap[uid] = uidString
            return uidString
        }
    }
    return nil
}

/**
Parse declaration from XPC dictionary.

:param: dictionary XPC dictionary to extract declaration from.

:returns: String declaration if successfully parsed.
*/
func parseDeclaration(dictionary: XPCDictionary) -> String? {
    if dictionary["key.typename"] == nil ||
        dictionary["key.annotated_decl"] == nil ||
        dictionary["key.kind"] as String == "source.lang.swift.decl.extension" {
        return nil
    }
    let offset = dictionary["key.offset"] as Int64
    let previousLineBreakOffset: Int = {
        for (index, lineBreakOffset) in enumerate(fileContentsLineBreaks) {
            if lineBreakOffset > Int(offset) {
                return fileContentsLineBreaks[index - 1]
            }
        }
        return fileContentsLineBreaks.first ?? 0
    }() + 1
    /**
    Filter fileContents from previousLineBreak
    to end while trimming unwanted characters.
    
    :param: end Ending offset to filter
    :returns: Filtered string.
    */
    func filteredSubstringTo(end: Int) -> String {
        let range = NSRange(location: previousLineBreakOffset, length: end - previousLineBreakOffset - 1)
        let unwantedSet = NSCharacterSet.whitespaceAndNewlineCharacterSet().mutableCopy() as NSMutableCharacterSet
        unwantedSet.addCharactersInString("{")
        return fileContents.substringWithRange(range).stringByTrimmingCharactersInSet(unwantedSet)
    }
    if let bodyOffset = dictionary["key.bodyoffset"] as Int64? {
        return filteredSubstringTo(Int(bodyOffset))
    }
    let nextLineBreakOffset: Int = {
        for (index, lineBreakOffset) in enumerate(fileContentsLineBreaks.reverse()) {
            if lineBreakOffset < Int(offset) {
                return fileContentsLineBreaks[fileContentsLineBreaks.count - index]
            }
        }
        return fileContentsLineBreaks.last ?? 0
    }() + 1
    return filteredSubstringTo(nextLineBreakOffset)
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
    if let substructure = dictionary["key.substructure"] as XPCArray? {
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
        if let parsedDeclaration = parseDeclaration(dictionary) {
            dictionary["key.parsed_declaration"] = parsedDeclaration
        }
        return true
    } else if dictionary["key.kind"] == nil {
        return false
    }

    let kind = dictionary["key.kind"] as String
    if kind != "source.lang.swift.decl.var.parameter" &&
        kind.rangeOfString("source.lang.swift.decl.") != nil {
        let offset = dictionary["key.nameoffset"] as Int64
        if offset > 0 {
            xpc_dictionary_set_int64(cursorInfoRequest, "key.offset", offset)

            // Send request and wait for response
            let response = sendSourceKitRequest(cursorInfoRequest)
            for (key, value) in response {
                if key == "key.kind" {
                    // Skip kinds, since values from editor.open are more
                    // accurate than cursorinfo
                    continue
                }
                dictionary[key] = value
            }
        }
        if let parsedDeclaration = parseDeclaration(dictionary) {
            dictionary["key.parsed_declaration"] = parsedDeclaration
        }
        return true
    } else if kind == "source.lang.swift.syntaxtype.comment.mark" {
        let offset = Int(dictionary["key.offset"] as Int64)
        let length = Int(dictionary["key.length"] as Int64)
        if let file = String(UTF8String: xpc_dictionary_get_string(cursorInfoRequest, "key.sourcefile")) {
            dictionary["key.name"] = fileContents.substringWithRange(NSRange(location: offset, length: length))
        }
        return true
    }
    return false
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
        let type = stringForSourceKitUID(uid) ?? "unknown"

        // Only append identifiers
        if type != "source.lang.swift.syntaxtype.identifier" {
            continue
        }
        var offset = 0
        syntaxMap.getBytes(&offset, range: NSRange(location: 24 + parserOffset, length: 4))
        identifierOffsets.append(offset)
    }

    let regex = NSRegularExpression(pattern: "(///.*\\n|\\*/\\n)", options: nil, error: nil)! // Safe to force unwrap
    let range = NSRange(location: 0, length: fileContents.length)
    let matches = regex.matchesInString(fileContents, options: nil, range: range)

    var offsets = [Int]()
    for match in matches {
        if let first = identifierOffsets.filter({ $0 >= match.range.location}).first {
            offsets.append(first)
        }
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
    if let syntaxMap = sendSourceKitRequest(request)["key.syntaxmap"] as NSData? {
        return documentedTokenOffsets(syntaxMap, file)
    }
    error("SourceKit could not generate syntax map.")
    return []
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
    return toJSON(array.map { toAnyObject($0 as XPCDictionary) })
}

/**
JSON Object to JSON String

:param: object Object to convert to JSON.

:returns: JSON string representation of the input object.
*/
func toJSON(object: AnyObject) -> String {
    if let prettyJSONData = NSJSONSerialization.dataWithJSONObject(object,
        options: .PrettyPrinted,
        error: nil) {
        return NSString(data: prettyJSONData, encoding: NSUTF8StringEncoding)! // Safe to force unwrap
    }
    return ""
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
            anyDictionary[key] = object.map { toAnyObject($0 as XPCDictionary) }
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

:param: arguments array of arguments to pass to `xcodebuild`

:returns: xcodebuild STDERR+STDOUT output
*/
func run_xcodebuild(arguments: [String]) -> String? {
    printSTDERR("Running xcodebuild -dry-run")

    let task = NSTask()
    task.launchPath = "/usr/bin/xcodebuild"

    // Forward arguments to xcodebuild
    task.arguments = arguments + ["clean", "build", "-dry-run", "CODE_SIGN_IDENTITY=", "CODE_SIGNING_REQUIRED=NO"]

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
func run_self(processArguments: [String]) -> String? {
    let task = NSTask()
    task.launchPath = NSBundle.mainBundle().executablePath! // Safe to force unwrap
    task.arguments = processArguments

    let pipe = NSPipe()
    task.standardOutput = pipe

    task.launch()

    let file = pipe.fileHandleForReading
    let output = NSString(data: file.readDataToEndOfFile(), encoding: NSUTF8StringEncoding)
    file.closeFile()

    return output
}

/**
Parses the compiler arguments needed to compile the `language` aspects of an Xcode project

:param: xcodebuildOutput output of `xcodebuild` to be parsed for compiler arguments

:returns: array of compiler arguments
*/
func compiler_arguments_from_xcodebuild_output(xcodebuildOutput: NSString, #language: Language) -> [String]? {
    let pattern: String = {
        if language == .ObjC {
            return "/usr/bin/clang.*"
        }
        let arguments = Process.arguments
        if let schemeIndex = find(arguments, "-scheme") {
            return "/usr/bin/swiftc.*-module-name \(arguments[schemeIndex+1]) .*"
        }
        return "/usr/bin/swiftc.*"
    }()
    let regex = NSRegularExpression(pattern: pattern, options: nil, error: nil)! // Safe to force unwrap
    let range = NSRange(location: 0, length: xcodebuildOutput.length)

    if let regexMatch = regex.firstMatchInString(xcodebuildOutput, options: nil, range: range) {
        let escapedSpacePlaceholder = "\u{0}"
        /// Filters compiler arguments from xcodebuild to something that libClang/sourcekit will accept
        func filterArguments(var args: [String]) -> [String] {
            /// Partially filters compiler arguments from xcodebuild to something that libClang/sourcekit will accept
            func partiallyFilterArguments(var args: [String]) -> ([String], Bool) {
                var didRemove = false
                let flagsToRemove = [
                    "--serialize-diagnostics",
                    "-c",
                    "-o"
                ]
                for flag in flagsToRemove {
                    if let index = find(args, flag) {
                        didRemove = true
                        args.removeAtIndex(index.successor())
                        args.removeAtIndex(index)
                    }
                }
                return (args, didRemove)
            }
            var shouldContinueToFilterArguments = true
            while (shouldContinueToFilterArguments) {
                (args, shouldContinueToFilterArguments) = partiallyFilterArguments(args)
            }
            return args.filter { $0 != "-parseable-output" }
        }
        let args = filterArguments(xcodebuildOutput
            .substringWithRange(regexMatch.range)
            .stringByReplacingOccurrencesOfString("\\ ", withString: escapedSpacePlaceholder)
            .componentsSeparatedByString(" "))

        // Remove swiftc/clang, -parseable-output and re-add spaces in arguments
        return Array<String>(args[1..<args.count]).map {
            $0.stringByReplacingOccurrencesOfString(escapedSpacePlaceholder, withString: " ")
        }
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

    if let contents = NSString(contentsOfFile: file, encoding: NSUTF8StringEncoding, error: nil) {
        fileContents = contents
    } else {
        error("\(file.lastPathComponent) could not be read.")
    }
    fileContentsLineBreaks = lineBreaks()

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
            if let mappedOffset = offsetsMap[offset] {
                insertDoc(response, &openResponse, Int64(mappedOffset), file)
            } else {
                printSTDERR("No mapped offset for \(offset) in \(file.lastPathComponent)")
            }
        }
    }
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
    /// Insert doc without performing any validation
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
        if var subArray = parent[key]! as? XPCArray { // Safe to force unwrap
            for i in 0..<subArray.count {
                var subDict = subArray[i] as XPCDictionary
                if insertDoc(doc, &subDict, offset, file) {
                    subArray[i] = subDict
                    parent[key] = subArray
                    return true
                }
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
        let type = stringForSourceKitUID(uid) ?? "unknown"

        var offset = 0
        data.getBytes(&offset, range: NSRange(location: 24 + parserOffset, length: 4))

        var length = 0
        data.getBytes(&length, range: NSRange(location: 28 + parserOffset, length: 4))
        length = length >> 1

        syntaxArray.append(["type": type, "offset": offset, "length": length])
    }

    if let syntaxJSONData = NSJSONSerialization.dataWithJSONObject(syntaxArray,
        options: .PrettyPrinted,
        error: nil) {
        println(NSString(data: syntaxJSONData, encoding: NSUTF8StringEncoding)!) // Safe to force unwrap
    }
}

/**
Prints help message in console
*/
func printHelp() {
    println("Usage: sourcekitten [-h] [--skip-xcodebuild COMPILER_ARGUMENTS] [--structure /absolute/path/to/file.swift] [--syntax /absolute/path/to/file.swift] [--syntax-text SWIFT_SOURCE_TEXT] [Xcode build arguments...]\n\nVersion: \(version)")
}

/**
Iterates over Clang translation unit to find all its XML comments. Prints to STDOUT.

:param: translationUnit Clang translation unit created from Clang index, file path and compiler arguments.
*/
func printXML(translationUnit: CXTranslationUnit) -> Void {
    clang_visitChildrenWithBlock(clang_getTranslationUnitCursor(translationUnit)) { cursor, parent in
        let comment = clang_Cursor_getParsedComment(cursor)
        let commentKind = clang_Comment_getKind(comment)

        if let commentXML = String.fromCString(clang_getCString(clang_FullComment_getAsXML(comment))) {
            println(commentXML)
        }
        return CXChildVisit_Recurse
    }
}

/**
Build Clang translation unit from Objective-C header file path and prints its XML comments to STDOUT.

:param: headerFilePath Absolute path to Objective-C header file.
*/
func objc(headerFiles: [String], args: [String]) {
    println("<?xml version=\"1.0\"?>\n<sourcekitten>")
    for file in headerFiles {
        let translationUnit = clang_createTranslationUnitFromSourceFile(clang_createIndex(0, 1),
            file,
            Int32(args.count),
            args.map { ($0 as NSString).UTF8String },
            0,
            nil)
        printXML(translationUnit)
    }
    println("</sourcekitten>")
}

// MARK: Main Program

/**
Parse command-line arguments & call the appropriate function.
*/
func main() {
    let arguments = Process.arguments
    if arguments.count > 1 && arguments[1] == "--single-file" {
        let sourcekitdArguments = Array<String>(arguments[3..<arguments.count])
        docs_for_swift_compiler_args(sourcekitdArguments, absolutePath(arguments[2]))
    } else if arguments.count > 1 && arguments[1] == "--single-file-objc" {
        objc([absolutePath(arguments[2])], Array<String>(arguments[3..<arguments.count]))
    } else if arguments.count > 2 && arguments[1] == "--objc" {
        var xcodebuildArguments = Array<String>(arguments[2..<arguments.count])
        var headerFiles = [String]()
        while xcodebuildArguments.first?.rangeOfString(".h") != nil {
            headerFiles.append(absolutePath(xcodebuildArguments.first!)) // Safe to force unwrap
            xcodebuildArguments.removeAtIndex(0)
        }
        if let xcodebuildOutput = run_xcodebuild(xcodebuildArguments) {
            if let clangArguments = compiler_arguments_from_xcodebuild_output(xcodebuildOutput, language: .ObjC) {
                objc(headerFiles, clangArguments)
            } else {
                error(xcodebuildOutput)
            }
        } else {
            error("Xcode build output could not be read")
        }
    } else if arguments.count == 3 && arguments[1] == "--structure" {
        printStructure(file: absolutePath(arguments[2]))
    } else if arguments.count == 3 && arguments[1] == "--syntax" {
        printSyntax(file: absolutePath(arguments[2]))
    } else if arguments.count == 3 && arguments[1] == "--syntax-text" {
        printSyntax(text: arguments[2])
    } else if arguments.count == 2 && arguments[1] == "-h" {
        printHelp()
    } else if let xcodebuildOutput = run_xcodebuild(Array<String>(arguments[1..<arguments.count])) {
        if let swiftcArguments = compiler_arguments_from_xcodebuild_output(xcodebuildOutput, language: .Swift) {
            // Spawn new processes for each Swift file because SourceKit crashes otherwise
            let swiftFiles = swiftFilesFromArray(swiftcArguments)
            println("[")
            for (index, file) in enumerate(swiftFiles) {
                printSTDERR("parsing \(file.lastPathComponent) (\(index + 1)/\(swiftFiles.count))")
                if let selfOutput = run_self(["--single-file", file] + swiftcArguments) {
                    println(selfOutput)
                    if index < swiftFiles.count-1 {
                        println(",")
                    }
                } else {
                    printSTDERR("\(file.lastPathComponent) could not be parsed. Please open an issue at https://github.com/jpsim/sourcekitten/issues with the file contents.")
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

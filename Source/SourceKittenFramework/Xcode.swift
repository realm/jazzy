//
//  Xcode.swift
//  SourceKitten
//
//  Created by JP Simard on 7/15/15.
//  Copyright © 2015 SourceKitten. All rights reserved.
//

import Foundation

/**
Run `xcodebuild clean build` along with any passed in build arguments.

- parameter arguments: Arguments to pass to `xcodebuild`.
- parameter path:      Path to run `xcodebuild` from.

- returns: `xcodebuild`'s STDERR+STDOUT output combined.
*/
internal func runXcodeBuild(arguments: [String], inPath path: String) -> String? {
    fputs("Running xcodebuild\n", stderr)

    let task = NSTask()
    task.launchPath = "/usr/bin/xcodebuild"
    task.currentDirectoryPath = path
    task.arguments = arguments + ["clean", "build", "CODE_SIGN_IDENTITY=", "CODE_SIGNING_REQUIRED=NO"]

    let pipe = NSPipe()
    task.standardOutput = pipe
    task.standardError = pipe

    task.launch()

    let file = pipe.fileHandleForReading
    let xcodebuildOutput = NSString(data: file.readDataToEndOfFile(), encoding: NSUTF8StringEncoding)
    file.closeFile()

    return xcodebuildOutput as String?
}

/**
Parses likely module name from compiler or `xcodebuild` arguments.

Will the following values, in this priority: module name, target name, scheme name.

- parameter arguments: Compiler or `xcodebuild` arguments to parse.

- returns: Module name if successful.
*/
internal func moduleNameFromArguments(arguments: [String]) -> String? {
    let flags = ["-module-name", "-target", "-scheme"]
    for flag in flags {
        if let flagIndex = arguments.indexOf(flag) {
            if flagIndex + 1 < arguments.count {
                return arguments[flagIndex + 1]
            }
        }
    }
    return nil
}

/**
Partially filters compiler arguments from `xcodebuild` to something that SourceKit/Clang will accept.

- parameter args: Compiler arguments, as parsed from `xcodebuild`.

- returns: A tuple of partially filtered compiler arguments in `.0`, and whether or not there are
          more flags to remove in `.1`.
*/
private func partiallyFilterArguments(var args: [String]) -> ([String], Bool) {
    var didRemove = false
    let flagsToRemove = [
        "-output-file-map"
    ]
    for flag in flagsToRemove {
        if let index = args.indexOf(flag) {
            didRemove = true
            args.removeAtIndex(index.successor())
            args.removeAtIndex(index)
        }
    }
    return (args, didRemove)
}

/**
Filters compiler arguments from `xcodebuild` to something that SourceKit/Clang will accept.

- parameter args: Compiler arguments, as parsed from `xcodebuild`.

- returns: Filtered compiler arguments.
*/
private func filterArguments(var args: [String]) -> [String] {
    args.extend(["-D", "DEBUG"])
    var shouldContinueToFilterArguments = true
    while shouldContinueToFilterArguments {
        (args, shouldContinueToFilterArguments) = partiallyFilterArguments(args)
    }
    return args.filter {
        ![
            "-parseable-output",
            "-incremental",
            "-serialize-diagnostics",
            "-emit-dependencies"
        ].contains($0)
    }.map {
        if $0 == "-O" {
            return "-Onone"
        } else if $0 == "-DNDEBUG=1" {
            return "-DDEBUG=1"
        }
        return $0
    }
}

/**
Parses the compiler arguments needed to compile the `language` files.

- parameter xcodebuildOutput: Output of `xcodebuild` to be parsed for compiler arguments.
- parameter language:         Language to parse for.
- parameter moduleName:       Name of the Module for which to extract compiler arguments.

- returns: Compiler arguments, filtered for suitable use by SourceKit if `.Swift` or Clang if `.ObjC`.
*/
internal func parseCompilerArguments(xcodebuildOutput: NSString, language: Language, moduleName: String?) -> [String]? {
    let pattern: String
    if language == .ObjC {
        pattern = "/usr/bin/clang.*"
    } else if let moduleName = moduleName {
        pattern = "/usr/bin/swiftc.*-module-name \(moduleName) .*"
    } else {
        pattern = "/usr/bin/swiftc.*"
    }
    let regex = try! NSRegularExpression(pattern: pattern, options: []) // Safe to force try
    let range = NSRange(location: 0, length: xcodebuildOutput.length)

    guard let regexMatch = regex.firstMatchInString(xcodebuildOutput as String, options: [], range: range) else {
        return nil
    }

    let escapedSpacePlaceholder = "\u{0}"
    let args = filterArguments(xcodebuildOutput
        .substringWithRange(regexMatch.range)
        .stringByReplacingOccurrencesOfString("\\ ", withString: escapedSpacePlaceholder)
        .componentsSeparatedByString(" "))

    // Remove first argument (swiftc/clang) and re-add spaces in arguments
    return (args[1..<args.count]).map {
        $0.stringByReplacingOccurrencesOfString(escapedSpacePlaceholder, withString: " ")
    }
}

/**
Extracts Objective-C header files and `xcodebuild` arguments from an array of header files followed by `xcodebuild` arguments.

- parameter sourcekittenArguments: Array of Objective-C header files followed by `xcodebuild` arguments.

- returns: Tuple of header files and xcodebuild arguments.
*/
public func parseHeaderFilesAndXcodebuildArguments(sourcekittenArguments: [String]) -> (headerFiles: [String], xcodebuildArguments: [String]) {
    var xcodebuildArguments = sourcekittenArguments
    var headerFiles = [String]()
    while let headerFile = xcodebuildArguments.first where headerFile.isObjectiveCHeaderFile() {
        headerFiles.append(headerFile.absolutePathRepresentation())
        xcodebuildArguments.removeAtIndex(0)
    }
    return (headerFiles, xcodebuildArguments)
}

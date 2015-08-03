//
//  Language.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-03.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

/// Language Enum.
public enum Language {
    /// Swift.
    case Swift
    /// Objective-C.
    case ObjC
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
    return args.filter({
        ![
            "-parseable-output",
            "-incremental",
            "-serialize-diagnostics",
            "-emit-dependencies"
            ].contains($0)
    }).map {
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
    let pattern: String = {
        if language == .ObjC {
            return "/usr/bin/clang.*"
        } else if let moduleName = moduleName {
            return "/usr/bin/swiftc.*-module-name \(moduleName) .*"
        }
        return "/usr/bin/swiftc.*"
    }()
    let regex = try! NSRegularExpression(pattern: pattern, options: []) // Safe to force unwrap
    let range = NSRange(location: 0, length: xcodebuildOutput.length)

    if let regexMatch = regex.firstMatchInString(xcodebuildOutput as String, options: [], range: range) {
        let escapedSpacePlaceholder = "\u{0}"
        let args = filterArguments(xcodebuildOutput
            .substringWithRange(regexMatch.range)
            .stringByReplacingOccurrencesOfString("\\ ", withString: escapedSpacePlaceholder)
            .componentsSeparatedByString(" "))

        // Remove first argument (swiftc/clang) and re-add spaces in arguments
        return Array<String>(args[1..<args.count]).map {
            $0.stringByReplacingOccurrencesOfString(escapedSpacePlaceholder, withString: " ")
        }
    }

    return nil
}

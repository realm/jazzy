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

:param: args Compiler arguments, as parsed from `xcodebuild`.

:returns: A tuple of partially filtered compiler arguments in `.0`, and whether or not there are
          more flags to remove in `.1`.
*/
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

/**
Filters compiler arguments from `xcodebuild` to something that SourceKit/Clang will accept.

:param: args Compiler arguments, as parsed from `xcodebuild`.

:returns: Filtered compiler arguments.
*/
func filterArguments(var args: [String]) -> [String] {
    var shouldContinueToFilterArguments = true
    while shouldContinueToFilterArguments {
        (args, shouldContinueToFilterArguments) = partiallyFilterArguments(args)
    }
    return args.filter { $0 != "-parseable-output" }
}

/**
Parses the compiler arguments needed to compile the `language` files.

:param: xcodebuildOutput Output of `xcodebuild` to be parsed for compiler arguments.
:param: language         Language to parse for.
:param: moduleName       Name of the Module for which to extract compiler arguments.

:returns: Compiler arguments, filtered for suitable use by SourceKit if `.Swift` or Clang if `.ObjC`.
*/
public func parseCompilerArguments(xcodebuildOutput: NSString, #language: Language, #moduleName: String?) -> [String]? {
    let pattern: String = {
        if language == .ObjC {
            return "/usr/bin/clang.*"
        }
        if let moduleName = moduleName {
            return "/usr/bin/swiftc.*-module-name \(moduleName) .*"
        }
        return "/usr/bin/swiftc.*"
    }()
    let regex = NSRegularExpression(pattern: pattern, options: nil, error: nil)! // Safe to force unwrap
    let range = NSRange(location: 0, length: xcodebuildOutput.length)

    if let regexMatch = regex.firstMatchInString(xcodebuildOutput, options: nil, range: range) {
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

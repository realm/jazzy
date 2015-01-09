//
//  Module.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-07.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

public struct Module {
    public let name: String
    public let compilerArguments: [String]
    public let sourceFiles: [String]

    public var docs: [SwiftDocs] {
        return sourceFiles.map({
            if let file = File(path: $0) {
                return SwiftDocs(file: file, arguments: self.compilerArguments)
            }
            return nil
        }).filter({
            $0 != nil
        }).map {
            $0!
        }
    }

    public init?(xcodeBuildArguments: [String], moduleName: String? = nil, inPath path: String = NSFileManager.defaultManager().currentDirectoryPath) {
        let xcodeBuildOutput = runXcodeBuildDryRun(xcodeBuildArguments, inPath: path)
        if let arguments = parseCompilerArguments(xcodeBuildOutput, language: .Swift, moduleName: moduleName ?? moduleNameFromArguments(xcodeBuildArguments)) {
            if let moduleName = moduleNameFromArguments(arguments) {
                self.init(name: moduleName, compilerArguments: arguments)
                return
            }
        }
        return nil
    }

    public init(name: String, compilerArguments: [String]) {
        self.name = name
        self.compilerArguments = compilerArguments
        sourceFiles = swiftFilesFromArray(compilerArguments)
    }
}

// MARK: Printable

extension Module: Printable {
    public var description: String {
        return "Module(name: \(name), compilerArguments: \(compilerArguments), sourceFiles: \(sourceFiles))"
    }
}

/**
Run `xcodebuild clean build -dry-run` along with any passed in build arguments.
Return STDERR and STDOUT as a combined string.

:param: arguments array of arguments to pass to `xcodebuild`

:returns: xcodebuild STDERR+STDOUT output
*/
private func runXcodeBuildDryRun(arguments: [String], inPath path: String) -> String {
    let task = NSTask()
    task.launchPath = "/usr/bin/xcodebuild"
    task.currentDirectoryPath = path

    // Forward arguments to xcodebuild
    task.arguments = arguments + ["clean", "build", "-dry-run", "CODE_SIGN_IDENTITY=", "CODE_SIGNING_REQUIRED=NO"]

    let pipe = NSPipe()
    task.standardOutput = pipe
    task.standardError = pipe

    task.launch()

    let file = pipe.fileHandleForReading
    let xcodebuildOutput = NSString(data: file.readDataToEndOfFile(), encoding: NSUTF8StringEncoding)
    file.closeFile()

    return xcodebuildOutput ?? "" // Should never be nil
}

/**
Parses the compiler arguments needed to compile the `language` aspects of an Xcode project

:param: xcodebuildOutput output of `xcodebuild` to be parsed for compiler arguments

:returns: array of compiler arguments
*/
private func parseCompilerArguments(xcodebuildOutput: NSString, #language: Language, #moduleName: String?) -> [String]? {
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

private func moduleNameFromArguments(arguments: [String]) -> String? {
    let flags = ["-module-name", "-target", "-scheme"]
    for flag in flags {
        if let flagIndex = find(arguments, flag) {
            if flagIndex + 1 < arguments.count {
                return arguments[flagIndex + 1]
            }
        }
    }
    return nil
}

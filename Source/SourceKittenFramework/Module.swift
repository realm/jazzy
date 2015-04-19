//
//  Module.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-07.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

/// Represents source module to be documented.
public struct Module {
    /// Module Name.
    public let name: String
    /// Compiler arguments required by SourceKit to process the source files in this Module.
    public let compilerArguments: [String]
    /// Source files to be documented in this Module.
    public let sourceFiles: [String]

    /// Documentation for this Module. Typically expensive computed property.
    public var docs: [SwiftDocs] {
        var fileIndex = 1
        let sourceFilesCount = sourceFiles.count
        return compact(sourceFiles.map({
            if let file = File(path: $0) {
                fputs("Parsing \($0.lastPathComponent) (\(fileIndex++)/\(sourceFilesCount))\n", stderr)
                return SwiftDocs(file: file, arguments: self.compilerArguments)
            }
            fputs("Could not parse `\($0.lastPathComponent)`. Please open an issue at https://github.com/jpsim/SourceKitten/issues with the file contents.\n", stderr)
            return nil
        }))
    }

    /**
    Failable initializer to create a Module by the arguments necessary pass in to `xcodebuild` to build it.
    Optionally pass in a `moduleName` and `path`.

    :param: xcodeBuildArguments The arguments necessary pass in to `xcodebuild` to build this Module.
    :param: name                Module name. Will be parsed from `xcodebuild` output if nil.
    :param: path                Path to run `xcodebuild` from. Uses current path by default.
    */
    public init?(xcodeBuildArguments: [String], name: String? = nil, inPath path: String = NSFileManager.defaultManager().currentDirectoryPath) {
        let xcodeBuildOutput = runXcodeBuild(xcodeBuildArguments, inPath: path) ?? ""
        if let arguments = parseCompilerArguments(xcodeBuildOutput, language: .Swift, moduleName: name ?? moduleNameFromArguments(xcodeBuildArguments)) {
            if let moduleName = moduleNameFromArguments(arguments) {
                self.init(name: moduleName, compilerArguments: arguments)
                return
            }
            fputs("Could not parse module name from compiler arguments.\n", stderr)
            return nil
        }
        fputs("Could not parse compiler arguments from `xcodebuild` output.\n", stderr)
        fputs("\(xcodeBuildOutput)\n", stderr)
        return nil
    }

    /**
    Initializer to create a Module by name and compiler arguments.

    :param: name              Module name.
    :param: compilerArguments Compiler arguments required by SourceKit to process the source files in this Module.
    */
    public init(name: String, compilerArguments: [String]) {
        self.name = name
        self.compilerArguments = compilerArguments
        sourceFiles = compilerArguments.filter { $0.isSwiftFile() }
    }
}

// MARK: Printable

extension Module: Printable {
    /// A textual representation of `Module`.
    public var description: String {
        return "Module(name: \(name), compilerArguments: \(compilerArguments), sourceFiles: \(sourceFiles))"
    }
}

/**
Run `xcodebuild clean build` along with any passed in build arguments.

:param: arguments Arguments to pass to `xcodebuild`.
:param: path      Path to run `xcodebuild` from.

:returns: `xcodebuild`'s STDERR+STDOUT output combined.
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

    return xcodebuildOutput as! String?
}

/**
Parses likely module name from compiler or `xcodebuild` arguments.

Will the following values, in this priority: module name, target name, scheme name.

:param: arguments Compiler or `xcodebuild` arguments to parse.

:returns: Module name if successful.
*/
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

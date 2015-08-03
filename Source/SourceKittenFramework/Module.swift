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
        return sourceFiles.flatMap {
            if let file = File(path: $0) {
                fputs("Parsing \($0.lastPathComponent) (\(fileIndex++)/\(sourceFilesCount))\n", stderr)
                return SwiftDocs(file: file, arguments: compilerArguments)
            }
            fputs("Could not parse `\($0.lastPathComponent)`. Please open an issue at https://github.com/jpsim/SourceKitten/issues with the file contents.\n", stderr)
            return nil
        }
    }

    /**
    Failable initializer to create a Module by the arguments necessary pass in to `xcodebuild` to build it.
    Optionally pass in a `moduleName` and `path`.

    - parameter xcodeBuildArguments: The arguments necessary pass in to `xcodebuild` to build this Module.
    - parameter name:                Module name. Will be parsed from `xcodebuild` output if nil.
    - parameter path:                Path to run `xcodebuild` from. Uses current path by default.
    */
    public init?(xcodeBuildArguments: [String], name: String? = nil, inPath path: String = NSFileManager.defaultManager().currentDirectoryPath) {
        let xcodeBuildOutput = runXcodeBuild(xcodeBuildArguments, inPath: path) ?? ""
        guard let arguments = parseCompilerArguments(xcodeBuildOutput, language: .Swift, moduleName: name ?? moduleNameFromArguments(xcodeBuildArguments)) else {
            fputs("Could not parse compiler arguments from `xcodebuild` output.\n", stderr)
            fputs("\(xcodeBuildOutput)\n", stderr)
            return nil
        }
        guard let moduleName = moduleNameFromArguments(arguments) else {
            fputs("Could not parse module name from compiler arguments.\n", stderr)
            return nil
        }
        self.init(name: moduleName, compilerArguments: arguments)
    }

    /**
    Initializer to create a Module by name and compiler arguments.

    - parameter name:              Module name.
    - parameter compilerArguments: Compiler arguments required by SourceKit to process the source files in this Module.
    */
    public init(name: String, compilerArguments: [String]) {
        self.name = name
        self.compilerArguments = compilerArguments
        sourceFiles = compilerArguments.filter({ $0.isSwiftFile() }).map { ($0 as NSString).stringByResolvingSymlinksInPath }
    }
}

// MARK: CustomStringConvertible

extension Module: CustomStringConvertible {
    /// A textual representation of `Module`.
    public var description: String {
        return "Module(name: \(name), compilerArguments: \(compilerArguments), sourceFiles: \(sourceFiles))"
    }
}

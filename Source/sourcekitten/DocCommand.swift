//
//  DocCommand.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-07.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import Commandant
import Foundation
import Result
import SourceKittenFramework

struct DocCommand: CommandType {
    let verb = "doc"
    let function = "Print Swift docs as JSON or Objective-C docs as XML"

    func run(mode: CommandMode) -> Result<(), CommandantError<SourceKittenError>> {
        return DocOptions.evaluate(mode).flatMap { options in
            let args = Process.arguments
            if options.objc {
                return runObjC(options, args: args)
            }
            if options.singleFile {
                return runSwiftSingleFile(args)
            }
            let moduleName: String? = options.moduleName.isEmpty ? nil : options.moduleName
            return runSwiftModule(moduleName, args: args)
        }
    }

    func runSwiftModule(moduleName: String?, args: [String]) -> Result<(), CommandantError<SourceKittenError>> {
        let xcodeBuildArgumentsStart = (moduleName != nil) ? 4 : 2
        let xcodeBuildArguments = Array<String>(args[xcodeBuildArgumentsStart..<args.count])
        let module = Module(xcodeBuildArguments: xcodeBuildArguments, name: moduleName)

        if let docs = module?.docs {
            print(docs)
            return .Success()
        }
        return .Failure(.CommandError(.DocFailed))
    }

    func runSwiftSingleFile(args: [String]) -> Result<(), CommandantError<SourceKittenError>> {
        if args.count < 5 {
            return .Failure(.CommandError(.InvalidArgument(description: "at least 5 arguments are required when using `--single-file`")))
        }
        let sourcekitdArguments = Array<String>(args[4..<args.count])
        if let file = File(path: args[3]) {
            let docs = SwiftDocs(file: file, arguments: sourcekitdArguments)
            print(docs)
            return .Success()
        }
        return .Failure(.CommandError(.ReadFailed(path: args[3])))
    }

    func runObjC(options: DocOptions, args: [String]) -> Result<(), CommandantError<SourceKittenError>> {
        let translationUnit = ClangTranslationUnit(headerFiles: [args[3]], compilerArguments: Array<String>(args[4..<args.count]))
        print(translationUnit)
        return .Success()
    }
}

struct DocOptions: OptionsType {
    let singleFile: Bool
    let moduleName: String
    let objc: Bool

    static func create(singleFile: Bool)(moduleName: String)(objc: Bool) -> DocOptions {
        return self.init(singleFile: singleFile, moduleName: moduleName, objc: objc)
    }

    static func evaluate(m: CommandMode) -> Result<DocOptions, CommandantError<SourceKittenError>> {
        return create
            <*> m <| Option(key: "single-file", defaultValue: false, usage: "only document one file")
            <*> m <| Option(key: "module-name", defaultValue: "",    usage: "name of module to document (can't be used with `--single-file` or `--objc`)")
            <*> m <| Option(key: "objc",        defaultValue: false, usage: "document Objective-C headers")
    }
}

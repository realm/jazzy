//
//  DocCommand.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-07.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import Commandant
import Foundation
import LlamaKit
import SourceKittenFramework

public struct DocCommand: CommandType {
    public let verb = "doc"
    public let function = "Print Swift docs as JSON"

    public func run(mode: CommandMode) -> Result<()> {
        return DocOptions.evaluate(mode).flatMap { options in
            let args = Process.arguments
            if options.singleFile {
                if args.count < 5 {
                    return failure(NSError(domain: "com.sourcekitten.SourceKitten", code: 0, userInfo: [NSLocalizedDescriptionKey: "must have at least 5 arguments to call `doc --single-file`"]))
                }
                let sourcekitdArguments = Array<String>(args[4..<args.count])
                if let file = File(path: args[3]) {
                    let docs = SwiftDocs(file: file, arguments: sourcekitdArguments)
                    println(docs)
                    return success(())
                }
                return failure(NSError(domain: "com.sourcekitten.SourceKitten", code: 1, userInfo: [NSLocalizedDescriptionKey: "file could not be read"]))
            }
            let moduleName: String? = countElements(options.moduleName) > 0 ? options.moduleName : nil
            let xcodeBuildArgumentsStart = (moduleName != nil) ? 4 : 2
            let xcodeBuildArguments = Array<String>(args[xcodeBuildArgumentsStart..<args.count])
            if let docs = Module(xcodeBuildArguments: xcodeBuildArguments, name: moduleName)?.docs {
                println(docs)
                return success(())
            }
            return failure(NSError(domain: "com.sourcekitten.SourceKitten", code: 2, userInfo: [NSLocalizedDescriptionKey: "could not generate docs"]))
        }
    }
}

public struct DocOptions: OptionsType {
    public let singleFile: Bool
    public let moduleName: String

    public static func create(singleFile: Bool)(moduleName: String) -> DocOptions {
        return self(singleFile: singleFile, moduleName: moduleName)
    }

    public static func evaluate(m: CommandMode) -> Result<DocOptions> {
        return create
            <*> m <| Option(key: "single-file", defaultValue: false, usage: "only document one file")
            <*> m <| Option(key: "module-name", defaultValue: "", usage: "name of module to document (can't be used with `single-file`)")
    }
}

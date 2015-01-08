//
//  Structure.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-07.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import Commandant
import Foundation
import LlamaKit
import SourceKittenFramework

public struct StructureCommand: CommandType {
    public let verb = "structure"
    public let function = "Print Swift structure information as JSON"

    public func run(mode: CommandMode) -> Result<()> {
        return StructureOptions.evaluate(mode).flatMap { options in
            if countElements(options.file) > 0 {
                if let file = File(path: options.file.absolutePathRepresentation()) {
                    println(Structure(file: file))
                } else {
                    return failure(NSError(domain: "com.sourcekitten.SourceKitten", code: 0, userInfo: [NSLocalizedDescriptionKey: "file could not be read"]))
                }
                return success(())
            }
            if countElements(options.text) > 0 {
                println(Structure(file: File(contents: options.text)))
                return success(())
            }
            return failure(NSError(domain: "com.sourcekitten.SourceKitten", code: 1, userInfo: [NSLocalizedDescriptionKey: "either file or text must be set when calling structure"]))
        }
    }
}

public struct StructureOptions: OptionsType {
    public let file: String
    public let text: String

    public static func create(file: String)(text: String) -> StructureOptions {
        return self(file: file, text: text)
    }

    public static func evaluate(m: CommandMode) -> Result<StructureOptions> {
        return create
            <*> m <| Option(key: "file", defaultValue: "", usage: "relative or absolute path of Swift file to parse")
            <*> m <| Option(key: "text", defaultValue: "", usage: "Swift code text to parse")
    }
}

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

struct StructureCommand: CommandType {
    let verb = "structure"
    let function = "Print Swift structure information as JSON"

    func run(mode: CommandMode) -> Result<()> {
        return StructureOptions.evaluate(mode).flatMap { options in
            if countElements(options.file) > 0 {
                if let file = File(path: options.file.absolutePathRepresentation()) {
                    println(Structure(file: file))
                } else {
                    return failure(SourceKittenError.ReadFailed(path: options.file).error)
                }
                return success(())
            }
            if countElements(options.text) > 0 {
                println(Structure(file: File(contents: options.text)))
                return success(())
            }
            return failure(SourceKittenError.InvalidArgument(description: "either file or text must be set when calling structure").error)
        }
    }
}

struct StructureOptions: OptionsType {
    let file: String
    let text: String

    static func create(file: String)(text: String) -> StructureOptions {
        return self(file: file, text: text)
    }

    static func evaluate(m: CommandMode) -> Result<StructureOptions> {
        return create
            <*> m <| Option(key: "file", defaultValue: "", usage: "relative or absolute path of Swift file to parse")
            <*> m <| Option(key: "text", defaultValue: "", usage: "Swift code text to parse")
    }
}

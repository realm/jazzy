//
//  Syntax.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-07.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import Commandant
import Foundation
import LlamaKit
import SourceKittenFramework

struct SyntaxCommand: CommandType {
    let verb = "syntax"
    let function = "Print Swift syntax information as JSON"

    func run(mode: CommandMode) -> Result<()> {
        return SyntaxOptions.evaluate(mode).flatMap { options in
            if countElements(options.file) > 0 {
                if let file = File(path: options.file.absolutePathRepresentation()) {
                    println(SyntaxMap(file: file))
                } else {
                    return failure(SourceKittenError.ReadFailed(path: options.file).error)
                }
                return success(())
            }
            if countElements(options.text) > 0 {
                println(SyntaxMap(file: File(contents: options.text)))
                return success(())
            }
            return failure(SourceKittenError.InvalidArgument(description: "either file or text must be set when calling syntax").error)
        }
    }
}

struct SyntaxOptions: OptionsType {
    let file: String
    let text: String

    static func create(file: String)(text: String) -> SyntaxOptions {
        return self(file: file, text: text)
    }

    static func evaluate(m: CommandMode) -> Result<SyntaxOptions> {
        return create
            <*> m <| Option(key: "file", defaultValue: "", usage: "relative or absolute path of Swift file to parse")
            <*> m <| Option(key: "text", defaultValue: "", usage: "Swift code text to parse")
    }
}

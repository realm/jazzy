//
//  Structure.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-07.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import Commandant
import Foundation
import SourceKittenFramework
import Result

struct StructureCommand: CommandType {
    let verb = "structure"
    let function = "Print Swift structure information as JSON"

    func run(mode: CommandMode) -> Result<(), CommandantError<SourceKittenError>> {
        return StructureOptions.evaluate(mode).flatMap { options in
            if options.file.characters.count > 0 {
                if let file = File(path: options.file.absolutePathRepresentation()) {
                    print(Structure(file: file))
                    return .Success()
                }
                return .Failure(.CommandError(.ReadFailed(path: options.file)))
            }
            if options.text.characters.count > 0 {
                print(Structure(file: File(contents: options.text)))
                return .Success()
            }
            return .Failure(.CommandError(
                .InvalidArgument(description: "either file or text must be set when calling structure")
            ))
        }
    }
}

struct StructureOptions: OptionsType {
    let file: String
    let text: String

    static func create(file: String)(text: String) -> StructureOptions {
        return self.init(file: file, text: text)
    }

    static func evaluate(m: CommandMode) -> Result<StructureOptions, CommandantError<SourceKittenError>> {
        return create
            <*> m <| Option(key: "file", defaultValue: "", usage: "relative or absolute path of Swift file to parse")
            <*> m <| Option(key: "text", defaultValue: "", usage: "Swift code text to parse")
    }
}

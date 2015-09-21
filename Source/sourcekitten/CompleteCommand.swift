//
//  CompleteCommand.swift
//  SourceKitten
//
//  Created by JP Simard on 9/4/15.
//  Copyright © 2015 SourceKitten. All rights reserved.
//

import Commandant
import Foundation
import Result
import SourceKittenFramework
import SwiftXPC

struct CompleteCommand: CommandType {
    let verb = "complete"
    let function = "Generate code completion options."

    func run(mode: CommandMode) -> Result<(), CommandantError<SourceKittenError>> {
        return CompleteOptions.evaluate(mode).flatMap { options in
            let path: String
            let contents: String
            if !options.file.isEmpty {
                path = options.file.absolutePathRepresentation()
                if let file = File(path: path) {
                    contents = file.contents
                }
                else {
                    return .Failure(.CommandError(.ReadFailed(path: options.file)))
                }
            } else {
                path = "\(NSUUID().UUIDString).swift"
                contents = options.text
            }
            let request = Request.CodeCompletionRequest(file: path, contents: contents,
                                                        offset: Int64(options.offset),
                                                        arguments: ["-sdk", sdkPath(), "-c", path])
            print(CodeCompletionItem.parseResponse(request.send()))
            return .Success()
        }
    }
}

struct CompleteOptions: OptionsType {
    let file: String
    let text: String
    let offset: Int

    static func create(file: String)(text: String)(offset: Int) -> CompleteOptions {
        return self.init(file: file, text: text, offset: offset)
    }

    static func evaluate(m: CommandMode) -> Result<CompleteOptions, CommandantError<SourceKittenError>> {
        return create
            <*> m <| Option(key: "file", defaultValue: "", usage: "relative or absolute path of Swift file to parse")
            <*> m <| Option(key: "text", defaultValue: "", usage: "Swift code text to parse")
            <*> m <| Option(key: "offset", defaultValue: 0, usage: "Offset for which to generate code completion options.")
    }
}

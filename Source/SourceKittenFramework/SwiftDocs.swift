//
//  SwiftDocs.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-03.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import Foundation
import SwiftXPC

public struct SwiftDocs {
    public let docsDictionary: XPCDictionary

    /**
    Create docs for the specified Swift file.

    :param: file Swift file to document
    :param: arguments compiler arguments to pass to SourceKit
    */
    public init(file: File, arguments: [String]) {
        self.init(
            file: file,
            dictionary: Request.EditorOpen(file).send(),
            cursorInfoRequest: Request.cursorInfoRequestForFilePath(file.path, arguments: arguments)
        )
    }

    /**
    Create docs for the specified Swift file.

    :param: file Swift file to document
    :param: dictionary editor.open response from SourceKit
    :param: cursorInfoRequest SourceKit xpc dictionary to use to send cursorinfo request.
    */
    public init(file: File, var dictionary: XPCDictionary, cursorInfoRequest: xpc_object_t?) {
        let syntaxMapData = dictionary.removeValueForKey(SwiftDocKey.SyntaxMap.rawValue) as NSData
        dictionary = file.processDictionary(dictionary, cursorInfoRequest: cursorInfoRequest)
        if let cursorInfoRequest = cursorInfoRequest {
            let documentedTokenOffsets = file.contents.documentedTokenOffsets(SyntaxMap(data: syntaxMapData))
            dictionary = file.furtherProcessDictionary(
                dictionary,
                documentedTokenOffsets: documentedTokenOffsets,
                cursorInfoRequest: cursorInfoRequest
            )
        }
        docsDictionary = dictionary
    }
}

// MARK: Printable

extension SwiftDocs: Printable {
    public var description: String { return toJSON(docsDictionary) }
}

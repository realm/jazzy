//
//  Structure.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-06.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import Foundation
import SwiftXPC

public struct Structure {
    public let dictionary: XPCDictionary

    public init(file: File) {
        dictionary = Request.EditorOpen(file).send()
        dictionary.removeValueForKey(SwiftDocKey.SyntaxMap.rawValue)
        dictionary = file.processDictionary(dictionary)
    }
}

// MARK: Printable

extension Structure: Printable {
    /// A textual JSON representation of `Structure`.
    public var description: String { return toJSON(dictionary) }
}

// MARK: Equatable

extension Structure: Equatable {}

public func ==(lhs: Structure, rhs: Structure) -> Bool {
    return lhs.dictionary == rhs.dictionary
}

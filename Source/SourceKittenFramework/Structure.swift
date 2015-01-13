//
//  Structure.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-06.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import Foundation
import SwiftXPC

/// Represents the structural information in a Swift source file.
public struct Structure {
    /// Structural information as an XPCDictionary.
    public let dictionary: XPCDictionary

    /**
    Initialize a Structure by passing in a File.

    :param: file File to parse for structural information.
    */
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

/**
Returns true if `lhs` Structure is equal to `rhs` Structure.

:param: lhs Structure to compare to `rhs`.
:param: rhs Structure to compare to `lhs`.

:returns: True if `lhs` Structure is equal to `rhs` Structure.
*/
public func ==(lhs: Structure, rhs: Structure) -> Bool {
    return lhs.dictionary == rhs.dictionary
}

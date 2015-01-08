//
//  SyntaxToken.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-03.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import Foundation

public struct SyntaxToken: Equatable {
    public let type: String
    public let offset: Int
    public let length: Int

    public var dictionaryValue: NSDictionary {
        return ["type": type, "offset": offset, "length": length]
    }

    public init(type: String, offset: Int, length: Int) {
        self.type = type
        self.offset = offset
        self.length = length
    }
}

public func ==(lhs: SyntaxToken, rhs: SyntaxToken) -> Bool {
    return (lhs.type == rhs.type) && (lhs.offset == rhs.offset) && (lhs.length == rhs.length)
}

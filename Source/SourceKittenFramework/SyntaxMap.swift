//
//  SyntaxMap.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-03.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import Foundation
import SwiftXPC

// MARK: SyntaxMap

public struct SyntaxMap {
    public let tokens: [SyntaxToken]

    public init(tokens: [SyntaxToken]) {
        self.tokens = tokens
    }

    public init(data: NSData) {
        var numberOfTokens = 0
        data.getBytes(&numberOfTokens, range: NSRange(location: 8, length: 8))
        numberOfTokens = numberOfTokens >> 4

        tokens = [SyntaxToken]()

        for parserOffset in stride(from: 16, through: numberOfTokens * 16, by: 16) {
            var uid = UInt64(0), offset = 0, length = 0
            data.getBytes(&uid, range: NSRange(location: parserOffset, length: 8))
            data.getBytes(&offset, range: NSRange(location: 8 + parserOffset, length: 4))
            data.getBytes(&length, range: NSRange(location: 12 + parserOffset, length: 4))

            tokens.append(
                SyntaxToken(
                    type: stringForSourceKitUID(uid) ?? "unknown",
                    offset: offset,
                    length: length >> 1
                )
            )
        }
    }

    public init(sourceKitResponse: XPCDictionary) {
        self.init(data: SwiftDocKey.getSyntaxMap(sourceKitResponse)!)
    }

    public init(file: File) {
        self.init(sourceKitResponse: Request.EditorOpen(file).send())
    }
}

// MARK: Printable

extension SyntaxMap: Printable {
    /// A textual JSON representation of `SyntaxMap`.
    public var description: String {
        if let jsonData = NSJSONSerialization.dataWithJSONObject(tokens.map { $0.dictionaryValue },
            options: .PrettyPrinted,
            error: nil) {
            if let jsonString = NSString(data: jsonData, encoding: NSUTF8StringEncoding) {
                return jsonString
            }
        }
        return "[\n\n]" // Empty JSON Array
    }
}

// MARK: Equatable

extension SyntaxMap: Equatable {}

public func ==(lhs: SyntaxMap, rhs: SyntaxMap) -> Bool {
    for (index, value) in enumerate(lhs.tokens) {
        if rhs.tokens[index] != value {
            return false
        }
    }
    return true
}

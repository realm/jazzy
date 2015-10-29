//
//  SyntaxMap.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-03.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import Foundation
import SwiftXPC

/// Represents a Swift file's syntax information.
public struct SyntaxMap {
    /// Array of SyntaxToken's.
    public let tokens: [SyntaxToken]

    /**
    Create a SyntaxMap by passing in tokens directly.

    - parameter tokens: Array of SyntaxToken's.
    */
    public init(tokens: [SyntaxToken]) {
        self.tokens = tokens
    }

    /**
    Create a SyntaxMap by passing in NSData from a SourceKit `editor.open` response to be parsed.

    - parameter data: NSData from a SourceKit `editor.open` response
    */
    public init(data: NSData) {
        var numberOfTokens = 0
        data.getBytes(&numberOfTokens, range: NSRange(location: 8, length: 8))
        numberOfTokens = numberOfTokens >> 4

        tokens = 16.stride(through: numberOfTokens * 16, by: 16).map { parserOffset in
            var uid = UInt64(0), offset = 0, length = 0
            data.getBytes(&uid, range: NSRange(location: parserOffset, length: 8))
            data.getBytes(&offset, range: NSRange(location: 8 + parserOffset, length: 4))
            data.getBytes(&length, range: NSRange(location: 12 + parserOffset, length: 4))

            return SyntaxToken(
                type: stringForSourceKitUID(uid) ?? "unknown",
                offset: offset,
                length: length >> 1
            )
        }
    }

    /**
    Create a SyntaxMap from a SourceKit `editor.open` response.

    - parameter sourceKitResponse: SourceKit `editor.open` response.
    */
    public init(sourceKitResponse: XPCDictionary) {
        self.init(data: SwiftDocKey.getSyntaxMap(sourceKitResponse)!)
    }

    /**
    Create a SyntaxMap from a File to be parsed.

    - parameter file: File to be parsed.
    */
    public init(file: File) {
        self.init(sourceKitResponse: Request.EditorOpen(file).send())
    }

    /**
    Returns the range of the last contiguous comment-like block from the tokens in `self` prior to
    `offset`.
    
    - parameter offset: Last possible byte offset of the range's start.
    */
    public func commentRangeBeforeOffset(offset: Int) -> Range<Int>? {
        let tokensBeforeOffset = tokens.filter { $0.offset < offset }
        let commentTokensImmediatelyPrecedingOffset = filterLastContiguous(tokensBeforeOffset) {
            SyntaxKind.isCommentLike($0.type)
        }
        return commentTokensImmediatelyPrecedingOffset.first.flatMap { firstToken in
            return commentTokensImmediatelyPrecedingOffset.last.map { lastToken in
                return Range(start: firstToken.offset, end: lastToken.offset + lastToken.length)
            }
        }
    }
}

// MARK: CustomStringConvertible

extension SyntaxMap: CustomStringConvertible {
    /// A textual JSON representation of `SyntaxMap`.
    public var description: String {
        do {
            let jsonData = try NSJSONSerialization.dataWithJSONObject(tokens.map { $0.dictionaryValue },
                options: .PrettyPrinted)
            if let jsonString = NSString(data: jsonData, encoding: NSUTF8StringEncoding) as String? {
                return jsonString
            }
        } catch {}
        return "[\n\n]" // Empty JSON Array
    }
}

// MARK: Equatable

extension SyntaxMap: Equatable {}

/**
Returns true if `lhs` SyntaxMap is equal to `rhs` SyntaxMap.

- parameter lhs: SyntaxMap to compare to `rhs`.
- parameter rhs: SyntaxMap to compare to `lhs`.

- returns: True if `lhs` SyntaxMap is equal to `rhs` SyntaxMap.
*/
public func ==(lhs: SyntaxMap, rhs: SyntaxMap) -> Bool {
    if lhs.tokens.count != rhs.tokens.count {
        return false
    }
    for (index, value) in lhs.tokens.enumerate() {
        if rhs.tokens[index] != value {
            return false
        }
    }
    return true
}

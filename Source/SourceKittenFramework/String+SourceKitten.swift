//
//  String+SourceKitten.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-05.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import Foundation

public typealias Line = (index: Int, content: String)

private let whitespaceAndNewlineCharacterSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()

extension NSString {
    /**
    Binary search for NSString index equivalent to byte offset.

    - parameter offset: Byte offset.

    - returns: NSString index, if any.
    */
    private func indexOfByteOffset(offset: Int) -> Int? {
        var usedLength = 0

        var left = Int(floor(Double(offset)/2))
        var right = min(length, offset + 1)
        var midpoint = (left + right) / 2

        for _ in left..<right {
            getBytes(nil,
                maxLength: Int.max,
                usedLength: &usedLength,
                encoding: NSUTF8StringEncoding,
                options: [],
                range: NSRange(location: 0, length: midpoint),
                remainingRange: nil)
            if usedLength < offset {
                left = midpoint
                midpoint = (right + left) / 2
            } else if usedLength > offset {
                right = midpoint
                midpoint = (right + left) / 2
            } else {
                return midpoint
            }
        }
        return nil
    }

    /**
    Returns a copy of `self` with the trailing contiguous characters belonging to `characterSet`
    removed.

    - parameter characterSet: Character set to check for membership.
    */
    public func stringByTrimmingTrailingCharactersInSet(characterSet: NSCharacterSet) -> String {
        if length == 0 {
            return self as String
        }
        var charBuffer = [unichar](count: length, repeatedValue: 0)
        getCharacters(&charBuffer)
        for newLength in (1...length).reverse() {
            if !characterSet.characterIsMember(charBuffer[newLength - 1]) {
                return substringWithRange(NSRange(location: 0, length: newLength))
            }
        }
        return self as String
    }

    /**
    Returns self represented as an absolute path.

    - parameter rootDirectory: Absolute parent path if not already an absolute path.
    */
    public func absolutePathRepresentation(rootDirectory: String = NSFileManager.defaultManager().currentDirectoryPath) -> String {
        if absolutePath {
            return self as String
        }
        return NSString.pathWithComponents([rootDirectory, self as String]).stringByStandardizingPath
    }

    /**
    Converts a range of byte offsets in `self` to an `NSRange` suitable for filtering `self` as an
    `NSString`.

    - parameter start: Starting byte offset.
    - parameter length: Length of bytes to include in range.

    - returns: An equivalent `NSRange`.
    */
    public func byteRangeToNSRange(start start: Int, length: Int) -> NSRange? {
        return indexOfByteOffset(start).flatMap { stringStart in
            return indexOfByteOffset(start + length).map { stringEnd in
                return NSRange(location: stringStart, length: stringEnd - stringStart)
            }
        }
    }

    /**
    Returns a substring with the provided byte range.

    - parameter start: Starting byte offset.
    - parameter length: Length of bytes to include in range.
    */
    public func substringWithByteRange(start start: Int, length: Int) -> String? {
        return byteRangeToNSRange(start: start, length: length).map(substringWithRange)
    }

    /**
    Returns a substring starting at the beginning of `start`'s line and ending at the end of `end`'s
    line. Returns `start`'s entire line if `end` is nil.

    - parameter start: Starting byte offset.
    - parameter length: Length of bytes to include in range.
    */
    public func substringLinesWithByteRange(start start: Int, length: Int) -> String? {
        return byteRangeToNSRange(start: start, length: length).map { range in
            var lineStart = 0, lineEnd = 0
            getLineStart(&lineStart, end: &lineEnd, contentsEnd: nil, forRange: range)
            return substringWithRange(NSRange(location: lineStart, length: lineEnd - lineStart))
        }
    }

    /**
    Returns line numbers containing starting and ending byte offsets.

    - parameter start: Starting byte offset.
    - parameter length: Length of bytes to include in range.
    */
    public func lineRangeWithByteRange(start start: Int, length: Int) -> (start: Int, end: Int)? {
        return byteRangeToNSRange(start: start, length: length).flatMap { range in
            var numberOfLines = 0, index = 0, lineRangeStart = 0
            while index < self.length {
                numberOfLines++
                if index <= range.location {
                    lineRangeStart = numberOfLines
                }
                index = NSMaxRange(lineRangeForRange(NSRange(location: index, length: 1)))
                if index > NSMaxRange(range) {
                    return (lineRangeStart, numberOfLines)
                }
            }
            return nil
        }
    }
}

extension String {
    /**
    Returns an array of Lines for each line in the file
    */
    internal func lines() -> [Line] {
        var lines = [Line]()
        var lineIndex = 1
        enumerateLines { line, _ in
            lines.append((lineIndex++, line))
        }
        return lines
    }

    /**
    Returns true if self is an Objective-C header file.
    */
    public func isObjectiveCHeaderFile() -> Bool {
        return ["h", "hpp", "hh"].contains(pathExtension)
    }

    /**
    Returns true if self is a Swift file.
    */
    public func isSwiftFile() -> Bool {
        return pathExtension == "swift"
    }

    /**
    Returns whether or not the `token` can be documented. Either because it is a
    `SyntaxKind.Identifier` or because it is a function treated as a `SyntaxKind.Keyword`:

    - `subscript`
    - `init`
    - `deinit`

    - parameter token: Token to process.
    */
    public func isTokenDocumentable(token: SyntaxToken) -> Bool {
        if token.type == SyntaxKind.Keyword.rawValue {
            let keywordFunctions = ["subscript", "init", "deinit"]
            return ((self as NSString).substringWithByteRange(start: token.offset, length: token.length))
                .map(keywordFunctions.contains) ?? false
        }
        return token.type == SyntaxKind.Identifier.rawValue
    }

    /**
    Find integer offsets of documented Swift tokens in self.

    - parameter syntaxMap: Syntax Map returned from SourceKit editor.open request.

    - returns: Array of documented token offsets.
    */
    public func documentedTokenOffsets(syntaxMap: SyntaxMap) -> [Int] {
        let documentableOffsets = syntaxMap.tokens.filter(isTokenDocumentable).map {
            $0.offset
        }

        let regex = try! NSRegularExpression(pattern: "(///.*\\n|\\*/\\n)", options: []) // Safe to force try
        let range = NSRange(location: 0, length: utf16.count)
        let matches = regex.matchesInString(self, options: [], range: range)

        return matches.flatMap { match in
            documentableOffsets.filter({ $0 >= match.range.location }).first
        }
    }

    /**
    Returns the body of the comment if the string is a comment.
    
    - parameter range: Range to restrict the search for a comment body.
    */
    public func commentBody(range: NSRange? = nil) -> String? {
        let nsString = self as NSString
        let patterns: [(pattern: String, options: NSRegularExpressionOptions)] = [
            ("^\\s*\\/\\*\\*\\s*(.+)\\*\\/", [.AnchorsMatchLines, .DotMatchesLineSeparators]),   // multi: ^\s*\/\*\*\s*(.+)\*\/
            ("^\\s*\\/\\/\\/(.+)?",          .AnchorsMatchLines)                                 // single: ^\s*\/\/\/(.+)?
        ]
        let range = range ?? NSRange(location: 0, length: nsString.length)
        for pattern in patterns {
            let regex = try! NSRegularExpression(pattern: pattern.pattern, options: pattern.options) // Safe to force try
            let matches = regex.matchesInString(self, options: [], range: range)
            let bodyParts = matches.flatMap { match -> [String] in
                let numberOfRanges = match.numberOfRanges
                if numberOfRanges < 1 {
                    return []
                }
                return (1..<numberOfRanges).map { rangeIndex in
                    let range = match.rangeAtIndex(rangeIndex)
                    if range.location == NSNotFound {
                        return "" // empty capture group, return empty string
                    }
                    var lineStart = 0
                    var lineEnd = nsString.length
                    guard let indexRange = self.byteRangeToNSRange(start: range.location, length: 0) else {
                        return "" // out of range, return empty string
                    }
                    nsString.getLineStart(&lineStart, end: &lineEnd, contentsEnd: nil, forRange: indexRange)
                    let leadingWhitespaceCountToAdd = nsString.substringWithRange(NSRange(location: lineStart, length: lineEnd - lineStart)).countOfLeadingCharactersInSet(whitespaceAndNewlineCharacterSet)
                    let leadingWhitespaceToAdd = String(count: leadingWhitespaceCountToAdd, repeatedValue: Character(" "))

                    let bodySubstring = nsString.substringWithRange(range)
                    return leadingWhitespaceToAdd + bodySubstring
                }
            }
            if bodyParts.count > 0 {
                return "\n"
                    .join(bodyParts)
                    .stringByTrimmingTrailingCharactersInSet(whitespaceAndNewlineCharacterSet)
                    .stringByRemovingCommonLeadingWhitespaceFromLines()
            }
        }
        return nil
    }

    /// Returns a copy of `self` with the leading whitespace common in each line removed.
    public func stringByRemovingCommonLeadingWhitespaceFromLines() -> String {
        var minLeadingWhitespace = Int.max
        enumerateLines { line, _ in
            let lineLeadingWhitespace = line.countOfLeadingCharactersInSet(whitespaceAndNewlineCharacterSet)
            if lineLeadingWhitespace < minLeadingWhitespace && lineLeadingWhitespace != line.characters.count {
                minLeadingWhitespace = lineLeadingWhitespace
            }
        }
        var lines = [String]()
        enumerateLines { line, _ in
            if line.characters.count >= minLeadingWhitespace {
                lines.append(line[advance(line.startIndex, minLeadingWhitespace)..<line.endIndex])
            } else {
                lines.append(line)
            }
        }
        return "\n".join(lines)
    }

    /**
    Returns the number of contiguous characters at the start of `self` belonging to `characterSet`.
    
    - parameter characterSet: Character set to check for membership.
    */
    public func countOfLeadingCharactersInSet(characterSet: NSCharacterSet) -> Int {
        let utf16View = utf16
        var count = 0
        for char in utf16View {
            if !characterSet.characterIsMember(char) {
                break
            }
            count++
        }
        return count
    }

    /// Returns a copy of the string by trimming whitespace and the opening curly brace (`{`).
    internal func stringByTrimmingWhitespaceAndOpeningCurlyBrace() -> String? {
        let unwantedSet = whitespaceAndNewlineCharacterSet.mutableCopy() as! NSMutableCharacterSet
        unwantedSet.addCharactersInString("{")
        return stringByTrimmingCharactersInSet(unwantedSet)
    }
}

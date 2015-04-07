//
//  String+SourceKitten.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-05.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import Foundation

private let whitespaceAndNewlineCharacterSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()

extension NSString {
    /**
    Binary search for NSString index equivalent to byte offset.

    :param: offset Byte offset.

    :returns: NSString index, if any.
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
                options: nil,
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

    :param: characterSet Character set to check for membership.
    */
    public func stringByTrimmingTrailingCharactersInSet(characterSet: NSCharacterSet) -> String {
        var charBuffer = [unichar](count: length, repeatedValue: 0)
        getCharacters(&charBuffer)
        for newLength in reverse(1...length) {
            if !characterSet.characterIsMember(charBuffer[newLength - 1]) {
                return substringWithRange(NSRange(location: 0, length: newLength))
            }
        }
        return self as String
    }

    /**
    Returns self represented as an absolute path.

    :param: rootDirectory Absolute parent path if not already an absolute path.
    */
    public func absolutePathRepresentation(rootDirectory: String = NSFileManager.defaultManager().currentDirectoryPath) -> String {
        if absolutePath {
            return self as String
        }
        return NSString.pathWithComponents([rootDirectory, self]).stringByStandardizingPath
    }

    /**
    Converts a range of byte offsets in `self` to an `NSRange` suitable for filtering `self` as an
    `NSString`.

    :param: start Starting byte offset.
    :param: length Length of bytes to include in range.

    :returns: An equivalent `NSRange`.
    */
    public func byteRangeToNSRange(# start: Int, length: Int) -> NSRange? {
        return flatMap(indexOfByteOffset(start)) { stringStart in
            return flatMap(self.indexOfByteOffset(start + length)) { stringEnd in
                return NSRange(location: stringStart, length: stringEnd - stringStart)
            }
        }
    }

    /**
    Returns a substring with the provided byte range.

    :param: start Starting byte offset.
    :param: length Length of bytes to include in range.
    */
    public func substringWithByteRange(# start: Int, length: Int) -> String? {
        return flatMap(byteRangeToNSRange(start: start, length: length)) {
            self.substringWithRange($0)
        }
    }

    /**
    Returns a substring starting at the beginning of `start`'s line and ending at the end of `end`'s
    line. Returns `start`'s entire line if `end` is nil.

    :param: start Starting byte offset.
    :param: length Length of bytes to include in range.
    */
    public func substringLinesWithByteRange(# start: Int, length: Int) -> String? {
        return flatMap(byteRangeToNSRange(start: start, length: length)) { range in
            var lineStart = 0
            var lineEnd = 0
            self.getLineStart(&lineStart, end: &lineEnd, contentsEnd: nil, forRange: range)
            return self.substringWithRange(NSRange(location: lineStart, length: lineEnd - lineStart))
        }
    }

    /**
    Returns line numbers containing starting and ending byte offsets.

    :param: start Starting byte offset.
    :param: length Length of bytes to include in range.
    */
    public func lineRangeWithByteRange(# start: Int, length: Int) -> (start: Int, end: Int)? {
        return flatMap(byteRangeToNSRange(start: start, length: length)) { range in
            var numberOfLines = 0
            var index = 0
            var lineRangeStart = 0
            while index < self.length {
                numberOfLines++
                if index <= range.location {
                    lineRangeStart = numberOfLines
                }
                index = NSMaxRange(self.lineRangeForRange(NSRange(location: index, length: 1)))
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
    Returns true if self is an Objective-C header file.
    */
    public func isObjectiveCHeaderFile() -> Bool {
        return contains(["h", "hpp", "hh"], pathExtension)
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

    :param: token Token to process.
    */
    public func isTokenDocumentable(token: SyntaxToken) -> Bool {
        if token.type == SyntaxKind.Keyword.rawValue {
            let keywordFunctions = ["subscript", "init", "deinit"]
            return flatMap((self as NSString).substringWithByteRange(start: token.offset, length: token.length)) {
                contains(keywordFunctions, $0)
            } ?? false
        }
        return token.type == SyntaxKind.Identifier.rawValue
    }

    /**
    Find integer offsets of documented Swift tokens in self.

    :param: syntaxMap Syntax Map returned from SourceKit editor.open request.

    :returns: Array of documented token offsets.
    */
    public func documentedTokenOffsets(syntaxMap: SyntaxMap) -> [Int] {
        let documentableOffsets = syntaxMap.tokens.filter({
            self.isTokenDocumentable($0)
        }).map {
            $0.offset
        }

        let regex = NSRegularExpression(pattern: "(///.*\\n|\\*/\\n)", options: nil, error: nil)! // Safe to force unwrap
        let range = NSRange(location: 0, length: utf16Count)
        let matches = regex.matchesInString(self, options: nil, range: range) as [NSTextCheckingResult]

        return compact(matches.map({ match in
            documentableOffsets.filter({ $0 >= match.range.location }).first
        }))
    }

    /**
    Returns the body of the comment if the string is a comment.
    
    :param: range Range to restrict the search for a comment body.
    */
    public func commentBody(var range: NSRange? = nil) -> String? {
        let nsString = self as NSString
        let patterns: [(pattern: String, options: NSRegularExpressionOptions)] = [
            ("^\\s*\\/\\*\\*\\s*(.+)\\*\\/", .AnchorsMatchLines | .DotMatchesLineSeparators),   // multi: ^\s*\/\*\*\s*(.+)\*\/
            ("^\\s*\\/\\/\\/(.+)?",          .AnchorsMatchLines)                                // single: ^\s*\/\/\/(.+)?
        ]
        if range == nil {
            range = NSRange(location: 0, length: nsString.length)
        }
        for pattern in patterns {
            let regex = NSRegularExpression(pattern: pattern.pattern, options: pattern.options, error: nil)! // Safe to force unwrap
            let matches = regex.matchesInString(self, options: nil, range: range!) as [NSTextCheckingResult]
            let bodyParts: [String] = map(matches) { match in
                let numberOfRanges = match.numberOfRanges
                if numberOfRanges < 1 {
                    return []
                }
                return map(1..<numberOfRanges) { rangeIndex in
                    let range = match.rangeAtIndex(rangeIndex)
                    if range.location == NSNotFound {
                        // empty capture group, return empty string
                        return ""
                    }
                    var lineStart = 0
                    var lineEnd   = nsString.length
                    let indexRange = self.byteRangeToNSRange(start: range.location, length: 0)!
                    nsString.getLineStart(&lineStart, end: &lineEnd, contentsEnd: nil, forRange: indexRange)
                    let leadingWhitespaceCountToAdd = nsString.substringWithRange(NSRange(location: lineStart, length: lineEnd - lineStart)).countOfLeadingCharactersInSet(whitespaceAndNewlineCharacterSet)
                    let leadingWhitespaceToAdd = String(count: leadingWhitespaceCountToAdd, repeatedValue: Character(" "))

                    let bodySubstring = nsString.substringWithRange(range)
                    return leadingWhitespaceToAdd + bodySubstring
                }
            }.reduce([], +)
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
            if lineLeadingWhitespace < minLeadingWhitespace && lineLeadingWhitespace != countElements(line) {
                minLeadingWhitespace = lineLeadingWhitespace
            }
        }
        var lines = [String]()
        enumerateLines { line, _ in
            if countElements(line) >= minLeadingWhitespace {
                lines.append(line[advance(line.startIndex, minLeadingWhitespace)..<line.endIndex])
            } else {
                lines.append(line)
            }
        }
        return "\n".join(lines)
    }

    /**
    Returns the number of contiguous characters at the start of `self` belonging to `characterSet`.
    
    :param: characterSet Character set to check for membership.
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
        let unwantedSet = whitespaceAndNewlineCharacterSet.mutableCopy() as NSMutableCharacterSet
        unwantedSet.addCharactersInString("{")
        return stringByTrimmingCharactersInSet(unwantedSet)
    }
}

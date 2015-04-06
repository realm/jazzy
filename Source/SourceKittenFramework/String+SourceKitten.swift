//
//  String+SourceKitten.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-05.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import Foundation

private let whitespaceAndNewlineCharacterSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()

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
    Returns self represented as an absolute path.

    :param: rootDirectory Absolute parent path if not already an absolute path.
    */
    public func absolutePathRepresentation(rootDirectory: String = NSFileManager.defaultManager().currentDirectoryPath) -> String {
        if (self as NSString).absolutePath {
            return self
        }
        return NSString.pathWithComponents([rootDirectory, self]).stringByStandardizingPath
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
            return flatMap(substringWithByteRange(start: token.offset, length: token.length)) {
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
            let bodyParts: [String] = matches.map { match in
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
                    var lineStart = self.startIndex
                    var lineEnd   = self.endIndex
                    let indexRange = self.byteRangeToStringRange(start: range.location, length: 0)!
                    self.getLineStart(&lineStart, end: &lineEnd, contentsEnd: nil, forRange: indexRange)
                    let leadingWhitespaceCountToAdd = self[lineStart..<lineEnd].countOfLeadingCharactersInSet(whitespaceAndNewlineCharacterSet)
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

    /**
    Returns a copy of `self` with the trailing contiguous characters belonging to `characterSet`
    removed.
    
    :param: characterSet Character set to check for membership.
    */
    public func stringByTrimmingTrailingCharactersInSet(characterSet: NSCharacterSet) -> String {
        let nsString = self as NSString
        var charBuffer = [unichar](count: utf16Count, repeatedValue: unichar())
        nsString.getCharacters(&charBuffer)
        for length in reverse(1...utf16Count) {
            if !characterSet.characterIsMember(charBuffer[length - 1]) {
                return nsString.substringWithRange(NSRange(location: 0, length: length))
            }
        }
        return self
    }

    /**
    Converts a range of byte offsets in `self` to an `NSRange` suitable for filtering `self` as an
    `NSString`.
    
    :param: start Starting byte offset.
    :param: length Length of bytes to include in range.
    
    :returns: An equivalent `NSRange`.
    */
    public func byteRangeToNSRange(# start: Int, length: Int) -> NSRange? {
        let nsString = self as NSString
        var startStringIndex: Int? = nil
        var endStringIndex: Int? = nil
        for stringIndex in 0..<nsString.length {
            let bytesSoFar = nsString.substringToIndex(stringIndex).lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
            if startStringIndex == nil && bytesSoFar >= start {
                startStringIndex = stringIndex
            }
            if endStringIndex == nil && bytesSoFar >= start + length {
                endStringIndex = stringIndex
                break
            }
        }
        return flatMap(startStringIndex) { startStringIndex in
            return flatMap(endStringIndex) { endStringIndex in
                return NSRange(location: startStringIndex, length: endStringIndex - startStringIndex)
            }
        }
    }

    /**
    Converts a range of byte offsets to a `Range<String.Index>`.

    :param: start  Starting byte offset.
    :param: length Length of bytes to include in range.

    :returns: Converted `Range<String.Index>` if successful.
    */
    public func byteRangeToStringRange(# start: Int, length: Int) -> Range<Index>? {
        var bytesSoFar = 0
        var startStringIndex: Index? = nil
        var endStringIndex: Index? = nil
        for stringIndex in startIndex..<endIndex {
            if startStringIndex == nil && bytesSoFar >= start {
                startStringIndex = stringIndex
            }
            if endStringIndex == nil && bytesSoFar >= start + length {
                endStringIndex = stringIndex
                break
            }
            bytesSoFar += countElements(String(self[stringIndex]).utf8)
        }
        return flatMap(startStringIndex) { startStringIndex in
            return flatMap(endStringIndex) { endStringIndex in
                return startStringIndex..<endStringIndex
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
            (self as NSString).substringWithRange($0)
        }
    }

    /**
    Returns a substring starting at the beginning of `start`'s line and ending at the end of `end`'s
    line. Returns `start`'s entire line if `end` is nil.

    :param: start Starting byte offset.
    :param: length Length of bytes to include in range.
    */
    public func substringLinesWithByteRange(# start: Int, length: Int) -> String? {
        return flatMap(byteRangeToStringRange(start: start, length: length)) { stringRange in
            var lineStart = self.startIndex
            var lineEnd = self.endIndex
            self.getLineStart(&lineStart, end: &lineEnd, contentsEnd: nil, forRange: stringRange)
            return self[lineStart..<lineEnd]
        }
    }

    /**
    Returns line numbers containing starting and ending byte offsets.

    :param: start Starting byte offset.
    :param: length Length of bytes to include in range.
    */
    public func lineRangeWithByteRange(# start: Int, length: Int) -> (start: Int, end: Int)? {
        return flatMap(byteRangeToStringRange(start: start, length: length)) { range in
            var numberOfLines = 0
            var index = self.startIndex
            var lineRangeStart = 0
            while index < self.endIndex {
                numberOfLines++
                if index <= range.startIndex {
                    lineRangeStart = numberOfLines
                }
                index = self.lineRangeForRange(index...index).endIndex
                if index > range.endIndex {
                    return (lineRangeStart, numberOfLines)
                }
            }
            return nil
        }
    }

    /**
    Returns a copy of the string by trimming whitespace and the opening curly brace (`{`).
    */
    internal func stringByTrimmingWhitespaceAndOpeningCurlyBrace() -> String? {
        let unwantedSet = whitespaceAndNewlineCharacterSet.mutableCopy() as NSMutableCharacterSet
        unwantedSet.addCharactersInString("{")
        return stringByTrimmingCharactersInSet(unwantedSet)
    }
}

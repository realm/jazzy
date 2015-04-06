//
//  String+SourceKitten.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-05.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import Foundation

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
            return flatMap(substringWithByteRange(token.offset, end: token.offset + token.length)) {
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
    Returns a substring with the provided byte range.

    :param: start Starting byte offset.
    :param: end   Ending byte offset.
    */
    internal func substringWithByteRange(start: Int, end: Int) -> String? {
        let bytes = utf8
        var buffer = [UInt8]()
        var byteIndex = advance(bytes.startIndex, start)
        for _ in start..<end {
            buffer.append(bytes[byteIndex])
            byteIndex = byteIndex.successor()
        }
        return NSString(bytes: buffer, length: buffer.count, encoding: NSUTF8StringEncoding)
    }

    /**
    Converts a range of byte offsets to a `Range<String.Index>`.
    
    :param: start Starting byte offset.
    :param: end   Ending byte offset.
    
    :returns: Converted `Range<String.Index>` if successful.
    */
    private func byteRangeToStringRange(start: Int, end: Int) -> Range<Index>? {
        var bytesSoFar = 0
        var startStringIndex: Index? = nil
        var endStringIndex: Index? = nil
        for stringIndex in startIndex..<endIndex {
            if startStringIndex == nil && bytesSoFar >= start {
                startStringIndex = stringIndex
            }
            if endStringIndex == nil && bytesSoFar >= end {
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
    Returns a substring starting at the beginning of `start`'s line and ending at the end of `end`'s
    line. Returns `start`'s entire line if `end` is nil.

    :param: start Starting byte offset.
    :param: end   Ending byte offset.
    */
    internal func substringLinesWithByteRange(start: Int, end: Int? = nil) -> String? {
        return flatMap(byteRangeToStringRange(start, end: end ?? start)) { stringRange in
            var lineStart = self.startIndex
            var lineEnd = self.endIndex
            self.getLineStart(&lineStart, end: &lineEnd, contentsEnd: nil, forRange: stringRange)
            return self[lineStart..<lineEnd]
        }
    }

    /**
    Returns line numbers containing starting and ending byte offsets.

    :param: start Starting byte offset.
    :param: end   Ending byte offset.
    */
    internal func lineRangeWithByteRange(start: Int, end: Int? = nil) -> (start: Int, end: Int)? {
        return flatMap(byteRangeToStringRange(start, end: end ?? start)) { range in
            var numberOfLines = 0
            var index = self.startIndex
            var lineRangeStart = 0
            while index < self.endIndex {
                numberOfLines++
                index = self.lineRangeForRange(index...index).endIndex
                if index < range.startIndex {
                    lineRangeStart = numberOfLines + 1
                }
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
        let unwantedSet = NSCharacterSet.whitespaceAndNewlineCharacterSet().mutableCopy() as NSMutableCharacterSet
        unwantedSet.addCharactersInString("{")
        return stringByTrimmingCharactersInSet(unwantedSet)
    }
}

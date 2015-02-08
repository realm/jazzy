//
//  NSString+SourceKitten.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-05.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import Foundation

extension NSString {
    /**
    Returns true if self is an Objective-C header file.

    :returns: True if self is an Objective-C header file.
    */
    public func isObjectiveCHeaderFile() -> Bool {
        return contains(["h", "hpp", "hh"], pathExtension)
    }

    /**
    Returns true if self is a Swift file.

    :returns: True if self is a Swift file.
    */
    public func isSwiftFile() -> Bool {
        return pathExtension == "swift"
    }

    /**
    Returns self represented as an absolute path.

    :returns: self represented as an absolute path.
    */
    public func absolutePathRepresentation() -> String {
        if absolutePath {
            return self
        }
        return NSString.pathWithComponents([NSFileManager.defaultManager().currentDirectoryPath, self]).stringByStandardizingPath
    }

    /**
    Returns offsets of all the line breaks in the current string.

    :returns: Line breaks.
    */
    public func lineBreaks() -> [Int] {
        var lineBreaks = [Int]()
        var searchRange = NSRange(location: 0, length: length)
	while searchRange.length > 0 {
            searchRange.length = length - searchRange.location
            let foundRange = rangeOfString("\n", options: nil, range: searchRange)
            if foundRange.location != NSNotFound {
                lineBreaks.append(foundRange.location)
                searchRange.location = foundRange.location + foundRange.length
            } else {
                break
            }
        }
        return lineBreaks
    }

    /**
    Filter self from start to end while trimming unwanted characters (whitespace & '{').

    :param: start Starting offset to filter.
    :param: end Ending offset to filter.

    :returns: Filtered string.
    */
    public func filteredSubstring(start: Int, end: Int) -> String {
        let range = NSRange(location: start, length: end - start - 1)
        let unwantedSet = NSCharacterSet.whitespaceAndNewlineCharacterSet().mutableCopy() as NSMutableCharacterSet
        unwantedSet.addCharactersInString("{")
        return substringWithRange(range).stringByTrimmingCharactersInSet(unwantedSet)
    }

    /**
    Find integer offsets of documented Swift tokens in self.

    :param: syntaxMap Syntax Map returned from SourceKit editor.open request.

    :returns: Array of documented token offsets.
    */
    public func documentedTokenOffsets(syntaxMap: SyntaxMap) -> [Int] {
        let identifierOffsets = syntaxMap.tokens.filter({
            $0.type == SyntaxKind.Identifier.rawValue
        }).map {
            $0.offset
        }

        let regex = NSRegularExpression(pattern: "(///.*\\n|\\*/\\n)", options: nil, error: nil)! // Safe to force unwrap
        let range = NSRange(location: 0, length: length)
        let matches = regex.matchesInString(self, options: nil, range: range) as [NSTextCheckingResult]

        return compact(matches.map({ match in
            identifierOffsets.filter({ $0 >= match.range.location }).first
        }))
    }
}

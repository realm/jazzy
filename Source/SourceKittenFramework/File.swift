//
//  File.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-03.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import Foundation
import SwiftXPC

/// Represents a source file.
public struct File {
    /// File path. Nil if initialized directly with File(contents:).
    public let path: String?
    /// File contents.
    public let contents: NSString
    /// Array of newline offsets in contents.
    public let lineBreaks: [Int]

    /**
    Failable initializer by path. Fails if file contents could not be read as a UTF8 string.

    :param: path File path.
    */
    public init?(path: String) {
        self.path = path
        if let contents = NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil) {
            self.contents = contents
            lineBreaks = contents.lineBreaks()
        } else {
            return nil
        }
    }

    /**
    Initializer by file contents. File path is nil.

    :param: contents File contents.
    */
    public init(contents: NSString) {
        self.contents = contents
        lineBreaks = contents.lineBreaks()
    }

	/**
	Parse source declaration string from XPC dictionary.

	:param: dictionary XPC dictionary to extract declaration from.

	:returns: Source declaration if successfully parsed.
	*/
    public func parseDeclaration(dictionary: XPCDictionary) -> String? {
        if !shouldParseDeclaration(dictionary) {
            return nil
        }
        let offset = Int(SwiftDocKey.getOffset(dictionary)!)
        let lineBreakIndexBeforeOffset = indexBefore(offset, inSequence: lineBreaks) ?? 0
        let previousLineBreakOffset = lineBreaks[lineBreakIndexBeforeOffset] + 1
        if let bodyOffset = SwiftDocKey.getBodyOffset(dictionary) {
            return contents.filteredSubstring(previousLineBreakOffset, end: Int(bodyOffset))
        }
        let nextLineBreakOffset = (lineBreakIndexBeforeOffset + 1 < lineBreaks.count) ? lineBreaks[lineBreakIndexBeforeOffset + 1] : lineBreaks.last!
        return contents.filteredSubstring(previousLineBreakOffset, end: nextLineBreakOffset + 1)
    }

    /**
    Extract mark-style comment string from doc dictionary. e.g. '// MARK: - The Name'

    :param: dictionary Doc dictionary to parse.

    :returns: Mark name if successfully parsed.
    */
    public func markNameFromDictionary(dictionary: XPCDictionary) -> String? {
        precondition(SwiftDocKey.getKind(dictionary)! == SyntaxKind.CommentMark.rawValue)
        let offset = Int(SwiftDocKey.getOffset(dictionary)!)
        let length = Int(SwiftDocKey.getLength(dictionary)!)
        if let fileContentsData = contents.dataUsingEncoding(NSUTF8StringEncoding) {
            let subdata = fileContentsData.subdataWithRange(NSRange(location: offset, length: length))
            if let substring = NSString(data: subdata, encoding: NSUTF8StringEncoding) as String? {
                return substring
            }
        }
        return nil
    }

    /**
    <#Description#>

    :param: dictionary        <#dictionary description#>
    :param: cursorInfoRequest Cursor.Info request to get declaration information.

    :returns: <#return value description#>
    */
    public func processDictionary(var dictionary: XPCDictionary, cursorInfoRequest: xpc_object_t? = nil) -> XPCDictionary {
        if let cursorInfoRequest = cursorInfoRequest {
            dictionary = merge(
                dictionary,
                dictWithCommentMarkNamesCursorInfo(dictionary, cursorInfoRequest: cursorInfoRequest)
            )
        }

        // Parse declaration and add to dictionary.
        if let parsedDeclaration = parseDeclaration(dictionary) {
            dictionary[SwiftDocKey.ParsedDeclaration.rawValue] = parsedDeclaration
        }

        // Update substructure
        if let substructure = newSubstructure(dictionary, cursorInfoRequest: cursorInfoRequest) {
            dictionary[SwiftDocKey.Substructure.rawValue] = substructure
        }
        return dictionary
    }

    /**
    <#Description#>

    :param: dictionary             <#dictionary description#>
    :param: documentedTokenOffsets <#documentedTokenOffsets description#>
    :param: cursorInfoRequest      Cursor.Info request to get declaration information.

    :returns: <#return value description#>
    */
    public func furtherProcessDictionary(var dictionary: XPCDictionary, documentedTokenOffsets: [Int], cursorInfoRequest: xpc_object_t) -> XPCDictionary {
        let offsetMap = generateOffsetMap(documentedTokenOffsets, dictionary: dictionary)
        for offset in offsetMap.keys.array.reverse() { // Do this in reverse to insert the doc at the correct offset
            let response = processDictionary(Request.sendCursorInfoRequest(cursorInfoRequest, atOffset: Int64(offset))!)
            if isSwiftDeclarationKind(SwiftDocKey.getKind(response)) {
                if let inserted = insertDoc(response, parent: dictionary, offset: Int64(offsetMap[offset]!)) { // Safe to force unwrap
                    dictionary = inserted
                }
            }
        }
        return dictionary
    }

    /**
    Update input dictionary's substructure by running `processDictionary(_:cursorInfoRequest:)` on
    its elements, only keeping comment marks and declarations.

    :param: dictionary        Input dictionary to process its substructure.
    :param: cursorInfoRequest Cursor.Info request to get declaration information.

    :returns: A copy of the input dictionary's substructure processed by running
              `processDictionary(_:cursorInfoRequest:)` on its elements, only keeping comment marks
              and declarations.
    */
    public func newSubstructure(dictionary: XPCDictionary, cursorInfoRequest: xpc_object_t?) -> XPCArray? {
        return SwiftDocKey.getSubstructure(dictionary)?
        .filter({
            return isDeclarationOrCommentMark($0 as XPCDictionary)
        }).map {
            return self.processDictionary($0 as XPCDictionary, cursorInfoRequest: cursorInfoRequest)
        }
    }

    /**
    Returns an updated copy of the input dictionary with comment mark names and cursor.info information.

    :param: dictionary        Dictionary to update.
    :param: cursorInfoRequest Cursor.Info request to get declaration information.

    :returns: An updated copy of the input dictionary with comment mark names and cursor.info information.
    */
    public func dictWithCommentMarkNamesCursorInfo(dictionary: XPCDictionary, cursorInfoRequest: xpc_object_t) -> XPCDictionary? {
        if let kind = SwiftDocKey.getKind(dictionary) {
            // Only update dictionaries with a 'kind' key
            if kind == SyntaxKind.CommentMark.rawValue {
                // Update comment marks
                if let markName = markNameFromDictionary(dictionary) {
                    return [SwiftDocKey.Name.rawValue: markName]
                }
            } else if kind != SwiftDeclarationKind.Parameter.rawValue && isSwiftDeclarationKind(kind) {
                // Update if kind is a declaration (but not a parameter)
                var updateDict = Request.sendCursorInfoRequest(cursorInfoRequest,
                    atOffset: SwiftDocKey.getNameOffset(dictionary)!) ?? XPCDictionary()

                // Skip kinds, since values from editor.open are more accurate than cursorinfo
                updateDict.removeValueForKey(SwiftDocKey.Kind.rawValue)
                return updateDict
            }
        }
        return nil
    }

    /**
    Returns whether or not a doc should be inserted into a parent at the provided offset.

    :param: parent Parent dictionary to evaluate.
    :param: offset Offset to search for in parent dictionary.

    :returns: True if a doc should be inserted in the parent at the provided offset.
    */
    public func shouldInsert(parent: XPCDictionary, offset: Int64) -> Bool {
        if offset == 0 {
            return true
        }
        if shouldTreatAsSameFile(parent) {
            if let rangeStart = SwiftDocKey.getOffset(parent) {
                if rangeStart == offset {
                    return true
                }
            }
        }
        return false
    }

    /**
    Inserts a document dictionary at the specified offset.
    Parent will be traversed until the offset is found.
    Returns nil if offset could not be found.

    :param: doc    Document dictionary to insert.
    :param: parent Parent to traverse to find insertion point.
    :param: offset Offset to insert document dictionary.

    :returns: Parent with doc inserted if successful.
    */
    public func insertDoc(doc: XPCDictionary, var parent: XPCDictionary, offset: Int64) -> XPCDictionary? {
        if shouldInsert(parent, offset: offset) {
            var substructure = SwiftDocKey.getSubstructure(parent)!
            var insertIndex = substructure.count
            for (index, structure) in enumerate(substructure.reverse()) {
                if SwiftDocKey.getOffset(structure as XPCDictionary)! < offset {
                    break
                }
                insertIndex = substructure.count - index
            }
            substructure.insert(doc, atIndex: insertIndex)
            parent[SwiftDocKey.Substructure.rawValue] = substructure
            return parent
        }
        for key in parent.keys {
            if var subArray = parent[key] as? XPCArray {
                for i in 0..<subArray.count {
                    if let subDict = insertDoc(doc, parent: subArray[i] as XPCDictionary, offset: offset) {
                        subArray[i] = subDict
                        parent[key] = subArray
                        return parent
                    }
                }
            }
        }
        return nil
    }

    /**
    Returns true if path is nil or if path is equal to `key.filepath` in the input dictionary.

    :param: dictionary Dictionary to parse.

    :returns: True if path is nil or if path is equal to `key.filepath` in the input dictionary.
    */
    public func shouldTreatAsSameFile(dictionary: XPCDictionary) -> Bool {
        if let path = path {
            if let dictFilePath = SwiftDocKey.getFilePath(dictionary) {
                return dictFilePath == path
            }
        }
        return true
    }
}

/**
Returns true if the input dictionary contains a parseable declaration.

:param: dictionary Dictionary to parse.

:returns: True if the input dictionary contains a parseable declaration.
*/
public func shouldParseDeclaration(dictionary: XPCDictionary) -> Bool {
    let hasTypeName = SwiftDocKey.getTypeName(dictionary) != nil
    let hasAnnotatedDeclaration = SwiftDocKey.getAnnotatedDeclaration(dictionary) != nil
    let hasOffset = SwiftDocKey.getOffset(dictionary) != nil
    let isntExtension = SwiftDocKey.getKind(dictionary) != SwiftDeclarationKind.Extension.rawValue
    return hasTypeName && hasAnnotatedDeclaration && hasOffset && isntExtension
}

/**
Traverse the dictionary replacing SourceKit UIDs with their string value.

:param: dictionary Dictionary to replace UIDs.

:returns: Dictionary with UIDs replaced by strings.
*/
public func replaceUIDsWithSourceKitStrings(var dictionary: XPCDictionary) -> XPCDictionary {
    for key in dictionary.keys {
        if let uid = dictionary[key] as? UInt64 {
            if let uidString = stringForSourceKitUID(uid) {
                dictionary[key] = uidString
            }
        } else if var array = dictionary[key] as? XPCArray {
            for (index, dict) in enumerate(array) {
                array[index] = replaceUIDsWithSourceKitStrings(dict as XPCDictionary)
            }
            dictionary[key] = array
        } else if let dict = dictionary[key] as? XPCDictionary {
            dictionary[key] = replaceUIDsWithSourceKitStrings(dict)
        }
    }
    return dictionary
}

/**
Returns true if the dictionary represents a source declaration or a mark-style comment.

:param: dictionary Dictionary to parse.

:returns: True if the dictionary represents a source declaration or a mark-style comment.
*/
func isDeclarationOrCommentMark(dictionary: XPCDictionary) -> Bool {
    if let kind = SwiftDocKey.getKind(dictionary) {
        return kind != SwiftDeclarationKind.Parameter.rawValue &&
            (kind == SyntaxKind.CommentMark.rawValue || isSwiftDeclarationKind(kind))
    }
    return false
}

//
//  File.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-03.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import Foundation
import SwiftXPC

public struct File {
    public let path: String?
    public let contents: NSString
    public let lineBreaks: [Int]

    public init?(path: String) {
        self.path = path
        if let contents = NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil) {
            self.contents = contents
            lineBreaks = contents.lineBreaks()
        } else {
            return nil
        }
    }

    public init(contents: NSString) {
        self.contents = contents
        lineBreaks = contents.lineBreaks()
    }

	/**
	Parse declaration from XPC dictionary.

	:param: dictionary XPC dictionary to extract declaration from.

	:returns: String declaration if successfully parsed.
	*/
    public func parseDeclaration(dictionary: XPCDictionary) -> String? {
        if !shouldParseDeclaration(dictionary) {
            return nil
        }
        let offset = Int(SwiftDocKey.getOffset(dictionary)!)
        let lineBreakIndexBeforeOffset = indexBeforeValue(offset, inArray: lineBreaks)
        let previousLineBreakOffset = lineBreaks[lineBreakIndexBeforeOffset] + 1
        if let bodyOffset = SwiftDocKey.getBodyOffset(dictionary) {
            return contents.filteredSubstring(previousLineBreakOffset, end: Int(bodyOffset))
        }
        let nextLineBreakOffset = (lineBreakIndexBeforeOffset + 1 < lineBreaks.count) ? lineBreaks[lineBreakIndexBeforeOffset + 1] : lineBreaks.last!
        return contents.filteredSubstring(previousLineBreakOffset, end: nextLineBreakOffset + 1)
    }

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
    Process a SourceKit editor.open response dictionary by removing undocumented tokens with no
    documented children. Add cursor.info information for declarations. Add name to mark comments.

    :param: dictionary        `XPCDictionary` to mutate.
    :param: cursorInfoRequest SourceKit xpc dictionary to use to send cursorinfo request.

    :returns: Whether or not the dictionary should be kept.
    */
    public func processDictionary(var dictionary: XPCDictionary, cursorInfoRequest: xpc_object_t? = nil) -> XPCDictionary {
        // Update substructure
        if let substructure = newSubstructure(dictionary, cursorInfoRequest: cursorInfoRequest) {
            dictionary[SwiftDocKey.Substructure.rawValue] = substructure
        }

        if let cursorInfoRequest = cursorInfoRequest {
            if let updateDict = updateDict(dictionary, cursorInfoRequest: cursorInfoRequest) {
                dictionary = merge(dictionary, updateDict)
            }
        }

        if let parsedDeclaration = parseDeclaration(dictionary) {
            dictionary[SwiftDocKey.ParsedDeclaration.rawValue] = parsedDeclaration
        }
        return dictionary
    }

    public func furtherProcessDictionary(var dictionary: XPCDictionary, documentedTokenOffsets: [Int], cursorInfoRequest: xpc_object_t) -> XPCDictionary {
        let offsetMap = generateOffsetMap(documentedTokenOffsets, dictionary: dictionary)
        for offset in offsetMap.keys.array.reverse() { // Do this in reverse to insert the doc at the correct offset
            let response = processDictionary(Request.sendCursorInfoRequest(cursorInfoRequest, atOffset: Int64(offset))!)
            if isSwiftDeclarationKind(SwiftDocKey.getKind(response)) {
                if let inserted = insertDoc(response, parent: dictionary, offset: Int64(offsetMap[offset]!)) {
                    dictionary = inserted
                }
            }
        }
        return dictionary
    }

    public func newSubstructure(dictionary: XPCDictionary, cursorInfoRequest: xpc_object_t?) -> XPCArray? {
        if let substructure = SwiftDocKey.getSubstructure(dictionary) {
            var newSubstructure = XPCArray()
            for subItem in substructure {
                let subDict = subItem as XPCDictionary
                if let kind = SwiftDocKey.getKind(subDict) {
                    if kind != SwiftDeclarationKind.Parameter.rawValue &&
                        (kind == SyntaxKind.CommentMark.rawValue || isSwiftDeclarationKind(kind)) {
                        newSubstructure.append(processDictionary(subDict, cursorInfoRequest: cursorInfoRequest))
                    }
                }
            }
            return newSubstructure
        }
        return nil
    }

    /**
    :param: dictionary        `XPCDictionary` to mutate.
    :param: file              File to parse the declaration out of.
    :param: cursorInfoRequest SourceKit xpc dictionary to use to send cursorinfo request.
    */
    public func updateDict(dictionary: XPCDictionary, cursorInfoRequest: xpc_object_t) -> XPCDictionary? {
        // Remove dictionaries without a 'kind' key
        let kind = SwiftDocKey.getKind(dictionary)
        if kind == nil {
            return nil
        }
        if kind != SwiftDeclarationKind.Parameter.rawValue && isSwiftDeclarationKind(kind) {
            var updateDict = XPCDictionary()
            let update = Request.sendCursorInfoRequest(cursorInfoRequest,
                atOffset: SwiftDocKey.getNameOffset(dictionary)!)
            if let update = update {
                for (key, value) in update {
                    if key == SwiftDocKey.Kind.rawValue {
                        // Skip kinds, since values from editor.open are more
                        // accurate than cursorinfo
                        continue
                    }
                    updateDict[key] = value
                }
            }
            if let parsedDeclaration = parseDeclaration(dictionary) {
                updateDict[SwiftDocKey.ParsedDeclaration.rawValue] = parsedDeclaration
            }
            return updateDict
        } else if kind == SyntaxKind.CommentMark.rawValue {
            if let markName = markNameFromDictionary(dictionary) {
                return [SwiftDocKey.Name.rawValue: markName]
            }
        }
        return nil
    }

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

    /// Insert doc without performing any validation
    public func insertDocDirectly(doc: XPCDictionary, parent: XPCDictionary, offset: Int64) -> XPCArray {
        var substructure = SwiftDocKey.getSubstructure(parent)!
        var insertIndex = substructure.count
        for (index, structure) in enumerate(substructure.reverse()) {
            if SwiftDocKey.getOffset(structure as XPCDictionary)! < offset {
                break
            }
            insertIndex = substructure.count - index
        }
        substructure.insert(doc, atIndex: insertIndex)
        return substructure
    }

    public func recursivelyInsertDoc(doc: XPCDictionary, var parent: XPCDictionary, offset: Int64) -> XPCDictionary? {
        for key in parent.keys {
            if var subArray = parent[key] as? XPCArray {
                for i in 0..<subArray.count {
                    var subDict = subArray[i] as XPCDictionary
                    if let subDict = insertDoc(doc, parent: subDict, offset: offset) {
                        subArray[i] = subDict
                        parent[key] = subArray
                        return parent
                    }
                }
            }
        }
        return nil
    }

    public func insertDoc(doc: XPCDictionary, var parent: XPCDictionary, offset: Int64) -> XPCDictionary? {
        if shouldInsert(parent, offset: offset) {
            parent[SwiftDocKey.Substructure.rawValue] = insertDocDirectly(doc, parent: parent, offset: offset)
            return parent
        }
        return recursivelyInsertDoc(doc, parent: parent, offset: offset)
    }

    public func shouldTreatAsSameFile(dictionary: XPCDictionary) -> Bool {
        if let path = path {
            if let dictFilePath = SwiftDocKey.getFilePath(dictionary) {
                return dictFilePath == path
            }
        }
        return true
    }
}

public func shouldParseDeclaration(dictionary: XPCDictionary) -> Bool {
    let hasTypeName = SwiftDocKey.getTypeName(dictionary) != nil
    let hasAnnotatedDeclaration = SwiftDocKey.getAnnotatedDeclaration(dictionary) != nil
    let hasOffset = SwiftDocKey.getOffset(dictionary) != nil
    let isntExtension = SwiftDocKey.getKind(dictionary) != SwiftDeclarationKind.Extension.rawValue
    return hasTypeName && hasAnnotatedDeclaration && hasOffset && isntExtension
}

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

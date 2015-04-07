//
//  File.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-03.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import Foundation
import SwiftXPC
import SWXMLHash

/// Represents a source file.
public struct File {
    /// File path. Nil if initialized directly with `File(contents:)`.
    public let path: String?
    /// File contents.
    public let contents: String

    /**
    Failable initializer by path. Fails if file contents could not be read as a UTF8 string.

    :param: path File path.
    */
    public init?(path: String) {
        self.path = path
        if let contents = NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil) as? String {
            self.contents = contents
        } else {
            fputs("Could not read contents of `\(path)`\n", stderr)
            return nil
        }
    }

    /**
    Initializer by file contents. File path is nil.

    :param: contents File contents.
    */
    public init(contents: String) {
        path = nil
        self.contents = contents
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
        return flatMap(SwiftDocKey.getOffset(dictionary)) { start in
            let end = flatMap(SwiftDocKey.getBodyOffset(dictionary)) { Int($0) }
            let start = Int(start)
            let length = (end ?? start) - start
            return contents.substringLinesWithByteRange(start: start, length: length)?
                .stringByTrimmingWhitespaceAndOpeningCurlyBrace()
        }
    }

    /**
    Parse line numbers containing the declaration's implementation from XPC dictionary.
    
    :param: dictionary XPC dictionary to extract declaration from.
    
    :returns: Line numbers containing the declaration's implementation.
    */
    public func parseScopeRange(dictionary: XPCDictionary) -> (start: Int, end: Int)? {
        if !shouldParseDeclaration(dictionary) {
            return nil
        }
        return flatMap(SwiftDocKey.getOffset(dictionary)) { start in
            let start = Int(start)
            let end = flatMap(SwiftDocKey.getBodyOffset(dictionary)) { bodyOffset in
                return flatMap(SwiftDocKey.getBodyLength(dictionary)) { bodyLength in
                    return Int(bodyOffset + bodyLength)
                }
            } ?? start
            let length = end - start
            return contents.lineRangeWithByteRange(start: start, length: length)
        }
    }

    /**
    Extract mark-style comment string from doc dictionary. e.g. '// MARK: - The Name'

    :param: dictionary Doc dictionary to parse.

    :returns: Mark name if successfully parsed.
    */
    private func markNameFromDictionary(dictionary: XPCDictionary) -> String? {
        precondition(SwiftDocKey.getKind(dictionary)! == SyntaxKind.CommentMark.rawValue)
        let offset = Int(SwiftDocKey.getOffset(dictionary)!)
        let length = Int(SwiftDocKey.getLength(dictionary)!)
        if let fileContentsData = contents.dataUsingEncoding(NSUTF8StringEncoding),
            subdata = Optional(fileContentsData.subdataWithRange(NSRange(location: offset, length: length))),
            substring = NSString(data: subdata, encoding: NSUTF8StringEncoding) as String? {
            return substring
        }
        return nil
    }

    /**
    Returns a copy of the input dictionary with comment mark names, cursor.info information and
    parsed declarations for the top-level of the input dictionary and its substructures.

    :param: dictionary        Dictionary to process.
    :param: cursorInfoRequest Cursor.Info request to get declaration information.
    */
    public func processDictionary(var dictionary: XPCDictionary, cursorInfoRequest: xpc_object_t? = nil, syntaxMap: SyntaxMap? = nil) -> XPCDictionary {
        if let cursorInfoRequest = cursorInfoRequest {
            dictionary = merge(
                dictionary,
                dictWithCommentMarkNamesCursorInfo(dictionary, cursorInfoRequest: cursorInfoRequest)
            )
        }

        // Parse declaration and add to dictionary
        if let parsedDeclaration = parseDeclaration(dictionary) {
            dictionary[SwiftDocKey.ParsedDeclaration.rawValue] = parsedDeclaration
        }

        // Parse scope range and add to dictionary
        if let parsedScopeRange = parseScopeRange(dictionary) {
            dictionary[SwiftDocKey.ParsedScopeStart.rawValue] = Int64(parsedScopeRange.start)
            dictionary[SwiftDocKey.ParsedScopeEnd.rawValue] = Int64(parsedScopeRange.end)
        }

        // Parse `key.doc.full_as_xml` and add to dictionary
        if let parsedXMLDocs = flatMap(SwiftDocKey.getFullXMLDocs(dictionary), { parseFullXMLDocs($0) }) {
            dictionary = merge(dictionary, parsedXMLDocs)

            // Parse documentation comment and add to dictionary
            if let commentBody = flatMap(syntaxMap, { getDocumentationCommentBody(dictionary, syntaxMap: $0) }) {
                dictionary[SwiftDocKey.DocumentationComment.rawValue] = commentBody
            }
        }

        // Update substructure
        if let substructure = newSubstructure(dictionary, cursorInfoRequest: cursorInfoRequest, syntaxMap: syntaxMap) {
            dictionary[SwiftDocKey.Substructure.rawValue] = substructure
        }
        return dictionary
    }

    /**
    Returns a copy of the input dictionary with additional cursorinfo information at the given
    `documentationTokenOffsets` that haven't yet been documented.

    :param: dictionary             Dictionary to insert new docs into.
    :param: documentedTokenOffsets Offsets that are likely documented.
    :param: cursorInfoRequest      Cursor.Info request to get declaration information.
    */
    internal func furtherProcessDictionary(var dictionary: XPCDictionary, documentedTokenOffsets: [Int], cursorInfoRequest: xpc_object_t, syntaxMap: SyntaxMap) -> XPCDictionary {
        let offsetMap = generateOffsetMap(documentedTokenOffsets, dictionary: dictionary)
        for offset in offsetMap.keys.array.reverse() { // Do this in reverse to insert the doc at the correct offset
            let response = processDictionary(Request.sendCursorInfoRequest(cursorInfoRequest, atOffset: Int64(offset))!, cursorInfoRequest: nil, syntaxMap: syntaxMap)
            if let kind = SwiftDocKey.getKind(response),
                _ = SwiftDeclarationKind(rawValue: kind),
                inserted = insertDoc(response, parent: dictionary, offset: Int64(offsetMap[offset]!)) { // Safe to force unwrap
                dictionary = inserted
            }
        }
        return dictionary
    }

    /**
    Update input dictionary's substructure by running `processDictionary(_:cursorInfoRequest:syntaxMap:)` on
    its elements, only keeping comment marks and declarations.

    :param: dictionary        Input dictionary to process its substructure.
    :param: cursorInfoRequest Cursor.Info request to get declaration information.

    :returns: A copy of the input dictionary's substructure processed by running
              `processDictionary(_:cursorInfoRequest:syntaxMap:)` on its elements, only keeping comment marks
              and declarations.
    */
    private func newSubstructure(dictionary: XPCDictionary, cursorInfoRequest: xpc_object_t?, syntaxMap: SyntaxMap?) -> XPCArray? {
        return SwiftDocKey.getSubstructure(dictionary)?
            .filter({
                return isDeclarationOrCommentMark($0 as! XPCDictionary)
            }).map {
                return self.processDictionary($0 as! XPCDictionary, cursorInfoRequest: cursorInfoRequest, syntaxMap: syntaxMap)
        }
    }

    /**
    Returns an updated copy of the input dictionary with comment mark names and cursor.info information.

    :param: dictionary        Dictionary to update.
    :param: cursorInfoRequest Cursor.Info request to get declaration information.
    */
    private func dictWithCommentMarkNamesCursorInfo(dictionary: XPCDictionary, cursorInfoRequest: xpc_object_t) -> XPCDictionary? {
        if let kind = SwiftDocKey.getKind(dictionary) {
            // Only update dictionaries with a 'kind' key
            if kind == SyntaxKind.CommentMark.rawValue {
                // Update comment marks
                if let markName = markNameFromDictionary(dictionary) {
                    return [SwiftDocKey.Name.rawValue: markName]
                }
            } else if let decl = SwiftDeclarationKind(rawValue: kind) where decl != .VarParameter {
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
    private func shouldInsert(parent: XPCDictionary, offset: Int64) -> Bool {
        return (offset == 0) ||
            (shouldTreatAsSameFile(parent) && SwiftDocKey.getOffset(parent) == offset)
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
    private func insertDoc(doc: XPCDictionary, var parent: XPCDictionary, offset: Int64) -> XPCDictionary? {
        if shouldInsert(parent, offset: offset) {
            var substructure = SwiftDocKey.getSubstructure(parent)!
            var insertIndex = substructure.count
            for (index, structure) in enumerate(substructure.reverse()) {
                if SwiftDocKey.getOffset(structure as! XPCDictionary)! < offset {
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
                    if let subDict = insertDoc(doc, parent: subArray[i] as! XPCDictionary, offset: offset) {
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
    */
    internal func shouldTreatAsSameFile(dictionary: XPCDictionary) -> Bool {
        return path == SwiftDocKey.getFilePath(dictionary)
    }

    /**
    Returns true if the input dictionary contains a parseable declaration.

    :param: dictionary Dictionary to parse.
    */
    private func shouldParseDeclaration(dictionary: XPCDictionary) -> Bool {
        let sameFile                = shouldTreatAsSameFile(dictionary)
        let hasTypeName             = SwiftDocKey.getTypeName(dictionary) != nil
        let hasAnnotatedDeclaration = SwiftDocKey.getAnnotatedDeclaration(dictionary) != nil
        let hasOffset               = SwiftDocKey.getOffset(dictionary) != nil
        let isntExtension           = SwiftDocKey.getKind(dictionary) != SwiftDeclarationKind.Extension.rawValue
        return sameFile && hasTypeName && hasAnnotatedDeclaration && hasOffset && isntExtension
    }

    /**
    Parses `dictionary`'s documentation comment body.

    :param: dictionary Dictionary to parse.
    :param: syntaxMap  SyntaxMap for current file.
    
    :returns: `dictionary`'s documentation comment body as a string, without any documentation
              syntax (`/** ... */` or `/// ...`).
    */
    public func getDocumentationCommentBody(dictionary: XPCDictionary, syntaxMap: SyntaxMap) -> String? {
        return flatMap(SwiftDocKey.getOffset(dictionary)) { offset in
            return flatMap(syntaxMap.commentRangeBeforeOffset(Int(offset))) { commentByteRange in
                return flatMap(contents.byteRangeToNSRange(start: commentByteRange.start, length: commentByteRange.length)) { nsRange in
                    return contents.commentBody(range: nsRange)
                }
            }
        }
    }
}

/**
Traverse the dictionary replacing SourceKit UIDs with their string value.

:param: dictionary Dictionary to replace UIDs.

:returns: Dictionary with UIDs replaced by strings.
*/
internal func replaceUIDsWithSourceKitStrings(var dictionary: XPCDictionary) -> XPCDictionary {
    for key in dictionary.keys {
        if let uid = dictionary[key] as? UInt64, uidString = stringForSourceKitUID(uid) {
            dictionary[key] = uidString
        } else if var array = dictionary[key] as? XPCArray {
            for (index, dict) in enumerate(array) {
                array[index] = replaceUIDsWithSourceKitStrings(dict as! XPCDictionary)
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
*/
private func isDeclarationOrCommentMark(dictionary: XPCDictionary) -> Bool {
    if let kind = SwiftDocKey.getKind(dictionary) {
        return kind != SwiftDeclarationKind.VarParameter.rawValue &&
            (kind == SyntaxKind.CommentMark.rawValue || SwiftDeclarationKind(rawValue: kind) != nil)
    }
    return false
}

/**
Parse XML from `key.doc.full_as_xml` from `cursor.info` request.

:param: xmlDocs Contents of `key.doc.full_as_xml` from SourceKit.

:returns: XML parsed as an `XPCDictionary`.
*/
public func parseFullXMLDocs(xmlDocs: String) -> XPCDictionary? {
    let cleanXMLDocs = xmlDocs.stringByReplacingOccurrencesOfString("<rawHTML>",  withString: "")
                              .stringByReplacingOccurrencesOfString("</rawHTML>", withString: "")
    return flatMap(SWXMLHash.parse(cleanXMLDocs).children.first) { rootXML in
        var docs = XPCDictionary()
        docs[SwiftDocKey.DocType.rawValue] = rootXML.element?.name
        docs[SwiftDocKey.DocFile.rawValue] = rootXML.element?.attributes["file"]
        docs[SwiftDocKey.DocLine.rawValue] = flatMap(rootXML.element?.attributes["line"]) {
            Int64(($0 as NSString).integerValue)
        }
        docs[SwiftDocKey.DocColumn.rawValue] = flatMap(rootXML.element?.attributes["column"]) {
            Int64(($0 as NSString).integerValue)
        }
        docs[SwiftDocKey.DocName.rawValue] = rootXML["Name"].element?.text
        docs[SwiftDocKey.DocUSR.rawValue] = rootXML["USR"].element?.text
        docs[SwiftDocKey.DocDeclaration.rawValue] = rootXML["Declaration"].element?.text
        let parameters = rootXML["Parameters"].children
        if parameters.count > 0 {
            docs[SwiftDocKey.DocParameters.rawValue] = map(parameters) {
                return [
                    "name": $0["Name"].element?.text ?? "",
                    "discussion": childrenAsArray($0["Discussion"]) ?? []
                ] as XPCDictionary
            } as XPCArray
        }
        docs[SwiftDocKey.DocDiscussion.rawValue] = childrenAsArray(rootXML["Discussion"])
        docs[SwiftDocKey.DocResultDiscussion.rawValue] = childrenAsArray(rootXML["ResultDiscussion"])
        return docs
    }
}

/**
Returns an `XPCArray` of `XPCDictionary` items from `indexer` children, if any.

:param: indexer `XMLIndexer` to traverse.
*/
private func childrenAsArray(indexer: XMLIndexer) -> XPCArray? {
    let children = indexer.children
    if children.count > 0 {
        return map(compact(map(children, { $0.element }))) {
            [$0.name: $0.text ?? ""] as XPCDictionary
        } as XPCArray
    }
    return nil
}

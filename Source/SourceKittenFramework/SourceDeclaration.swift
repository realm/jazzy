//
//  SourceDeclaration.swift
//  SourceKitten
//
//  Created by JP Simard on 7/15/15.
//  Copyright © 2015 SourceKitten. All rights reserved.
//

import SwiftXPC
import SWXMLHash

/**
Parse XML from `key.doc.full_as_xml` from `cursor.info` request.

- parameter xmlDocs: Contents of `key.doc.full_as_xml` from SourceKit.

- returns: XML parsed as an `XPCDictionary`.
*/
public func parseFullXMLDocs(xmlDocs: String) -> XPCDictionary? {
    let cleanXMLDocs = xmlDocs.stringByReplacingOccurrencesOfString("<rawHTML>", withString: "")
        .stringByReplacingOccurrencesOfString("</rawHTML>", withString: "")
        .stringByReplacingOccurrencesOfString("<codeVoice>", withString: "`")
        .stringByReplacingOccurrencesOfString("</codeVoice>", withString: "`")
    return SWXMLHash.parse(cleanXMLDocs).children.first.map { rootXML in
        var docs = XPCDictionary()
        docs[SwiftDocKey.DocType.rawValue] = rootXML.element?.name
        docs[SwiftDocKey.DocFile.rawValue] = rootXML.element?.attributes["file"]
        docs[SwiftDocKey.DocLine.rawValue] = rootXML.element?.attributes["line"].flatMap {
            Int64($0)
        }
        docs[SwiftDocKey.DocColumn.rawValue] = rootXML.element?.attributes["column"].flatMap {
            Int64($0)
        }
        docs[SwiftDocKey.DocName.rawValue] = rootXML["Name"].element?.text
        docs[SwiftDocKey.DocUSR.rawValue] = rootXML["USR"].element?.text
        docs[SwiftDocKey.DocDeclaration.rawValue] = rootXML["Declaration"].element?.text
        let parameters = rootXML["Parameters"].children
        if parameters.count > 0 {
            docs[SwiftDocKey.DocParameters.rawValue] = parameters.map {
                [
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

- parameter indexer: `XMLIndexer` to traverse.
*/
private func childrenAsArray(indexer: XMLIndexer) -> XPCArray? {
    let children = indexer.children
    if children.count > 0 {
        return children.flatMap({ $0.element }).map {
            [$0.name: $0.text ?? ""] as XPCDictionary
        } as XPCArray
    }
    return nil
}

//
//  OffsetMap.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-05.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import SwiftXPC

public typealias OffsetMap = [Int: Int]

extension File {
    /// Map documented token offsets to the start of their range
    public func generateOffsetMap(documentedTokenOffsets: [Int], dictionary: XPCDictionary) -> OffsetMap {
        var offsetMap = OffsetMap()
        for offset in documentedTokenOffsets {
            offsetMap[offset] = 0
        }
        offsetMap = mapOffsets(dictionary, documentedTokenOffsets: offsetMap)
        let alreadyDocumentedOffsets = offsetMap.keys.filter { $0 == offsetMap[$0] }
        for alreadyDocumentedOffset in alreadyDocumentedOffsets {
            offsetMap.removeValueForKey(alreadyDocumentedOffset)
        }
        return offsetMap
    }

    /**
    Find parent offsets for given documented offsets.

    :param: dictionary Parent document to search for ranges.
    :param: documentedTokenOffsets dictionary of documented token offsets mapping to their parent offsets.
    :param: file File where these offsets are located.
    */
    public func mapOffsets(dictionary: XPCDictionary, var documentedTokenOffsets: OffsetMap) -> OffsetMap {
        if shouldTreatAsSameFile(dictionary) {
            if let rangeStart = SwiftDocKey.getNameOffset(dictionary) {
                if let rangeLength = SwiftDocKey.getNameLength(dictionary) {
                    let bodyLength = SwiftDocKey.getBodyLength(dictionary)
                    let offsetsInRange = documentedTokenOffsets.keys.filter {
                        $0 >= Int(rangeStart) && $0 <= Int(rangeStart + rangeLength + (bodyLength ?? 0))
                    }
                    for offset in offsetsInRange {
                        documentedTokenOffsets[offset] = Int(rangeStart)
                    }
                }
            }
        }
        for subDict in SwiftDocKey.getSubstructure(dictionary)! {
            documentedTokenOffsets = mapOffsets(subDict as XPCDictionary, documentedTokenOffsets: documentedTokenOffsets)
        }
        return documentedTokenOffsets
    }
}

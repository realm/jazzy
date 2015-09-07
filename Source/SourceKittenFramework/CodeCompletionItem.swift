//
//  CodeCompletionItem.swift
//  SourceKitten
//
//  Created by JP Simard on 9/4/15.
//  Copyright © 2015 SourceKitten. All rights reserved.
//

import Foundation
import SwiftXPC

extension Dictionary {
    private mutating func addIfNotNil(key: Key, _ value: Value?) {
        if let value = value {
            self[key] = value
        }
    }
}

extension NSData {
    private func stringFromRange(start: Int, end: Int) -> String? {
        let start = start
        let length = end - start
        if length < 0 {
            return nil
        }
        var buffer = [CChar](count: length, repeatedValue: 0)
        getBytes(&buffer, range: NSRange(location: start, length: length))
        return String.fromCString(&buffer)
    }
}

public struct CodeCompletionItem: CustomStringConvertible {
    public let kind: String
    public let context: String
    public let name: String?
    public let descriptionKey: String?
    public let sourcetext: String?
    public let typeName: String?
    public let moduleName: String?
    public let docBrief: String?
    public let associatedUSRs: String?

    public init(kind: String, context: String, name: String?,
                descriptionKey: String?, sourcetext: String?, typeName: String?,
                moduleName: String?, docBrief: String?, associatedUSRs: String?) {
        self.kind = kind
        self.context = context
        self.name = name
        self.descriptionKey = descriptionKey
        self.sourcetext = sourcetext
        self.typeName = typeName
        self.moduleName = moduleName
        self.docBrief = docBrief
        self.associatedUSRs = associatedUSRs
    }

    /// Dictionary representation of CodeCompletionItem. Useful for NSJSONSerialization.
    public var dictionaryValue: [String: AnyObject] {
        var dict = [
            "kind": kind,
            "context": context
        ]
        dict.addIfNotNil("name", name)
        dict.addIfNotNil("descriptionKey", descriptionKey)
        dict.addIfNotNil("sourcetext", sourcetext)
        dict.addIfNotNil("typeName", typeName)
        dict.addIfNotNil("moduleName", moduleName)
        dict.addIfNotNil("docBrief", docBrief)
        dict.addIfNotNil("associatedUSRs", associatedUSRs)
        return dict
    }

    public var description: String {
        return toJSON(dictionaryValue)
    }

    public static func parseResponse(response: XPCDictionary) -> [CodeCompletionItem] {
        return (response["key.results"] as? NSData).map { parseItems($0) } ?? []
    }

    public static func parseItems(data: NSData) -> [CodeCompletionItem] {
        var buffer = UInt64(0)
        data.getBytes(&buffer, range: NSRange(location: 8, length: 8))
        let maxRange = Int(buffer.littleEndian) + 16
        var smallerBuffer = UInt32(0)
        let notFound = UInt32.max
        let offsets = 16.stride(to: maxRange, by: 45).map { offset in
            return (offset + 8).stride(through: offset + 32, by: 4).map { offset -> Int? in
                data.getBytes(&smallerBuffer, range: NSRange(location: offset, length: 4))
                if smallerBuffer != notFound {
                    return maxRange + Int(smallerBuffer)
                }
                return nil
            }
        }
        let flatOffsets = offsets.flatMap({ $0 }).flatMap({ $0 })
        let offsetPairs = zip(flatOffsets, Array(flatOffsets.dropFirst()) + [data.length])
        var offsetsToStrings = [Int: String]()
        for (offset, nextOffset) in offsetPairs {
            if let string = data.stringFromRange(offset, end: nextOffset) {
                offsetsToStrings[offset] = string
            }
        }
        return 16.stride(to: maxRange, by: 45).enumerate().flatMap { index, offset -> CodeCompletionItem? in
            data.getBytes(&buffer, range: NSRange(location: offset, length: 8))
            guard let kind = stringForSourceKitUID(buffer) else {
                return nil
            }
            data.getBytes(&buffer, range: NSRange(location: offset + 36, length: 8))
            guard let context = stringForSourceKitUID(buffer) else {
                return nil
            }
            return CodeCompletionItem(kind: kind,
                context: context,
                name: offsets[index][0].flatMap({ offsetsToStrings[$0] }),
                descriptionKey: offsets[index][1].flatMap({ offsetsToStrings[$0] }),
                sourcetext: offsets[index][2].flatMap({ offsetsToStrings[$0] }),
                typeName: offsets[index][3].flatMap({ offsetsToStrings[$0] }),
                moduleName: offsets[index][4].flatMap({ offsetsToStrings[$0] }),
                docBrief: offsets[index][5].flatMap({ offsetsToStrings[$0] }),
                associatedUSRs: offsets[index][6].flatMap({ offsetsToStrings[$0] })
            )
        }
    }
}

//
//  SwiftDocKey.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-05.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import Foundation
import SwiftXPC

internal enum SwiftDocKey: String {
    case Kind                 = "key.kind"
    case SyntaxMap            = "key.syntaxmap"
    case Offset               = "key.offset"
    case Length               = "key.length"
    case TypeName             = "key.typename"
    case AnnotatedDeclaration = "key.annotated_decl"
    case Substructure         = "key.substructure"
    case ParsedDeclaration    = "key.parsed_declaration"
    case NameOffset           = "key.nameoffset"
    case NameLength           = "key.namelength"
    case BodyOffset           = "key.bodyoffset"
    case BodyLength           = "key.bodylength"
    case FilePath             = "key.filepath"
    case Name                 = "key.name"
    case DiagnosticStage      = "key.diagnostic_stage"

    private static func get<T>(key: SwiftDocKey, _ dictionary: XPCDictionary) -> T? {
        return dictionary[key.rawValue] as T?
    }

    static func getKind(dictionary: XPCDictionary) -> String? {
        return SwiftDocKey.get(.Kind, dictionary)
    }
    static func getSyntaxMap(dictionary: XPCDictionary) -> NSData? {
        return SwiftDocKey.get(.SyntaxMap, dictionary)
    }
    static func getOffset(dictionary: XPCDictionary) -> Int64? {
        return SwiftDocKey.get(.Offset, dictionary)
    }
    static func getLength(dictionary: XPCDictionary) -> Int64? {
        return SwiftDocKey.get(.Length, dictionary)
    }
    static func getTypeName(dictionary: XPCDictionary) -> String? {
        return SwiftDocKey.get(.TypeName, dictionary)
    }
    static func getAnnotatedDeclaration(dictionary: XPCDictionary) -> String? {
        return SwiftDocKey.get(.AnnotatedDeclaration, dictionary)
    }
    static func getSubstructure(dictionary: XPCDictionary) -> XPCArray? {
        return SwiftDocKey.get(.Substructure, dictionary)
    }
    static func getParsedDeclaration(dictionary: XPCDictionary) -> String? {
        return SwiftDocKey.get(.ParsedDeclaration, dictionary)
    }
    static func getNameOffset(dictionary: XPCDictionary) -> Int64? {
        return SwiftDocKey.get(.NameOffset, dictionary)
    }
    static func getNameLength(dictionary: XPCDictionary) -> Int64? {
        return SwiftDocKey.get(.NameLength, dictionary)
    }
    static func getBodyOffset(dictionary: XPCDictionary) -> Int64? {
        return SwiftDocKey.get(.BodyOffset, dictionary)
    }
    static func getBodyLength(dictionary: XPCDictionary) -> Int64? {
        return SwiftDocKey.get(.BodyLength, dictionary)
    }
    static func getFilePath(dictionary: XPCDictionary) -> String? {
        return SwiftDocKey.get(.FilePath, dictionary)
    }
    static func getName(dictionary: XPCDictionary) -> String? {
        return SwiftDocKey.get(.Name, dictionary)
    }
    static func getDiagnosticStage(dictionary: XPCDictionary) -> String? {
        return SwiftDocKey.get(.DiagnosticStage, dictionary)
    }
}

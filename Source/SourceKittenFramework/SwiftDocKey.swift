//
//  SwiftDocKey.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-05.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import Foundation
import SwiftXPC

/// SourceKit response dictionary keys.
internal enum SwiftDocKey: String {
    /// Represents a kind (String).
    case Kind                 = "key.kind"
    /// Represents a syntax map (NSData).
    case SyntaxMap            = "key.syntaxmap"
    /// Represents an offset (Int64).
    case Offset               = "key.offset"
    /// Represents a length (Int64).
    case Length               = "key.length"
    /// Represents a type name (String).
    case TypeName             = "key.typename"
    /// Represents an annotated declaration (String).
    case AnnotatedDeclaration = "key.annotated_decl"
    /// Represents a substructure (XPCArray).
    case Substructure         = "key.substructure"
    /// Represents a parsed declaration (String).
    case ParsedDeclaration    = "key.parsed_declaration"
    /// Represents a parsed scope start (Int64).
    case ParsedScopeStart     = "key.parsed_scope.start"
    /// Represents a parsed scope start end (Int64).
    case ParsedScopeEnd       = "key.parsed_scope.end"
    /// Represents a name offset (Int64).
    case NameOffset           = "key.nameoffset"
    /// Represents a name length (Int64).
    case NameLength           = "key.namelength"
    /// Represents a body offset (Int64).
    case BodyOffset           = "key.bodyoffset"
    /// Represents a body length (Int64).
    case BodyLength           = "key.bodylength"
    /// Represents a file path (String).
    case FilePath             = "key.filepath"
    /// Represents a name (String).
    case Name                 = "key.name"
    /// Represents a diagnostic stage (String).
    case DiagnosticStage      = "key.diagnostic_stage"

    // MARK: Typed SwiftDocKey Getters

    /**
    Returns the typed value of a dictionary key.

    :param: key        SwiftDoctKey to get from the dictionary.
    :param: dictionary Dictionary to get value from.

    :returns: Typed value of a dictionary key.
    */
    private static func get<T>(key: SwiftDocKey, _ dictionary: XPCDictionary) -> T? {
        return dictionary[key.rawValue] as T?
    }

    /**
    Get kind string from dictionary.

    :param: dictionary Dictionary to get value from.

    :returns: Kind string if successful.
    */
    internal static func getKind(dictionary: XPCDictionary) -> String? {
        return SwiftDocKey.get(.Kind, dictionary)
    }

    /**
    Get syntax map data from dictionary.

    :param: dictionary Dictionary to get value from.

    :returns: Syntax map data if successful.
    */
    internal static func getSyntaxMap(dictionary: XPCDictionary) -> NSData? {
        return SwiftDocKey.get(.SyntaxMap, dictionary)
    }

    /**
    Get offset int from dictionary.

    :param: dictionary Dictionary to get value from.

    :returns: Offset int if successful.
    */
    internal static func getOffset(dictionary: XPCDictionary) -> Int64? {
        return SwiftDocKey.get(.Offset, dictionary)
    }

    /**
    Get length int from dictionary.

    :param: dictionary Dictionary to get value from.

    :returns: Length int if successful.
    */
    internal static func getLength(dictionary: XPCDictionary) -> Int64? {
        return SwiftDocKey.get(.Length, dictionary)
    }

    /**
    Get type name string from dictionary.

    :param: dictionary Dictionary to get value from.

    :returns: Type name string if successful.
    */
    internal static func getTypeName(dictionary: XPCDictionary) -> String? {
        return SwiftDocKey.get(.TypeName, dictionary)
    }

    /**
    Get annotated declaration string from dictionary.

    :param: dictionary Dictionary to get value from.

    :returns: Annotated declaration string if successful.
    */
    internal static func getAnnotatedDeclaration(dictionary: XPCDictionary) -> String? {
        return SwiftDocKey.get(.AnnotatedDeclaration, dictionary)
    }

    /**
    Get substructure array from dictionary.

    :param: dictionary Dictionary to get value from.

    :returns: Substructure array if successful.
    */
    internal static func getSubstructure(dictionary: XPCDictionary) -> XPCArray? {
        return SwiftDocKey.get(.Substructure, dictionary)
    }

    /**
    Get parsed declaration string from dictionary.

    :param: dictionary Dictionary to get value from.

    :returns: Parsed declaration string if successful.
    */
    internal static func getParsedDeclaration(dictionary: XPCDictionary) -> String? {
        return SwiftDocKey.get(.ParsedDeclaration, dictionary)
    }

    /**
    Get name offset int from dictionary.

    :param: dictionary Dictionary to get value from.

    :returns: Name offset int if successful.
    */
    internal static func getNameOffset(dictionary: XPCDictionary) -> Int64? {
        return SwiftDocKey.get(.NameOffset, dictionary)
    }

    /**
    Get length int from dictionary.

    :param: dictionary Dictionary to get value from.

    :returns: Length int if successful.
    */
    internal static func getNameLength(dictionary: XPCDictionary) -> Int64? {
        return SwiftDocKey.get(.NameLength, dictionary)
    }

    /**
    Get body offset int from dictionary.

    :param: dictionary Dictionary to get value from.

    :returns: Body offset int if successful.
    */
    internal static func getBodyOffset(dictionary: XPCDictionary) -> Int64? {
        return SwiftDocKey.get(.BodyOffset, dictionary)
    }

    /**
    Get body length int from dictionary.

    :param: dictionary Dictionary to get value from.

    :returns: Body length int if successful.
    */
    internal static func getBodyLength(dictionary: XPCDictionary) -> Int64? {
        return SwiftDocKey.get(.BodyLength, dictionary)
    }

    /**
    Get file path string from dictionary.

    :param: dictionary Dictionary to get value from.

    :returns: File path string if successful.
    */
    internal static func getFilePath(dictionary: XPCDictionary) -> String? {
        return SwiftDocKey.get(.FilePath, dictionary)
    }

    /**
    Get name string from dictionary.

    :param: dictionary Dictionary to get value from.

    :returns: Name string if successful.
    */
    internal static func getName(dictionary: XPCDictionary) -> String? {
        return SwiftDocKey.get(.Name, dictionary)
    }

    /**
    Get diagnostic stage string from dictionary.

    :param: dictionary Dictionary to get value from.

    :returns: Diagnostic stage string if successful.
    */
    internal static func getDiagnosticStage(dictionary: XPCDictionary) -> String? {
        return SwiftDocKey.get(.DiagnosticStage, dictionary)
    }
}

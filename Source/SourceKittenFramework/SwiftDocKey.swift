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
    // MARK: SourceKit Keys

    /// Annotated declaration (String).
    case AnnotatedDeclaration = "key.annotated_decl"
    /// Body length (Int64).
    case BodyLength           = "key.bodylength"
    /// Body offset (Int64).
    case BodyOffset           = "key.bodyoffset"
    /// Diagnostic stage (String).
    case DiagnosticStage      = "key.diagnostic_stage"
    /// File path (String).
    case FilePath             = "key.filepath"
    /// Full XML docs (String).
    case FullXMLDocs          = "key.doc.full_as_xml"
    /// Kind (String).
    case Kind                 = "key.kind"
    /// Length (Int64).
    case Length               = "key.length"
    /// Name (String).
    case Name                 = "key.name"
    /// Name length (Int64).
    case NameLength           = "key.namelength"
    /// Name offset (Int64).
    case NameOffset           = "key.nameoffset"
    /// Offset (Int64).
    case Offset               = "key.offset"
    /// Substructure (XPCArray).
    case Substructure         = "key.substructure"
    /// Syntax map (NSData).
    case SyntaxMap            = "key.syntaxmap"
    /// Type name (String).
    case TypeName             = "key.typename"

    // MARK: Custom Keys

    /// Column where the token's declaration begins (Int64).
    case DocColumn            = "key.doc.column"
    /// Documentation comment (String).
    case DocumentationComment = "key.doc.comment"
    /// Declaration of documented token (String).
    case DocDeclaration       = "key.doc.declaration"
    /// Discussion documentation of documented token (XPCArray).
    case DocDiscussion        = "key.doc.discussion"
    /// File where the documented token is located (String).
    case DocFile              = "key.doc.file"
    /// Line where the token's declaration begins (Int64).
    case DocLine              = "key.doc.line"
    /// Name of documented token (String).
    case DocName              = "key.doc.name"
    /// Parameters of documented token (XPCArray).
    case DocParameters        = "key.doc.parameters"
    /// Parsed declaration (String).
    case DocResultDiscussion  = "key.doc.result_discussion"
    /// Parsed scope start (Int64).
    case DocType              = "key.doc.type"
    /// Parsed scope start end (Int64).
    case DocUSR               = "key.doc.usr"
    /// Result discussion documentation of documented token (XPCArray).
    case ParsedDeclaration    = "key.parsed_declaration"
    /// Type of documented token (String).
    case ParsedScopeEnd       = "key.parsed_scope.end"
    /// USR of documented token (String).
    case ParsedScopeStart     = "key.parsed_scope.start"


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

    /**
    Get full xml docs string from dictionary.

    :param: dictionary Dictionary to get value from.

    :returns: Full xml docs string if successful.
    */
    internal static func getFullXMLDocs(dictionary: XPCDictionary) -> String? {
        return SwiftDocKey.get(.FullXMLDocs, dictionary)
    }
}

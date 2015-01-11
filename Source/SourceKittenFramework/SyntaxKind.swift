//
//  SyntaxKind.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-03.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

/// Syntax kind values.
public enum SyntaxKind: String {
    /// Represents a comment mark.
    case CommentMark = "source.lang.swift.syntaxtype.comment.mark"
    /// Represents an identifier.
    case Identifier  = "source.lang.swift.syntaxtype.identifier"
    /// Represents a comment.
    case Comment     = "source.lang.swift.syntaxtype.comment"
    /// Represents a comment URL.
    case CommentURL  = "source.lang.swift.syntaxtype.comment.url"
    /// Represents a keyword.
    case Keyword     = "source.lang.swift.syntaxtype.keyword"
    /// Represents a built-in attribute.
    case BuiltIn     = "source.lang.swift.syntaxtype.attribute.builtin"
    /// Represents a string literal.
    case _String     = "source.lang.swift.syntaxtype.string"
    /// Represents a type identifier.
    case TypeID      = "source.lang.swift.syntaxtype.typeidentifier"
    /// Represents a number literal.
    case Number      = "source.lang.swift.syntaxtype.number"
    /// Represents an attribute.
    case Attribute   = "source.lang.swift.syntaxtype.attribute.id"
}

//
//  SyntaxKind.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-03.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

/// Syntax kind values.
/// Found in `strings SourceKitService | grep source.lang.swift.syntaxtype.`.
public enum SyntaxKind: String {
    /// `argument`.
    case Argument = "source.lang.swift.syntaxtype.argument"
    /// `attribute.builtin`.
    case AttributeBuiltin = "source.lang.swift.syntaxtype.attribute.builtin"
    /// `attribute.id`.
    case AttributeID = "source.lang.swift.syntaxtype.attribute.id"
    /// `buildconfig.id`.
    case BuildconfigID = "source.lang.swift.syntaxtype.buildconfig.id"
    /// `buildconfig.keyword`.
    case BuildconfigKeyword = "source.lang.swift.syntaxtype.buildconfig.keyword"
    /// `comment`.
    case Comment = "source.lang.swift.syntaxtype.comment"
    /// `comment.mark`.
    case CommentMark = "source.lang.swift.syntaxtype.comment.mark"
    /// `comment.url`.
    case CommentURL = "source.lang.swift.syntaxtype.comment.url"
    /// `identifier`.
    case Identifier = "source.lang.swift.syntaxtype.identifier"
    /// `keyword`.
    case Keyword = "source.lang.swift.syntaxtype.keyword"
    /// `number`.
    case Number = "source.lang.swift.syntaxtype.number"
    /// `parameter`.
    case Parameter = "source.lang.swift.syntaxtype.parameter"
    /// `string`.
    case String = "source.lang.swift.syntaxtype.string"
    /// `string_interpolation_anchor`.
    case StringInterpolationAnchor = "source.lang.swift.syntaxtype.string_interpolation_anchor"
    /// `typeidentifier`.
    case Typeidentifier = "source.lang.swift.syntaxtype.typeidentifier"

    /**
    Returns true if the input is a comment-like syntax kind string.

    - parameter string: Input string.
    */
    internal static func isCommentLike(string: Swift.String) -> Bool {
        return [Comment.rawValue, CommentMark.rawValue, CommentURL.rawValue].contains(string)
    }
}

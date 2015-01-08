//
//  SyntaxKind.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-03.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

public enum SyntaxKind: String {
    case CommentMark = "source.lang.swift.syntaxtype.comment.mark"
    case Identifier  = "source.lang.swift.syntaxtype.identifier"
    case Comment     = "source.lang.swift.syntaxtype.comment"
    case CommentURL  = "source.lang.swift.syntaxtype.comment.url"
    case Keyword     = "source.lang.swift.syntaxtype.keyword"
    case BuiltIn     = "source.lang.swift.syntaxtype.attribute.builtin"
    case _String     = "source.lang.swift.syntaxtype.string"
    case TypeID      = "source.lang.swift.syntaxtype.typeidentifier"
    case Number      = "source.lang.swift.syntaxtype.number"
    case Attribute   = "source.lang.swift.syntaxtype.attribute.id"
}

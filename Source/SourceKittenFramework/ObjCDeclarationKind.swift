//
//  ObjCDeclarationKind.swift
//  SourceKitten
//
//  Created by JP Simard on 7/15/15.
//  Copyright © 2015 SourceKitten. All rights reserved.
//

/**
Objective-C declaration kinds.
More or less equivalent to `SwiftDeclarationKind`, but with made up values because there's no such
thing as SourceKit for Objective-C.
*/
public enum ObjCDeclarationKind: String {
    /// `category`.
    case Category = "sourcekitten.source.lang.objc.decl.category"
    /// `class`.
    case Class = "sourcekitten.source.lang.objc.decl.class"
    /// `constant`.
    case Constant = "sourcekitten.source.lang.objc.decl.constant"
    /// `enum`.
    case Enum = "sourcekitten.source.lang.objc.decl.enum"
    /// `enumcase`.
    case Enumcase = "sourcekitten.source.lang.objc.decl.enumcase"
    /// `initializer`.
    case Initializer = "sourcekitten.source.lang.objc.decl.initializer"
    /// `method.class`.
    case MethodClass = "sourcekitten.source.lang.objc.decl.method.class"
    /// `method.instance`.
    case MethodInstance = "sourcekitten.source.lang.objc.decl.method.instance"
    /// `property`.
    case Property = "sourcekitten.source.lang.objc.decl.property"
    /// `protocol`.
    case Protocol = "sourcekitten.source.lang.objc.decl.protocol"
    /// `typedef`.
    case Typedef = "sourcekitten.source.lang.objc.decl.typedef"
    /// `function`.
    case Function = "sourcekitten.source.lang.objc.decl.function"
    /// `mark`.
    case Mark = "sourcekitten.source.lang.objc.mark"

    public static func fromClang(kind: CXCursorKind) -> ObjCDeclarationKind {
        switch kind.rawValue {
        case CXCursor_ObjCCategoryDecl.rawValue: return .Category
        case CXCursor_ObjCInterfaceDecl.rawValue: return .Class
        case CXCursor_EnumDecl.rawValue: return .Enum
        case CXCursor_EnumConstantDecl.rawValue: return .Enumcase
        case CXCursor_ObjCClassMethodDecl.rawValue: return .MethodClass
        case CXCursor_ObjCInstanceMethodDecl.rawValue: return .MethodInstance
        case CXCursor_ObjCPropertyDecl.rawValue: return .Property
        case CXCursor_ObjCProtocolDecl.rawValue: return .Protocol
        case CXCursor_TypedefDecl.rawValue: return .Typedef
        case CXCursor_VarDecl.rawValue: return .Constant
        case CXCursor_FunctionDecl.rawValue: return .Function
        default: fatalError("Unsupported CXCursorKind value: \(kind.rawValue)")
        }
    }
}

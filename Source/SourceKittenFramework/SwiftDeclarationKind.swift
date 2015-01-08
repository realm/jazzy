//
//  SwiftDeclarationKind.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-05.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

public func isSwiftDeclarationKind(string: String?) -> Bool {
    return string != nil &&
        string?.rangeOfString("source.lang.swift.decl.")?.startIndex == string?.startIndex
}

public enum SwiftDeclarationKind: String {
    case ClassMethod      = "source.lang.swift.decl.function.method.class"
    case ClassVariable    = "source.lang.swift.decl.var.class"
    case Class            = "source.lang.swift.decl.class"
    case Constructor      = "source.lang.swift.decl.function.constructor"
    case Destructor       = "source.lang.swift.decl.function.destructor"
    case Global           = "source.lang.swift.decl.var.global"
    case EnumElement      = "source.lang.swift.decl.enumelement"
    case Enum             = "source.lang.swift.decl.enum"
    case Extension        = "source.lang.swift.decl.extension"
    case FreeFunction     = "source.lang.swift.decl.function.free"
    case Method           = "source.lang.swift.decl.function.method.instance"
    case InstanceVariable = "source.lang.swift.decl.var.instance"
    case LocalVariable    = "source.lang.swift.decl.var.local"
    case Parameter        = "source.lang.swift.decl.var.parameter"
    case Protocol         = "source.lang.swift.decl.protocol"
    case StaticMethod     = "source.lang.swift.decl.function.method.static"
    case StaticVariable   = "source.lang.swift.decl.var.static"
    case Struct           = "source.lang.swift.decl.struct"
    case Subscript        = "source.lang.swift.decl.function.subscript"
    case TypeAlias        = "source.lang.swift.decl.typealias"
}

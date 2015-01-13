//
//  SwiftDeclarationKind.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-05.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

/**
Returns true if input string represents a declaration kind.

:param: string String to evaluate.

:returns: True if input string represents a declaration kind.
*/
public func isSwiftDeclarationKind(string: String?) -> Bool {
    return string != nil &&
        string?.rangeOfString("source.lang.swift.decl.")?.startIndex == string?.startIndex
}

/// Declaration kind values.
public enum SwiftDeclarationKind: String {
    /// Represents a class method.
    case ClassMethod      = "source.lang.swift.decl.function.method.class"
    /// Represents a class variable.
    case ClassVariable    = "source.lang.swift.decl.var.class"
    /// Represents a class.
    case Class            = "source.lang.swift.decl.class"
    /// Represents a constructor (initializer).
    case Constructor      = "source.lang.swift.decl.function.constructor"
    /// Represents a destructor.
    case Destructor       = "source.lang.swift.decl.function.destructor"
    /// Represents a global.
    case Global           = "source.lang.swift.decl.var.global"
    /// Represents an enum element.
    case EnumElement      = "source.lang.swift.decl.enumelement"
    /// Represents an enum.
    case Enum             = "source.lang.swift.decl.enum"
    /// Represents an extension.
    case Extension        = "source.lang.swift.decl.extension"
    /// Represents a free function.
    case FreeFunction     = "source.lang.swift.decl.function.free"
    /// Represents a method.
    case Method           = "source.lang.swift.decl.function.method.instance"
    /// Represents an instance variable.
    case InstanceVariable = "source.lang.swift.decl.var.instance"
    /// Represents a local variable.
    case LocalVariable    = "source.lang.swift.decl.var.local"
    /// Represents a parameter.
    case Parameter        = "source.lang.swift.decl.var.parameter"
    /// Represents a protocol.
    case Protocol         = "source.lang.swift.decl.protocol"
    /// Represents a static method.
    case StaticMethod     = "source.lang.swift.decl.function.method.static"
    /// Represents a static variable.
    case StaticVariable   = "source.lang.swift.decl.var.static"
    /// Represents a struct.
    case Struct           = "source.lang.swift.decl.struct"
    /// Represents a susbcript function.
    case Subscript        = "source.lang.swift.decl.function.subscript"
    /// Represents a typealias.
    case TypeAlias        = "source.lang.swift.decl.typealias"
}

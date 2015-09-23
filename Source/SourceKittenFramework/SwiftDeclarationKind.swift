//
//  SwiftDeclarationKind.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-05.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

/// Swift declaration kinds.
/// Found in `strings SourceKitService | grep source.lang.swift.decl.`.
public enum SwiftDeclarationKind: String {
    /// `class`.
    case Class = "source.lang.swift.decl.class"
    /// `enum`.
    case Enum = "source.lang.swift.decl.enum"
    /// `enumcase`.
    case Enumcase = "source.lang.swift.decl.enumcase"
    /// `enumelement`.
    case Enumelement = "source.lang.swift.decl.enumelement"
    /// `extension`.
    case Extension = "source.lang.swift.decl.extension"
    /// `extension.class`.
    case ExtensionClass = "source.lang.swift.decl.extension.class"
    /// `extension.enum`.
    case ExtensionEnum = "source.lang.swift.decl.extension.enum"
    /// `extension.protocol`.
    case ExtensionProtocol = "source.lang.swift.decl.extension.protocol"
    /// `extension.struct`.
    case ExtensionStruct = "source.lang.swift.decl.extension.struct"
    /// `function.accessor.address`.
    case FunctionAccessorAddress = "source.lang.swift.decl.function.accessor.address"
    /// `function.accessor.didset`.
    case FunctionAccessorDidset = "source.lang.swift.decl.function.accessor.didset"
    /// `function.accessor.getter`.
    case FunctionAccessorGetter = "source.lang.swift.decl.function.accessor.getter"
    /// `function.accessor.mutableaddress`.
    case FunctionAccessorMutableaddress = "source.lang.swift.decl.function.accessor.mutableaddress"
    /// `function.accessor.setter`.
    case FunctionAccessorSetter = "source.lang.swift.decl.function.accessor.setter"
    /// `function.accessor.willset`.
    case FunctionAccessorWillset = "source.lang.swift.decl.function.accessor.willset"
    /// `function.constructor`.
    case FunctionConstructor = "source.lang.swift.decl.function.constructor"
    /// `function.destructor`.
    case FunctionDestructor = "source.lang.swift.decl.function.destructor"
    /// `function.free`.
    case FunctionFree = "source.lang.swift.decl.function.free"
    /// `function.method.class`.
    case FunctionMethodClass = "source.lang.swift.decl.function.method.class"
    /// `function.method.instance`.
    case FunctionMethodInstance = "source.lang.swift.decl.function.method.instance"
    /// `function.method.static`.
    case FunctionMethodStatic = "source.lang.swift.decl.function.method.static"
    /// `function.operator`.
    case FunctionOperator = "source.lang.swift.decl.function.operator"
    /// `function.subscript`.
    case FunctionSubscript = "source.lang.swift.decl.function.subscript"
    /// `generic_type_param`.
    case GenericTypeParam = "source.lang.swift.decl.generic_type_param"
    /// `module`
    case Module = "source.lang.swift.decl.module"
    /// `protocol`.
    case Protocol = "source.lang.swift.decl.protocol"
    /// `struct`.
    case Struct = "source.lang.swift.decl.struct"
    /// `typealias`.
    case Typealias = "source.lang.swift.decl.typealias"
    /// `var.class`.
    case VarClass = "source.lang.swift.decl.var.class"
    /// `var.global`.
    case VarGlobal = "source.lang.swift.decl.var.global"
    /// `var.instance`.
    case VarInstance = "source.lang.swift.decl.var.instance"
    /// `var.local`.
    case VarLocal = "source.lang.swift.decl.var.local"
    /// `var.parameter`.
    case VarParameter = "source.lang.swift.decl.var.parameter"
    /// `var.static`.
    case VarStatic = "source.lang.swift.decl.var.static"
}

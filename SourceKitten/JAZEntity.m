//
//  JAZEntity.m
//  SourceKitten
//
//  Created by JP Simard on 9/13/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import "JAZEntity.h"

NSString *stringFromJAZEntityKind(JAZEntityKind kind) {
    switch (kind) {
        case JAZEntityKindDeclFunctionFree:
            return @"source.lang.swift.decl.function.free";
        case JAZEntityKindRefFunctionFree:
            return @"source.lang.swift.ref.function.free";
        case JAZEntityKindDeclMethodInstance:
            return @"source.lang.swift.decl.function.method.instance";
        case JAZEntityKindRefMethodInstance:
            return @"source.lang.swift.ref.function.method.instance";
        case JAZEntityKindDeclMethodStatic:
            return @"source.lang.swift.decl.function.method.static";
        case JAZEntityKindRefMethodStatic:
            return @"source.lang.swift.ref.function.method.static";
        case JAZEntityKindDeclMethodClass:
            return @"source.lang.swift.decl.function.method.class";
        case JAZEntityKindRefMethodClass:
            return @"source.lang.swift.ref.function.method.class";
        case JAZEntityKindDeclAccessorGetter:
            return @"source.lang.swift.decl.function.accessor.getter";
        case JAZEntityKindRefAccessorGetter:
            return @"source.lang.swift.ref.function.accessor.getter";
        case JAZEntityKindDeclAccessorSetter:
            return @"source.lang.swift.decl.function.accessor.setter";
        case JAZEntityKindRefAccessorSetter:
            return @"source.lang.swift.ref.function.accessor.setter";
        case JAZEntityKindDeclAccessorWillSet:
            return @"source.lang.swift.decl.function.accessor.willset";
        case JAZEntityKindRefAccessorWillSet:
            return @"source.lang.swift.ref.function.accessor.willset";
        case JAZEntityKindDeclAccessorDidSet:
            return @"source.lang.swift.decl.function.accessor.didset";
        case JAZEntityKindRefAccessorDidSet:
            return @"source.lang.swift.ref.function.accessor.didset";
        case JAZEntityKindDeclConstructor:
            return @"source.lang.swift.decl.function.constructor";
        case JAZEntityKindRefConstructor:
            return @"source.lang.swift.ref.function.constructor";
        case JAZEntityKindDeclDestructor:
            return @"source.lang.swift.decl.function.destructor";
        case JAZEntityKindRefDestructor:
            return @"source.lang.swift.ref.function.destructor";
        case JAZEntityKindDeclFunctionOperator:
            return @"source.lang.swift.decl.function.operator";
        case JAZEntityKindRefFunctionOperator:
            return @"source.lang.swift.ref.function.operator";
        case JAZEntityKindDeclSubscript:
            return @"source.lang.swift.decl.function.subscript";
        case JAZEntityKindRefSubscript:
            return @"source.lang.swift.ref.function.subscript";
        case JAZEntityKindDeclVarGlobal:
            return @"source.lang.swift.decl.var.global";
        case JAZEntityKindRefVarGlobal:
            return @"source.lang.swift.ref.var.global";
        case JAZEntityKindDeclVarInstance:
            return @"source.lang.swift.decl.var.instance";
        case JAZEntityKindRefVarInstance:
            return @"source.lang.swift.ref.var.instance";
        case JAZEntityKindDeclVarStatic:
            return @"source.lang.swift.decl.var.static";
        case JAZEntityKindRefVarStatic:
            return @"source.lang.swift.ref.var.static";
        case JAZEntityKindDeclVarClass:
            return @"source.lang.swift.decl.var.class";
        case JAZEntityKindRefVarClass:
            return @"source.lang.swift.ref.var.class";
        case JAZEntityKindDeclVarLocal:
            return @"source.lang.swift.decl.var.local";
        case JAZEntityKindRefVarLocal:
            return @"source.lang.swift.ref.var.local";
        case JAZEntityKindDeclClass:
            return @"source.lang.swift.decl.class";
        case JAZEntityKindRefClass:
            return @"source.lang.swift.ref.class";
        case JAZEntityKindDeclStruct:
            return @"source.lang.swift.decl.struct";
        case JAZEntityKindRefStruct:
            return @"source.lang.swift.ref.struct";
        case JAZEntityKindDeclEnum:
            return @"source.lang.swift.decl.enum";
        case JAZEntityKindRefEnum:
            return @"source.lang.swift.ref.enum";
        case JAZEntityKindDeclEnumElement:
            return @"source.lang.swift.decl.enumelement";
        case JAZEntityKindRefEnumElement:
            return @"source.lang.swift.ref.enumelement";
        case JAZEntityKindDeclProtocol:
            return @"source.lang.swift.decl.protocol";
        case JAZEntityKindRefProtocol:
            return @"source.lang.swift.ref.protocol";
        case JAZEntityKindDeclExtensionStruct:
            return @"source.lang.swift.decl.extension.struct";
        case JAZEntityKindDeclExtensionClass:
            return @"source.lang.swift.decl.extension.class";
        case JAZEntityKindDeclExtensionEnum:
            return @"source.lang.swift.decl.extension.enum";
        case JAZEntityKindDeclTypeAlias:
            return @"source.lang.swift.decl.typealias";
        case JAZEntityKindRefTypeAlias:
            return @"source.lang.swift.ref.typealias";
        case JAZEntityKindDeclGenericTypeParam:
            return @"source.lang.swift.decl.generic_type_param";
        case JAZEntityKindRefGenericTypeParam:
            return @"source.lang.swift.ref.generic_type_param";
        case JAZEntityKindRefModule:
            return @"source.lang.swift.ref.module";

        default:
            break;
    }
    return nil;
}

JAZEntityKind JAZEntityKindFromCString(const char *cstring) {
    if (!strcmp(cstring, "source.lang.swift.decl.function.free")) {
        return JAZEntityKindDeclFunctionFree;
    } else if (!strcmp(cstring, "source.lang.swift.ref.function.free")) {
        return JAZEntityKindRefFunctionFree;
    } else if (!strcmp(cstring, "source.lang.swift.decl.function.method.instance")) {
        return JAZEntityKindDeclMethodInstance;
    } else if (!strcmp(cstring, "source.lang.swift.ref.function.method.instance")) {
        return JAZEntityKindRefMethodInstance;
    } else if (!strcmp(cstring, "source.lang.swift.decl.function.method.static")) {
        return JAZEntityKindDeclMethodStatic;
    } else if (!strcmp(cstring, "source.lang.swift.ref.function.method.static")) {
        return JAZEntityKindRefMethodStatic;
    } else if (!strcmp(cstring, "source.lang.swift.decl.function.method.class")) {
        return JAZEntityKindDeclMethodClass;
    } else if (!strcmp(cstring, "source.lang.swift.ref.function.method.class")) {
        return JAZEntityKindRefMethodClass;
    } else if (!strcmp(cstring, "source.lang.swift.decl.function.accessor.getter")) {
        return JAZEntityKindDeclAccessorGetter;
    } else if (!strcmp(cstring, "source.lang.swift.ref.function.accessor.getter")) {
        return JAZEntityKindRefAccessorGetter;
    } else if (!strcmp(cstring, "source.lang.swift.decl.function.accessor.setter")) {
        return JAZEntityKindDeclAccessorSetter;
    } else if (!strcmp(cstring, "source.lang.swift.ref.function.accessor.setter")) {
        return JAZEntityKindRefAccessorSetter;
    } else if (!strcmp(cstring, "source.lang.swift.decl.function.accessor.willset")) {
        return JAZEntityKindDeclAccessorWillSet;
    } else if (!strcmp(cstring, "source.lang.swift.ref.function.accessor.willset")) {
        return JAZEntityKindRefAccessorWillSet;
    } else if (!strcmp(cstring, "source.lang.swift.decl.function.accessor.didset")) {
        return JAZEntityKindDeclAccessorDidSet;
    } else if (!strcmp(cstring, "source.lang.swift.ref.function.accessor.didset")) {
        return JAZEntityKindRefAccessorDidSet;
    } else if (!strcmp(cstring, "source.lang.swift.decl.function.constructor")) {
        return JAZEntityKindDeclConstructor;
    } else if (!strcmp(cstring, "source.lang.swift.ref.function.constructor")) {
        return JAZEntityKindRefConstructor;
    } else if (!strcmp(cstring, "source.lang.swift.decl.function.destructor")) {
        return JAZEntityKindDeclDestructor;
    } else if (!strcmp(cstring, "source.lang.swift.ref.function.destructor")) {
        return JAZEntityKindRefDestructor;
    } else if (!strcmp(cstring, "source.lang.swift.decl.function.operator")) {
        return JAZEntityKindDeclFunctionOperator;
    } else if (!strcmp(cstring, "source.lang.swift.ref.function.operator")) {
        return JAZEntityKindRefFunctionOperator;
    } else if (!strcmp(cstring, "source.lang.swift.decl.function.subscript")) {
        return JAZEntityKindDeclSubscript;
    } else if (!strcmp(cstring, "source.lang.swift.ref.function.subscript")) {
        return JAZEntityKindRefSubscript;
    } else if (!strcmp(cstring, "source.lang.swift.decl.var.global")) {
        return JAZEntityKindDeclVarGlobal;
    } else if (!strcmp(cstring, "source.lang.swift.ref.var.global")) {
        return JAZEntityKindRefVarGlobal;
    } else if (!strcmp(cstring, "source.lang.swift.decl.var.instance")) {
        return JAZEntityKindDeclVarInstance;
    } else if (!strcmp(cstring, "source.lang.swift.ref.var.instance")) {
        return JAZEntityKindRefVarInstance;
    } else if (!strcmp(cstring, "source.lang.swift.decl.var.static")) {
        return JAZEntityKindDeclVarStatic;
    } else if (!strcmp(cstring, "source.lang.swift.ref.var.static")) {
        return JAZEntityKindRefVarStatic;
    } else if (!strcmp(cstring, "source.lang.swift.decl.var.class")) {
        return JAZEntityKindDeclVarClass;
    } else if (!strcmp(cstring, "source.lang.swift.ref.var.class")) {
        return JAZEntityKindRefVarClass;
    } else if (!strcmp(cstring, "source.lang.swift.decl.var.local")) {
        return JAZEntityKindDeclVarLocal;
    } else if (!strcmp(cstring, "source.lang.swift.ref.var.local")) {
        return JAZEntityKindRefVarLocal;
    } else if (!strcmp(cstring, "source.lang.swift.decl.class")) {
        return JAZEntityKindDeclClass;
    } else if (!strcmp(cstring, "source.lang.swift.ref.class")) {
        return JAZEntityKindRefClass;
    } else if (!strcmp(cstring, "source.lang.swift.decl.struct")) {
        return JAZEntityKindDeclStruct;
    } else if (!strcmp(cstring, "source.lang.swift.ref.struct")) {
        return JAZEntityKindRefStruct;
    } else if (!strcmp(cstring, "source.lang.swift.decl.enum")) {
        return JAZEntityKindDeclEnum;
    } else if (!strcmp(cstring, "source.lang.swift.ref.enum")) {
        return JAZEntityKindRefEnum;
    } else if (!strcmp(cstring, "source.lang.swift.decl.enumelement")) {
        return JAZEntityKindDeclEnumElement;
    } else if (!strcmp(cstring, "source.lang.swift.ref.enumelement")) {
        return JAZEntityKindRefEnumElement;
    } else if (!strcmp(cstring, "source.lang.swift.decl.protocol")) {
        return JAZEntityKindDeclProtocol;
    } else if (!strcmp(cstring, "source.lang.swift.ref.protocol")) {
        return JAZEntityKindRefProtocol;
    } else if (!strcmp(cstring, "source.lang.swift.decl.extension.struct")) {
        return JAZEntityKindDeclExtensionStruct;
    } else if (!strcmp(cstring, "source.lang.swift.decl.extension.class")) {
        return JAZEntityKindDeclExtensionClass;
    } else if (!strcmp(cstring, "source.lang.swift.decl.extension.enum")) {
        return JAZEntityKindDeclExtensionEnum;
    } else if (!strcmp(cstring, "source.lang.swift.decl.typealias")) {
        return JAZEntityKindDeclTypeAlias;
    } else if (!strcmp(cstring, "source.lang.swift.ref.typealias")) {
        return JAZEntityKindRefTypeAlias;
    } else if (!strcmp(cstring, "source.lang.swift.decl.generic_type_param")) {
        return JAZEntityKindDeclGenericTypeParam;
    } else if (!strcmp(cstring, "source.lang.swift.ref.generic_type_param")) {
        return JAZEntityKindRefGenericTypeParam;
    } else if (!strcmp(cstring, "source.lang.swift.ref.module")) {
        return JAZEntityKindRefModule;
    }
    return JAZEntityKindDeclClass;
}

NSString *generateTabs(NSUInteger numberOfTabs) {
    NSMutableString *tabs = [NSMutableString stringWithCapacity:numberOfTabs];
    for (NSUInteger indentLevel = 0; indentLevel <= numberOfTabs; indentLevel++) {
        [tabs appendString:@"\t"];
    }
    return tabs;
}

@implementation JAZEntity

- (NSString *)xmlDocs {
    return [self xmlDocsWithCurrentLevel:0];
}

- (NSString *)xmlDocsWithCurrentLevel:(NSUInteger)currentLevel {
    NSMutableString *xml = [NSMutableString string];
    if (currentLevel == 0) {
        [xml appendString:@"<jazzy>\n"];
    }
    [xml appendString:generateTabs(currentLevel)];
    [xml appendString:self.docs];
    [xml appendString:@"\n"];
    if (self.entities.count > 0) {
        NSRange closingRange = [xml rangeOfString:@"</" options:NSBackwardsSearch];
        NSString *closingString = nil;
        if (closingRange.location != NSNotFound) {
            closingRange = NSMakeRange(closingRange.location, xml.length - closingRange.location);
            closingString = [xml substringWithRange:closingRange];
            [xml deleteCharactersInRange:closingRange];
            [xml appendString:@"\n"];
        }
        for (JAZEntity *entity in self.entities) {
            [xml appendString:[entity xmlDocsWithCurrentLevel:currentLevel+1]];
        }
        if (closingRange.location != NSNotFound) {
            [xml appendString:generateTabs(currentLevel)];
            [xml appendString:closingString];
        }
    }
    if (currentLevel == 0) {
        [xml appendString:@"</jazzy>\n"];
    }
    return [xml copy];
}

@end

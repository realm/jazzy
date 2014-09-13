//
//  JAZEntity.h
//  SourceKitten
//
//  Created by JP Simard on 9/13/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, JAZEntityKind) {
    JAZEntityKindDeclFunctionFree = 0x100d97303,
    JAZEntityKindRefFunctionFree = 0x100d97328,
    JAZEntityKindDeclMethodInstance = 0x100d9734c,
    JAZEntityKindRefMethodInstance = 0x100d9737c,
    JAZEntityKindDeclMethodStatic = 0x100d973ab,
    JAZEntityKindRefMethodStatic = 0x100d973d9,
    JAZEntityKindDeclMethodClass = 0x100d97406,
    JAZEntityKindRefMethodClass = 0x100d97433,
    JAZEntityKindDeclAccessorGetter = 0x100d9745f,
    JAZEntityKindRefAccessorGetter = 0x100d9748f,
    JAZEntityKindDeclAccessorSetter = 0x100d974be,
    JAZEntityKindRefAccessorSetter = 0x100d974ee,
    JAZEntityKindDeclAccessorWillSet = 0x100d9751d,
    JAZEntityKindRefAccessorWillSet = 0x100d9754e,
    JAZEntityKindDeclAccessorDidSet = 0x100d9757e,
    JAZEntityKindRefAccessorDidSet = 0x100d975ae,
    JAZEntityKindDeclConstructor = 0x100d975dd,
    JAZEntityKindRefConstructor = 0x100d97609,
    JAZEntityKindDeclDestructor = 0x100d97634,
    JAZEntityKindRefDestructor = 0x100d9765f,
    JAZEntityKindDeclFunctionOperator = 0x100d97689,
    JAZEntityKindRefFunctionOperator = 0x100d976b2,
    JAZEntityKindDeclSubscript = 0x100d976da,
    JAZEntityKindRefSubscript = 0x100d97704,
    JAZEntityKindDeclVarGlobal = 0x100d9772d,
    JAZEntityKindRefVarGlobal = 0x100d9774f,
    JAZEntityKindDeclVarInstance = 0x100d97770,
    JAZEntityKindRefVarInstance = 0x100d97794,
    JAZEntityKindDeclVarStatic = 0x100d977b7,
    JAZEntityKindRefVarStatic = 0x100d977d9,
    JAZEntityKindDeclVarClass = 0x100d977fa,
    JAZEntityKindRefVarClass = 0x100d9781b,
    JAZEntityKindDeclVarLocal = 0x100d9783b,
    JAZEntityKindRefVarLocal = 0x100d9785c,
    JAZEntityKindDeclClass = 0x100d9787c,
    JAZEntityKindRefClass = 0x100d97899,
    JAZEntityKindDeclStruct = 0x100d978b5,
    JAZEntityKindRefStruct = 0x100d978d3,
    JAZEntityKindDeclEnum = 0x100d978f0,
    JAZEntityKindRefEnum = 0x100d9790c,
    JAZEntityKindDeclEnumElement = 0x100d97927,
    JAZEntityKindRefEnumElement = 0x100d9794a,
    JAZEntityKindDeclProtocol = 0x100d9796c,
    JAZEntityKindRefProtocol = 0x100d9798c,
    JAZEntityKindDeclExtensionStruct = 0x100d979ab,
    JAZEntityKindDeclExtensionClass = 0x100d979d3,
    JAZEntityKindDeclExtensionEnum = 0x100d979fa,
    JAZEntityKindDeclTypeAlias = 0x100d97a20,
    JAZEntityKindRefTypeAlias = 0x100d97a41,
    JAZEntityKindDeclGenericTypeParam = 0x100d97a61,
    JAZEntityKindRefGenericTypeParam = 0x100d97a8b,
    JAZEntityKindRefModule = 0x100d97ab4,
};

NSString *stringFromJAZEntityKind(JAZEntityKind kind);

JAZEntityKind JAZEntityKindFromCString(const char *cstring);

@interface JAZEntity : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *usr;
@property (nonatomic, assign) NSInteger offset;
@property (nonatomic, assign) NSInteger length;
@property (nonatomic, assign) JAZEntityKind kind;
@property (nonatomic, strong) NSArray *entities; // array of JAZEntity
@property (nonatomic, strong) NSArray *conforms; // array of JAZEntity
@property (nonatomic, copy) NSString *docs;

- (NSString *)xmlDocs;

@end

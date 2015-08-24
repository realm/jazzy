//
//  SourceKittenFramework.h
//  SourceKittenFramework
//
//  Created by JP Simard on 2015-01-02.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for SourceKittenFramework.
FOUNDATION_EXPORT double SourceKittenFrameworkVersionNumber;

//! Project version string for SourceKittenFramework.
FOUNDATION_EXPORT const unsigned char SourceKittenFrameworkVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <SourceKittenFramework/PublicHeader.h>

// Ideally this would be in a bridging header, but due to rdar://17633863, we can't have nice things.
// TODO: use clang-c's modulemap instead.
#import <SourceKittenFramework/Index.h>
#import <SourceKittenFramework/Documentation.h>
#import <SourceKittenFramework/CXCompilationDatabase.h>

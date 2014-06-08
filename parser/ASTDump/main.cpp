//
//  main.cpp
//  ASTDump
//
//  Created by JP Simard on 6/5/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#include <iostream>
#include "clang-c/Index.h"

//////////////////////////////////////////
// Print XML from translation unit
//////////////////////////////////////////

void printXMLFromTU(CXTranslationUnit tu)
{
    printf("<?xml version=\"1.0\"?>\n<jazz>");
    clang_visitChildrenWithBlock(clang_getTranslationUnitCursor(tu), ^enum CXChildVisitResult(CXCursor cursor, CXCursor parent) {
        CXComment comment = clang_Cursor_getParsedComment(cursor);
        if (clang_Comment_getKind(comment) == CXComment_FullComment) {
            printf("%s\n", clang_getCString(clang_FullComment_getAsXML(comment)));
        }
        return CXChildVisit_Recurse;
    });
    printf("</jazz>");
}

//////////////////////////////////////////
// Make translation unit from index/file
//////////////////////////////////////////

CXTranslationUnit tuFromIndexAndFile(CXIndex index, const char *filename)
{
    const char *args[] = {
        "-x",
        "objective-c",
        "-isysroot",
        "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.9.sdk"
    };
    
    int numArgs = sizeof(args) / sizeof(*args);
    
    return clang_createTranslationUnitFromSourceFile(index, filename, numArgs, args, 0, NULL);
}

//////////////////////////////////////////
// Print XML from filename
//////////////////////////////////////////

void printXMLFromFile(const char *filename)
{
    CXIndex index = clang_createIndex(0, 1);
    
    CXTranslationUnit tu = tuFromIndexAndFile(index, filename);
    
    printXMLFromTU(tu);
    
    clang_disposeTranslationUnit(tu);
    clang_disposeIndex(index);
}

//////////////////////////////////////////
// Program entry
//////////////////////////////////////////

int main(int argc, const char * argv[])
{
    printXMLFromFile(argv[1]);
    return 0;
}

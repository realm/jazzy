//
//  main.cpp
//  ASTDump
//
//  Created by JP Simard on 6/5/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#include <iostream>
#include "clang-c/Index.h"

const char *commentKindToString(CXCommentKind commentKind)
{
    switch (commentKind) {
        case CXComment_Null:
        {
            return "CXComment_Null";
        }
            break;
        case CXComment_Text:
        {
            return "CXComment_Text";
        }
            break;
        case CXComment_InlineCommand:
        {
            return "CXComment_InlineCommand";
        }
            break;
        case CXComment_HTMLStartTag:
        {
            return "CXComment_HTMLStartTag";
        }
            break;
        case CXComment_HTMLEndTag:
        {
            return "CXComment_HTMLEndTag";
        }
            break;
        case CXComment_Paragraph:
        {
            return "CXComment_Paragraph";
        }
            break;
        case CXComment_BlockCommand:
        {
            return "CXComment_BlockCommand";
        }
            break;
        case CXComment_ParamCommand:
        {
            return "CXComment_ParamCommand";
        }
            break;
        case CXComment_TParamCommand:
        {
            return "CXComment_TParamCommand";
        }
            break;
        case CXComment_VerbatimBlockCommand:
        {
            return "CXComment_VerbatimBlockCommand";
        }
            break;
        case CXComment_VerbatimBlockLine:
        {
            return "CXComment_VerbatimBlockLine";
        }
            break;
        case CXComment_VerbatimLine:
        {
            return "CXComment_VerbatimLine";
        }
            break;
        case CXComment_FullComment:
        {
            return "CXComment_FullComment";
        }
            break;
            
        default:
            break;
    }
    return "";
}

void printChildren(CXComment comment)
{
    switch (clang_Comment_getKind(comment)) {
        case CXComment_Null:
        {
            // fprintf(stderr, "null comment");
        }
            break;
        case CXComment_Text:
        {
            CXString commentText = clang_TextComment_getText(comment);
            fprintf(stderr, "comment text: %s\n", clang_getCString(commentText));
        }
            break;
        case CXComment_InlineCommand:
        {
            CXString commandName = clang_InlineCommandComment_getCommandName(comment);
            fprintf(stderr, "command name: %s\n", clang_getCString(commandName));
        }
            break;
        case CXComment_HTMLStartTag:
        {
            CXString tagName = clang_HTMLTagComment_getTagName(comment);
            fprintf(stderr, "HTMLStartTag name: %s\n", clang_getCString(tagName));
        }
            break;
        case CXComment_HTMLEndTag:
        {
            CXString tagName = clang_HTMLTagComment_getTagName(comment);
            fprintf(stderr, "HTMLEndTag name: %s\n", clang_getCString(tagName));
        }
            break;
        case CXComment_Paragraph:
        {
            // No content in this comment. Only contains children.
        }
            break;
        case CXComment_BlockCommand:
        {
            CXString commandName = clang_BlockCommandComment_getCommandName(comment);
            fprintf(stderr, "block command name: %s\n", clang_getCString(commandName));
        }
            break;
        case CXComment_ParamCommand:
        {
            CXString paramName = clang_ParamCommandComment_getParamName(comment);
            fprintf(stderr, "param command name: %s\n", clang_getCString(paramName));
        }
            break;
        case CXComment_TParamCommand:
        {
            CXString paramName = clang_TParamCommandComment_getParamName(comment);
            fprintf(stderr, "T param command name: %s\n", clang_getCString(paramName));
        }
            break;
        case CXComment_VerbatimBlockCommand:
        {
            printChildren(clang_BlockCommandComment_getParagraph(comment));
        }
            break;
        case CXComment_VerbatimBlockLine:
        {
            CXString commentText = clang_VerbatimBlockLineComment_getText(comment);
            fprintf(stderr, "verbatim block line comment text: %s\n", clang_getCString(commentText));
        }
            break;
        case CXComment_VerbatimLine:
        {
            CXString commentText = clang_VerbatimLineComment_getText(comment);
            fprintf(stderr, "verbatim comment text: %s\n", clang_getCString(commentText));
        }
            break;
        case CXComment_FullComment:
        {
            fprintf(stderr, "full comment as XML:\n%s\n", clang_getCString(clang_FullComment_getAsXML(comment)));
        }
            break;
            
        default:
            break;
    }
    
    unsigned numChildren = clang_Comment_getNumChildren(comment);
    for (unsigned idx = 0; idx < numChildren; idx++) {
        printChildren(clang_Comment_getChild(comment, idx));
    }
}

void visitTUChildren(CXTranslationUnit tu)
{
    clang_visitChildrenWithBlock(clang_getTranslationUnitCursor(tu), ^enum CXChildVisitResult(CXCursor cursor, CXCursor parent) {
        printf("%s", clang_getCString(clang_getCursorUSR(cursor)));
        return CXChildVisit_Recurse;
    });
}

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

void printXMLFromFile(const char *filename)
{
    CXIndex index = clang_createIndex(0, 1);
    
    CXTranslationUnit tu = tuFromIndexAndFile(index, filename);
    
    printXMLFromTU(tu);
    
    clang_disposeTranslationUnit(tu);
    clang_disposeIndex(index);
}

void printChildrenFromFile(const char *filename)
{
    CXIndex index = clang_createIndex(0, 1);
    
    CXTranslationUnit tu = tuFromIndexAndFile(index, filename);
    
    visitTUChildren(tu);
    
    clang_disposeTranslationUnit(tu);
    clang_disposeIndex(index);
}

int main(int argc, const char * argv[])
{
    printXMLFromFile(argv[1]);
//    printChildrenFromFile(argv[1]);
    return 0;
}

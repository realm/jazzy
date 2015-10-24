//
//  Clang+SourceKitten.swift
//  SourceKitten
//
//  Created by Thomas Goyne on 9/17/15.
//  Copyright © 2015 SourceKitten. All rights reserved.
//

struct ClangIndex {
    private let cx = clang_createIndex(0, 1)

    func open(file file: String, args: [UnsafePointer<Int8>]) -> CXTranslationUnit {
        return clang_createTranslationUnitFromSourceFile(cx,
            file,
            Int32(args.count),
            args,
            0,
            nil)
    }
}

extension CXString: CustomStringConvertible {
    func str() -> String? {
        return String.fromCString(clang_getCString(self))
    }

    public var description: String {
        return str() ?? "<null>"
    }
}

extension CXTranslationUnit {
    func cursor() -> CXCursor {
        return clang_getTranslationUnitCursor(self)
    }

    func visit(block: ((CXCursor, CXCursor) -> CXChildVisitResult)) {
        cursor().visit(block)
    }
}

extension CXCursor {
    func location() -> SourceLocation {
        var cxfile = CXFile()
        var line: UInt32 = 0
        var column: UInt32 = 0
        var offset: UInt32 = 0
        clang_getSpellingLocation(clang_getCursorLocation(self), &cxfile, &line, &column, &offset)
        return SourceLocation(file: clang_getFileName(cxfile).str() ?? "<none>",
            line: line, column: column, offset: offset)
    }

    func name() -> String {
        return clang_getCursorSpelling(self).str()!
    }

    func type() -> CXType {
        return clang_getCursorType(self)
    }

    func usr() -> String? {
        return clang_getCursorUSR(self).str()
    }

    func text() -> String {
        // Tokenize the string, then reassemble the tokens back into one string
        // This is kinda wtf but there's no way to get the raw string...
        let range = clang_getCursorExtent(self)
        var tokens = UnsafeMutablePointer<CXToken>()
        var count = UInt32(0)
        clang_tokenize(translationUnit(), range, &tokens, &count)

        func needsWhitespace(kind: CXTokenKind) -> Bool {
            return kind == CXToken_Identifier || kind == CXToken_Keyword
        }

        var str = ""
        var prevWasIdentifier = false
        for i in 0..<count {
            let type = clang_getTokenKind(tokens[Int(i)])
            if type == CXToken_Comment {
                break
            }

            if let s = tokens[Int(i)].str(translationUnit()) {
                if prevWasIdentifier && needsWhitespace(type) {
                    str += " "
                }
                str += s
                prevWasIdentifier = needsWhitespace(type)
            }
        }

        clang_disposeTokens(translationUnit(), tokens, count)
        return str
    }

    func translationUnit() -> CXTranslationUnit {
        return clang_Cursor_getTranslationUnit(self)
    }

    func visit(block: CXCursorVisitorBlock) {
        clang_visitChildrenWithBlock(self, block)
    }

    func parsedComment() -> CXComment {
        return clang_Cursor_getParsedComment(self)
    }

    func flatMap<T>(block: (CXCursor) -> T?) -> [T] {
        var ret = [T]()
        visit() { cursor, _ in
            if let val = block(cursor) {
                ret.append(val)
            }
            return CXChildVisit_Continue
        }
        return ret
    }
}

extension CXToken {
    func str(tu: CXTranslationUnit) -> String? {
        return clang_getTokenSpelling(tu, self).str()
    }
}

extension CXType {
    func name() -> String? {
        return clang_getTypeSpelling(self).str()
    }
}

extension CXComment {
    func paramName() -> String? {
        guard clang_Comment_getKind(self) == CXComment_ParamCommand else { return nil }
        return clang_ParamCommandComment_getParamName(self).str()
    }

    func paragraph() -> CXComment {
        return clang_BlockCommandComment_getParagraph(self)
    }

    func paragraphToString(kindString: String? = nil) -> [Text] {
        if kind() == CXComment_VerbatimLine {
            return [.Verbatim(clang_VerbatimLineComment_getText(self).str()!)]
        }
        if kind() == CXComment_BlockCommand  {
            var ret = [Text]()
            for i in 0..<clang_Comment_getNumChildren(self) {
                let child = clang_Comment_getChild(self, i)
                ret += child.paragraphToString()
            }
            return ret
        }

        guard kind() == CXComment_Paragraph else {
            print("not a paragraph: \(kind())")
            return []
        }

        var ret = ""
        for i in 0..<clang_Comment_getNumChildren(self) {
            let child = clang_Comment_getChild(self, i)
            if let text = clang_TextComment_getText(child).str() {
                if ret != "" {
                    ret += "\n"
                }
                ret += text
            }
            else if child.kind() == CXComment_InlineCommand {
                // @autoreleasepool etc. get parsed as commands when not in code blocks
                ret += "@" + clang_InlineCommandComment_getCommandName(child).str()!
            }
            else {
                print("not text: \(child.kind())")
            }
        }
        return [.Para(ret.stringByRemovingCommonLeadingWhitespaceFromLines(), kindString)]
    }

    func kind() -> CXCommentKind {
        return clang_Comment_getKind(self)
    }

    func commandName() -> String? {
        return clang_BlockCommandComment_getCommandName(self).str()
    }

    func count() -> UInt32 {
        return clang_Comment_getNumChildren(self)
    }

    subscript(idx: UInt32) -> CXComment {
        return clang_Comment_getChild(self, idx)
    }
}

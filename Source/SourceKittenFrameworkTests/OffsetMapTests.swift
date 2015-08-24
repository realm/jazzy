//
//  OffsetMapTests.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-03.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import Foundation
import SourceKittenFramework
import XCTest

class OffsetMapTests: XCTestCase {
    func testOffsetMapContainsDeclarationOffsetWithDocCommentButNotAlreadyDocumented() {
        // Subscripts aren't parsed by SourceKit, so OffsetMap should contain its offset.
        let file = File(contents:
            "struct VoidStruct {\n/// Returns or sets Void.\nsubscript(key: String) -> () {\n" +
            "get { return () }\nset {}\n}\n}"
        )
        let documentedTokenOffsets = file.contents.documentedTokenOffsets(SyntaxMap(file: file))
        let response = file.processDictionary(Request.EditorOpen(file).send(), cursorInfoRequest: nil)
        let offsetMap = file.generateOffsetMap(documentedTokenOffsets, dictionary: response)
        XCTAssertEqual(offsetMap, [46: 7], "should generate correct offset map of [(declaration offset): (parent offset)]")
    }

    func testOffsetMapDoesntContainAlreadyDocumentedDeclarationOffset() {
        // Struct declarations are parsed by SourceKit, so OffsetMap shouldn't contain its offset.
        let file = File(contents: "/// Doc Comment\nstruct DocumentedStruct {}")
        let documentedTokenOffsets = file.contents.documentedTokenOffsets(SyntaxMap(file: file))
        let response = file.processDictionary(Request.EditorOpen(file).send(), cursorInfoRequest: nil)
        let offsetMap = file.generateOffsetMap(documentedTokenOffsets, dictionary: response)
        XCTAssertEqual(offsetMap, [:], "should generate empty offset map")
    }
}

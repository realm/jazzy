//
//  StringTests.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-03.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import Foundation
import SourceKittenFramework
import SwiftXPC
import XCTest

class StringTests: XCTestCase {
    func testIsSwiftFile() {
        let good = ["good.swift"]
        let bad = [
            "bad.swift.",
            ".swift.bad",
            "badswift",
            "bad.Swift"
        ]
        XCTAssertEqual((good + bad).filter({ $0.isSwiftFile() }), good, "should parse Swift files in an Array")
    }

    func testIsObjectiveCHeaderFile() {
        let good = [
            "good.h",
            "good.hpp",
            "good.hh"
        ]
        let bad = [
            "bad.h.",
            ".hpp.bad",
            "badshh",
            "bad.H"
        ]
        XCTAssertEqual((good + bad).filter({ $0.isObjectiveCHeaderFile() }), good, "should parse Objective-C header files in an Array")
    }

    func testAbsolutePath() {
        XCTAssert(("LICENSE".absolutePathRepresentation() as NSString).absolutePath, "absolutePathRepresentation() of a relative path should be an absolute path")
        XCTAssertEqual(__FILE__.absolutePathRepresentation(), __FILE__, "absolutePathRepresentation() should return the caller if it's already an absolute path")
    }

    func testIsTokenDocumentable() {
        let source = "struct A { subscript(key: String) -> Void { return () } }"
        let actual = SyntaxMap(file: File(contents: source)).tokens.filter {
            source.isTokenDocumentable($0)
        }
        let expected = [
            SyntaxToken(type: SyntaxKind.Identifier.rawValue, offset: 7, length: 1), // `A`
            SyntaxToken(type: SyntaxKind.Keyword.rawValue, offset: 11, length: 9),   // `subscript`
            SyntaxToken(type: SyntaxKind.Identifier.rawValue, offset: 21, length: 3) // `key`
        ]
        XCTAssertEqual(actual, expected, "should detect documentable tokens")
    }

    func testParseDeclaration() {
        let dict = [
            "key.kind": "source.lang.swift.decl.class",
            "key.offset": Int64(24),
            "key.bodyoffset": Int64(32),
            "key.annotated_decl": "",
            "key.typename": "ClassA.Type"
        ] as XPCDictionary
        // This string is a regression test for https://github.com/jpsim/SourceKitten/issues/35 .
        let file = File(contents: "/**\n　ほげ\n*/\nclass ClassA {\n}\n")
        XCTAssertEqual("class ClassA", file.parseDeclaration(dict)!, "should extract declaration from source text")
    }

    func testGenerateDocumentedTokenOffsets() {
        let fileContents = "/// Comment\nlet global = 0"
        let syntaxMap = SyntaxMap(file: File(contents: fileContents))
        XCTAssertEqual(fileContents.documentedTokenOffsets(syntaxMap), [16], "should generate documented token offsets")
    }

    func testDocumentedTokenOffsetsWithSubscript() {
        let file = File(path: fixturesDirectory + "Subscript.swift")!
        let syntaxMap = SyntaxMap(file: file)
        XCTAssertEqual(file.contents.documentedTokenOffsets(syntaxMap), [54], "should generate documented token offsets")
    }

    func testGenerateDocumentedTokenOffsetsEmpty() {
        let fileContents = "// Comment\nlet global = 0"
        let syntaxMap = SyntaxMap(file: File(contents: fileContents))
        XCTAssertEqual(fileContents.documentedTokenOffsets(syntaxMap).count, 0, "shouldn't detect any documented token offsets when there are none")
    }

    func testSubstringWithByteRange() {
        XCTAssertEqual(("😄123" as String).substringWithByteRange(start: 0, length: 4)!, "😄" as String)
        XCTAssertEqual(("😄123" as String).substringWithByteRange(start: 4, length: 1)!, "1" as String)
    }
}

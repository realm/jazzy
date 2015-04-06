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
        let string = "😄123"
        XCTAssertEqual(string.substringWithByteRange(start: 0, length: 4)!, "😄")
        XCTAssertEqual(string.substringWithByteRange(start: 4, length: 1)!, "1")
    }

    func testByteRangeToStringRange() {
        let string = "😄123"
        XCTAssertEqual(string.byteRangeToStringRange(start: 0, end: 4)!, string.startIndex..<advance(string.startIndex, 1))
        XCTAssertEqual(string.byteRangeToStringRange(start: 4, end: 5)!, advance(string.startIndex, 1)..<advance(string.startIndex, 2))
    }

    func testSubstringLinesWithByteRange() {
        let string = "😄\n123"
        XCTAssertEqual(string.substringLinesWithByteRange(start: 0, end: 0)!, "😄\n")
        XCTAssertEqual(string.substringLinesWithByteRange(start: 0, end: 5)!, "😄\n")
        XCTAssertEqual(string.substringLinesWithByteRange(start: 0, end: 6)!, string)
        XCTAssertEqual(string.substringLinesWithByteRange(start: 6, end: 6)!, "123")
    }

    func testLineRangeWithByteRange() {
        let string = "😄\n123"
        XCTAssert(string.lineRangeWithByteRange(start: 0, end: 0)! == (1, 1))
        XCTAssert(string.lineRangeWithByteRange(start: 0, end: 5)! == (1, 2))
        XCTAssert(string.lineRangeWithByteRange(start: 0, end: 6)! == (1, 2))
        XCTAssert(string.lineRangeWithByteRange(start: 6, end: 6)! == (2, 2))
    }
}

typealias LineRangeType = (start: Int, end: Int)

func ==(lhs: LineRangeType, rhs: LineRangeType) -> Bool {
    return lhs.start == rhs.start && lhs.end == rhs.end
}

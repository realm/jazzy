//
//  StringTests.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-03.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import Foundation
import SourceKittenFramework
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

    func testParseLineBreaks() {
        XCTAssertEqual("a\nbc\nd\n".lineBreaks(), [1, 4, 6], "should parse line breaks")
    }

    func testFilteredSubstring() {
        let expected = "public func myFunc()"
        let end = countElements(expected) + 4 // 4 == 2 spaces before + 2 characters after (until newline)
        let actual = ("  \(expected) {\n}" as NSString).filteredSubstring(0, end: end)
        XCTAssertEqual(expected, actual, "should extract function declaration from source text")
    }

    func testGenerateDocumentedTokenOffsets() {
        let fileContents = "/// Comment\nlet global = 0"
        let syntaxMap = SyntaxMap(file: File(contents: fileContents))
        XCTAssertEqual(fileContents.documentedTokenOffsets(syntaxMap), [16], "should generate documented token offsets")
    }

    func testGenerateDocumentedTokenOffsetsEmpty() {
        let fileContents = "// Comment\nlet global = 0"
        let syntaxMap = SyntaxMap(file: File(contents: fileContents))
        XCTAssertEqual(fileContents.documentedTokenOffsets(syntaxMap).count, 0, "shouldn't detect any documented token offsets when there are none")
    }

    func testIsSwiftDeclarationKind() {
        let positives = ([
            .ClassMethod,
            .ClassVariable,
            .Class,
            .Constructor,
            .Destructor,
            .Global,
            .EnumElement,
            .Enum,
            .Extension,
            .FreeFunction,
            .Method,
            .InstanceVariable,
            .LocalVariable,
            .Parameter,
            .Protocol,
            .StaticMethod,
            .StaticVariable,
            .Struct,
            .Subscript,
            .TypeAlias
        ] as [SwiftDeclarationKind]).map { $0.rawValue }
        for positive in positives {
            XCTAssertTrue(isSwiftDeclarationKind(positive), "\(positive) should be considered a declaration kind")
        }
        let negatives: [String?] = [nil, "", ".source.lang.swift.decl."]
        for negative in negatives {
            XCTAssertFalse(isSwiftDeclarationKind(negative), "\(negative) shouldn't be considered a declaration kind")
        }
    }
}

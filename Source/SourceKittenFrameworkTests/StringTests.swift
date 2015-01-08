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

//
//  SyntaxTests.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-03.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import Foundation
import SourceKittenFramework
import SwiftXPC
import XCTest

func compareSyntax(file: File, expectedTokens: [(SyntaxKind, Int, Int)]) {
    let expectedSyntaxMap = SyntaxMap(tokens: expectedTokens.map { tokenTuple in
        return SyntaxToken(type: tokenTuple.0.rawValue, offset: tokenTuple.1, length: tokenTuple.2)
    })
    let syntaxMap = SyntaxMap(file: file)
    XCTAssertEqual(syntaxMap, expectedSyntaxMap, "should generate expected syntax map")

    let syntaxJSON = syntaxMap.description
    let jsonArray = NSJSONSerialization.JSONObjectWithData(syntaxJSON.dataUsingEncoding(NSUTF8StringEncoding)!, options: nil, error: nil) as! NSArray?
    XCTAssertNotNil(jsonArray, "JSON should be propery parsed")
    XCTAssertEqual(jsonArray!, expectedSyntaxMap.tokens.map { $0.dictionaryValue }, "JSON should match expected syntax")
}

class SyntaxTests: XCTestCase {
    func testPrintEmptySyntax() {
        XCTAssertEqual(SyntaxMap(file: File(contents: "")).description, "[\n\n]", "should print empty syntax")
    }

    func testGenerateSameSyntaxMapFileAndContents() {
        let fileContents = NSString(contentsOfFile: __FILE__, encoding: NSUTF8StringEncoding, error: nil) as String!
        XCTAssertEqual(SyntaxMap(file: File(path: __FILE__)!),
            SyntaxMap(file: File(contents: fileContents)),
            "should generate the same syntax map for a file as raw text")
    }

    func testSubscript() {
        compareSyntax(File(contents: "struct A { subscript(index: Int) -> () { return () } }"),
            [
                (.Keyword, 0, 6),
                (.Identifier, 7, 1),
                (.Keyword, 11, 9),
                (.Identifier, 21, 5),
                (.Typeidentifier, 28, 3),
                (.Keyword, 41, 6)
            ]
        )
    }

    func testSyntaxMapPrintValidJSON() {
        compareSyntax(File(contents: "import Foundation // Hello World!"),
            [
                (.Keyword, 0, 6),
                (.Identifier, 7, 10),
                (.Comment, 18, 15)
            ]
        )
    }
}

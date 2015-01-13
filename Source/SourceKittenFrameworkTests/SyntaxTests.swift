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

class SyntaxTests: XCTestCase {
    func testPrintEmptySyntax() {
        XCTAssertEqual(SyntaxMap(file: File(contents: "")).description, "[\n\n]", "should print empty syntax")
    }

    func testGenerateSameSyntaxMapFileAndContents() {
        let fileContents = NSString(contentsOfFile: __FILE__, encoding: NSUTF8StringEncoding, error: nil)!
        XCTAssertEqual(SyntaxMap(file: File(path: __FILE__)!),
            SyntaxMap(file: File(contents: fileContents)),
            "should generate the same syntax map for a file as raw text")
    }

    func testSyntaxMapPrintValidJSON() {
        let expectedSyntaxMap = SyntaxMap(tokens: [
            SyntaxToken(type: SyntaxKind.Keyword.rawValue, offset: 0, length: 6),
            SyntaxToken(type: SyntaxKind.Identifier.rawValue, offset: 7, length: 10),
            SyntaxToken(type: SyntaxKind.Comment.rawValue, offset: 18, length: 15)
        ])
        let syntaxMap = SyntaxMap(file: File(contents: "import Foundation // Hello World!"))
        XCTAssertEqual(syntaxMap, expectedSyntaxMap, "should generate expected syntax map")

        let syntaxJSON = syntaxMap.description
        var error: NSError? = nil
        let jsonArray = NSJSONSerialization.JSONObjectWithData(syntaxJSON.dataUsingEncoding(NSUTF8StringEncoding)!, options: nil, error: &error) as NSArray?
        XCTAssertNil(error, "JSON should be propery parsed")
        XCTAssertNotNil(jsonArray, "JSON should be propery parsed")
        if let jsonArray = jsonArray {
            XCTAssertEqual(jsonArray, expectedSyntaxMap.tokens.map { $0.dictionaryValue }, "JSON should match expected syntax")
        }
    }
}

//
//  SwiftDocsTests.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-03.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import Foundation
import SourceKittenFramework
import XCTest

func compareDocsWithFixturesName(name: String) {
    let swiftFilePath = fixturesDirectory + name + ".swift"
    let jsonFilePath  = fixturesDirectory + name + ".json"

    let docs = SwiftDocs(file: File(path: swiftFilePath)!, arguments: ["-j4", swiftFilePath])

    let escapedFixturesDirectory = fixturesDirectory.stringByReplacingOccurrencesOfString("/", withString: "\\/")
    let comparisonString = docs.description.stringByReplacingOccurrencesOfString(escapedFixturesDirectory, withString: "")

    func docsObject(docsString: String) -> NSDictionary {
        return try! NSJSONSerialization.JSONObjectWithData(docsString.dataUsingEncoding(NSUTF8StringEncoding)!, options: []) as! NSDictionary
    }

    XCTAssertEqual(
        docsObject(comparisonString),
        docsObject(File(path: jsonFilePath)!.contents),
        "should generate expected docs for Swift file"
    )
}

class SwiftDocsTests: XCTestCase {
    func testSubscript() {
        compareDocsWithFixturesName("Subscript")
    }

    func testBicycle() {
        compareDocsWithFixturesName("Bicycle")
    }

    func testParseFullXMLDocs() {
        let xmlDocsString = "<Type file=\"file\" line=\"1\" column=\"2\"><Name>name</Name><USR>usr</USR><Declaration>declaration</Declaration><Abstract><Para>discussion</Para></Abstract><Parameters><Parameter><Name>param1</Name><Direction isExplicit=\"0\">in</Direction><Discussion><Para>param1_discussion</Para></Discussion></Parameter></Parameters><ResultDiscussion><Para>result_discussion</Para></ResultDiscussion></Type>"
        let parsed = parseFullXMLDocs(xmlDocsString)!
        let expected: NSDictionary = [
            "key.doc.type": "Type",
            "key.doc.file": "file",
            "key.doc.line": 1,
            "key.doc.column": 2,
            "key.doc.name": "name",
            "key.doc.usr": "usr",
            "key.doc.declaration": "declaration",
            "key.doc.parameters": [[
                "name": "param1",
                "discussion": [["Para": "param1_discussion"]]
            ]],
            "key.doc.result_discussion": [["Para": "result_discussion"]]
        ]
        XCTAssertEqual(toAnyObject(parsed), expected)
    }
}

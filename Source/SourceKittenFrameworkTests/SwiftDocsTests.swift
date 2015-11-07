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

func compareJSONStringWithFixturesName(name: String, jsonString: String) {
    func jsonValue(jsonString: String) -> AnyObject {
        let data = jsonString.dataUsingEncoding(NSUTF8StringEncoding)!
        let result = try! NSJSONSerialization.JSONObjectWithData(data, options: [])
        return (result as? NSDictionary) ?? (result as! NSArray)
    }
    let firstValue = jsonValue(jsonString)
    let secondValue = jsonValue(File(path: fixturesDirectory + name + ".json")!.contents)
    let message = "output should match expected fixture"
    if let firstValue = firstValue as? NSDictionary, secondValue = secondValue as? NSDictionary {
        XCTAssertEqual(firstValue, secondValue, message)
    } else if let firstValue = firstValue as? NSArray, secondValue = secondValue as? NSArray {
        XCTAssertEqual(firstValue, secondValue, message)
    } else {
        XCTFail("output didn't match fixture type")
    }
}

func compareDocsWithFixturesName(name: String) {
    let swiftFilePath = fixturesDirectory + name + ".swift"
    let docs = SwiftDocs(file: File(path: swiftFilePath)!, arguments: ["-j4", swiftFilePath])

    let escapedFixturesDirectory = fixturesDirectory.stringByReplacingOccurrencesOfString("/", withString: "\\/")
    let comparisonString = String(docs).stringByReplacingOccurrencesOfString(escapedFixturesDirectory, withString: "")
    compareJSONStringWithFixturesName(name, jsonString: comparisonString)
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
            "key.usr": "usr",
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

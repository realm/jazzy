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
        return NSJSONSerialization.JSONObjectWithData(docsString.dataUsingEncoding(NSUTF8StringEncoding)!, options: nil, error: nil) as NSDictionary
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
}

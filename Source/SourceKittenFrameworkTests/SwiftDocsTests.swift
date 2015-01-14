//
//  SwiftDocsTests.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-03.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import Foundation
import SourceKittenFramework
import SwiftXPC
import XCTest

class SwiftDocsTests: XCTestCase {
    func testSingleSwiftFileDocs() {
        let docs = SwiftDocs(file: File(path: fixturesDirectory + "Bicycle.swift")!, arguments: ["-j4", fixturesDirectory + "Bicycle.swift"])
        let escapedFixturesDirectory = fixturesDirectory.stringByReplacingOccurrencesOfString("/", withString: "\\/")
        let comparisonString = (docs.description + "\n").stringByReplacingOccurrencesOfString(escapedFixturesDirectory, withString: "")
        XCTAssertEqual(comparisonString, File(path: fixturesDirectory + "Bicycle.json")?.contents as String, "should generate expected docs for Swift file")
    }
}

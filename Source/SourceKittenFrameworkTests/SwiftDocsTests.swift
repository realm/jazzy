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
        let comparisonString = (docs.description + "\n").stringByReplacingOccurrencesOfString(escapedFixturesDirectory, withString: "") as NSString
        let expected = File(path: fixturesDirectory + "Bicycle.json")!.contents
        let actualDocsObject = NSJSONSerialization.JSONObjectWithData(comparisonString.dataUsingEncoding(NSUTF8StringEncoding)!, options: nil, error: nil)! as NSDictionary
        let expectedDocsObject = NSJSONSerialization.JSONObjectWithData(expected.dataUsingEncoding(NSUTF8StringEncoding)!, options: nil, error: nil)! as NSDictionary
        XCTAssertEqual(actualDocsObject, expectedDocsObject, "should generate expected docs for Swift file")
    }
}

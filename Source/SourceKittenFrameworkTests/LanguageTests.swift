//
//  LanguageTests.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-03.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import SourceKittenFramework
import XCTest

class LanguageTests: XCTestCase {
    func testParseSwiftFilesInArray() {
        let good = ["good.swift"]
        let bad = [
            "bad.swift.",
            ".swift.bad",
            "badswift",
            "bad.Swift"
        ]
        XCTAssertEqual(swiftFilesFromArray(good + bad), good, "should parse Swift files in an Array")
    }
}

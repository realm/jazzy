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
        let docs = SwiftDocs(file: File(path: __FILE__)!, arguments: ["-j4", __FILE__])
        XCTAssertEqual(docs.docsDictionary.count, 4, "should generate docs for a single Swift file") // substructure, offset, diagnostic_stage, length
    }
}

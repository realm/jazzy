//
//  StructureTests.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-03.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import Foundation
import SourceKittenFramework
import SwiftXPC
import XCTest

class StructureTests: XCTestCase {
    func testPrintEmptyStructure() {
        let expected = [
            "key.substructure": [],
            "key.offset": 0,
            "key.length": 0,
            "key.diagnostic_stage": "source.diagnostic.stage.swift.parse"
        ] as NSDictionary
        let structure = Structure(file: File(contents: ""))
        XCTAssertEqual(toAnyObject(structure.dictionary), expected, "should generate expected structure")
    }

    func testGenerateSameStructureFileAndContents() {
        let fileContents = NSString(contentsOfFile: __FILE__, encoding: NSUTF8StringEncoding, error: nil)!
        XCTAssertEqual(Structure(file: File(path: __FILE__)!),
            Structure(file: File(contents: fileContents)),
            "should generate the same structure for a file as raw text")
    }

    func testStructurePrintValidJSON() {
        let structure = Structure(file: File(contents: "struct A { func b() {} }"))
        let expectedStructure = [
            "key.substructure": [
                [
                    "key.kind": "source.lang.swift.decl.struct",
                    "key.offset": 0,
                    "key.nameoffset": 7,
                    "key.namelength": 1,
                    "key.bodyoffset": 10,
                    "key.bodylength": 13,
                    "key.length": 24,
                    "key.substructure": [
                        [
                            "key.kind": "source.lang.swift.decl.function.method.instance",
                            "key.offset": 11,
                            "key.nameoffset": 16,
                            "key.namelength": 3,
                            "key.bodyoffset": 21,
                            "key.bodylength": 0,
                            "key.length": 11,
                            "key.substructure": [
                                
                            ],
                            "key.name": "b()"
                        ]
                    ],
                    "key.name": "A"
                ]
            ],
            "key.offset": 0,
            "key.diagnostic_stage": "source.diagnostic.stage.swift.parse",
            "key.length": 24
        ]
        XCTAssertEqual(toAnyObject(structure.dictionary), expectedStructure, "should generate expected structure")

        let structureJSON = structure.description
        var error: NSError? = nil
        let jsonDictionary = NSJSONSerialization.JSONObjectWithData(structureJSON.dataUsingEncoding(NSUTF8StringEncoding)!, options: nil, error: &error) as NSDictionary?
        XCTAssertNil(error, "JSON should be propery parsed")
        XCTAssertNotNil(jsonDictionary, "JSON should be propery parsed")
        if let jsonDictionary = jsonDictionary {
            XCTAssertEqual(jsonDictionary, expectedStructure, "JSON should match expected structure")
        }
    }
}

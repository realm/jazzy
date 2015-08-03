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
        let expected: NSDictionary = [
            "key.offset": 0,
            "key.length": 0,
            "key.diagnostic_stage": "source.diagnostic.stage.swift.parse"
        ]
        let structure = Structure(file: File(contents: ""))
        XCTAssertEqual(toAnyObject(structure.dictionary), expected, "should generate expected structure")
    }

    func testGenerateSameStructureFileAndContents() {
        let fileContents = try! NSString(contentsOfFile: __FILE__, encoding: NSUTF8StringEncoding) as String!
        XCTAssertEqual(Structure(file: File(path: __FILE__)!),
            Structure(file: File(contents: fileContents)),
            "should generate the same structure for a file as raw text")
    }

    func testEnum() {
        let structure = Structure(file: File(contents: "enum MyEnum { case First }"))
        let expectedStructure: NSDictionary = [
            "key.substructure": [
                [
                    "key.kind": "source.lang.swift.decl.enum",
                    "key.accessibility": "source.lang.swift.accessibility.internal",
                    "key.offset": 0,
                    "key.nameoffset": 5,
                    "key.namelength": 6,
                    "key.bodyoffset": 13,
                    "key.bodylength": 12,
                    "key.length": 26,
                    "key.substructure": [
                    // TODO: Uncomment this once rdar://18845613 is fixed.
                    //    [
                    //        "key.kind": "source.lang.swift.decl.enumelement",
                    //        "key.accessibility": "source.lang.swift.accessibility.internal",
                    //        "key.name": "First"
                    //    ]
                    ],
                    "key.name": "MyEnum"
                ]
            ],
            "key.offset": 0,
            "key.diagnostic_stage": "source.diagnostic.stage.swift.parse",
            "key.length": 26
        ]
        XCTAssertEqual(toAnyObject(structure.dictionary), expectedStructure, "should generate expected structure")
    }

    func testStructurePrintValidJSON() {
        let structure = Structure(file: File(contents: "struct A { func b() {} }"))
        let expectedStructure: NSDictionary = [
            "key.substructure": [
                [
                    "key.kind": "source.lang.swift.decl.struct",
                    "key.accessibility": "source.lang.swift.accessibility.internal",
                    "key.offset": 0,
                    "key.nameoffset": 7,
                    "key.namelength": 1,
                    "key.bodyoffset": 10,
                    "key.bodylength": 13,
                    "key.length": 24,
                    "key.substructure": [
                        [
                            "key.kind": "source.lang.swift.decl.function.method.instance",
                            "key.accessibility": "source.lang.swift.accessibility.internal",
                            "key.offset": 11,
                            "key.nameoffset": 16,
                            "key.namelength": 3,
                            "key.bodyoffset": 21,
                            "key.bodylength": 0,
                            "key.length": 11,
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
        do {
            let jsonDictionary = try NSJSONSerialization.JSONObjectWithData(structureJSON.dataUsingEncoding(NSUTF8StringEncoding)!, options: []) as? NSDictionary
            XCTAssertNotNil(jsonDictionary, "JSON should be propery parsed")
            if let jsonDictionary = jsonDictionary {
                XCTAssertEqual(jsonDictionary, expectedStructure, "JSON should match expected structure")
            }
        } catch {
            XCTFail("JSON should be propery parsed")
        }
    }
}

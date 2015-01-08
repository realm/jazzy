//
//  ModuleTests.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-07.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import Foundation
import SourceKittenFramework
import XCTest

class ModuleTests: XCTestCase {
    func testCreateSwiftModuleFromXcodeBuiltArguments() {
        let modelFromNoArguments = Module(xcodeBuildArguments: [])
        XCTAssert(modelFromNoArguments == nil, "model initialization without any xcodebuild arguments should fail")
    }

    func testSourceKittenFrameworkDocsAreValidJSON() {
        let xcodeProjectRoot = __FILE__.stringByDeletingLastPathComponent.stringByDeletingLastPathComponent.stringByDeletingLastPathComponent
        let xcodeBuildArguments = ["-workspace", "SourceKitten.xcworkspace", "-scheme", "SourceKittenFramework"]
        let sourceKittenModule = Module(xcodeBuildArguments: xcodeBuildArguments, moduleName: nil, inPath: xcodeProjectRoot)!
        let docsJSON = sourceKittenModule.docs.description
        var error: NSError? = nil
        let jsonArray = NSJSONSerialization.JSONObjectWithData(docsJSON.dataUsingEncoding(NSUTF8StringEncoding)!, options: nil, error: &error) as NSArray?
        XCTAssertNil(error, "JSON should be propery parsed")
        XCTAssertNotNil(jsonArray, "JSON should be propery parsed")
    }
}

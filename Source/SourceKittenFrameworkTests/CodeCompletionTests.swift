//
//  CodeCompletionTests.swift
//  SourceKitten
//
//  Created by JP Simard on 9/3/15.
//  Copyright © 2015 SourceKitten. All rights reserved.
//

import SourceKittenFramework
import SwiftXPC
import XCTest

class CodeCompletionTests: XCTestCase {
    func testSimpleCodeCompletion() {
        let file = "\(NSUUID().UUIDString).swift"
        let completionItems = CodeCompletionItem.parseResponse(
            Request.CodeCompletionRequest(file: file, contents: "0.", offset: 2,
                arguments: ["-c", file, "-sdk", sdkPath()]).send())
        compareJSONStringWithFixturesName("SimpleCodeCompletion",
            jsonString: String(completionItems))
    }
}

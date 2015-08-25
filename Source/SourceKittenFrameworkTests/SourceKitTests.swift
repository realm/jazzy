//
//  SourceKitTests.swift
//  SourceKitten
//
//  Created by JP Simard on 7/15/15.
//  Copyright © 2015 SourceKitten. All rights reserved.
//

import SourceKittenFramework
import XCTest

private func run(executable: String, arguments: [String]) -> String? {
    let task = NSTask()
    task.launchPath = executable
    task.arguments = arguments

    let pipe = NSPipe()
    task.standardOutput = pipe

    task.launch()

    let file = pipe.fileHandleForReading
    let output = NSString(data: file.readDataToEndOfFile(), encoding: NSUTF8StringEncoding)
    file.closeFile()
    return output as String?
}

private func sourcekitStringsStartingWith(pattern: String) -> Set<String> {
    let sourceKitServicePath = (((run("/usr/bin/xcrun", arguments: ["-f", "swiftc"])! as NSString)
        .stringByDeletingLastPathComponent as NSString)
        .stringByDeletingLastPathComponent as NSString)
        .stringByAppendingPathComponent("lib/sourcekitd.framework/XPCServices/SourceKitService.xpc/Contents/MacOS/SourceKitService")
    let strings = run("/usr/bin/strings", arguments: [sourceKitServicePath])
    return Set(strings!.componentsSeparatedByString("\n").filter { string in
        return string.rangeOfString(pattern)?.startIndex == string.startIndex
    })
}

class SourceKitTests: XCTestCase {

    func testSyntaxKinds() {
        let expected: [SyntaxKind] = [
            .Argument,
            .AttributeBuiltin,
            .AttributeID,
            .BuildconfigID,
            .BuildconfigKeyword,
            .Comment,
            .CommentMark,
            .CommentURL,
            .DocComment,
            .DocCommentField,
            .Identifier,
            .Keyword,
            .Number,
            .Parameter,
            .Placeholder,
            .String,
            .StringInterpolationAnchor,
            .Typeidentifier
        ]
        XCTAssertEqual(
            sourcekitStringsStartingWith("source.lang.swift.syntaxtype."),
            Set(expected.map { $0.rawValue })
        )
    }

    func testSwiftDeclarationKind() {
        let expected: [SwiftDeclarationKind] = [
            .Class,
            .Enum,
            .Enumcase,
            .Enumelement,
            .Extension,
            .ExtensionClass,
            .ExtensionEnum,
            .ExtensionProtocol,
            .ExtensionStruct,
            .FunctionAccessorAddress,
            .FunctionAccessorDidset,
            .FunctionAccessorGetter,
            .FunctionAccessorMutableaddress,
            .FunctionAccessorSetter,
            .FunctionAccessorWillset,
            .FunctionConstructor,
            .FunctionDestructor,
            .FunctionFree,
            .FunctionMethodClass,
            .FunctionMethodInstance,
            .FunctionMethodStatic,
            .FunctionOperator,
            .FunctionSubscript,
            .GenericTypeParam,
            .Protocol,
            .Struct,
            .Typealias,
            .VarClass,
            .VarGlobal,
            .VarInstance,
            .VarLocal,
            .VarParameter,
            .VarStatic
        ]
        XCTAssertEqual(
            sourcekitStringsStartingWith("source.lang.swift.decl."),
            Set(expected.map { $0.rawValue })
        )
    }
}

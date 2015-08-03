//
//  ClangTranslationUnit.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-12.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

/// Represents a group of CXTranslationUnits.
public struct ClangTranslationUnit {
    /// Array of CXTranslationUnits.
    private let clangTranslationUnits: [CXTranslationUnit]

    /**
    Create a ClangTranslationUnit by passing Objective-C header files and clang compiler arguments.

    - parameter headerFiles:       Objective-C header files to document.
    - parameter compilerArguments: Clang compiler arguments.
    */
    public init(headerFiles: [String], compilerArguments: [String]) {
        let cStringCompilerArguments = compilerArguments.map { ($0 as NSString).UTF8String }
        let clangIndex = clang_createIndex(0, 1)
        clangTranslationUnits = headerFiles.map { file in
            return clang_createTranslationUnitFromSourceFile(clangIndex,
                file,
                Int32(cStringCompilerArguments.count),
                cStringCompilerArguments,
                0,
                nil)
        }
    }

    /**
    Failable initializer to create a ClangTranslationUnit by passing an array of Objective-C header
    files followed by `xcodebuild` arguments. Optionally pass in a `path`.

    - parameter headerFilesAndXcodeBuildArguments: Array of Objective-C header files followed by `xcodebuild` arguments.
    - parameter path:                              Path to run `xcodebuild` from. Uses current path by default.
    */
    public init?(headerFilesAndXcodeBuildArguments: [String], inPath path: String = NSFileManager.defaultManager().currentDirectoryPath) {
        let (headerFiles, xcodebuildArguments) = parseHeaderFilesAndXcodebuildArguments(headerFilesAndXcodeBuildArguments)
        self.init(headerFiles: headerFiles, xcodeBuildArguments: xcodebuildArguments, inPath: path)
    }

    /**
    Failable initializer to create a ClangTranslationUnit by passing Objective-C header files and
    `xcodebuild` arguments. Optionally pass in a `path`.

    - parameter headerFiles:         Objective-C header files to document.
    - parameter xcodeBuildArguments: The arguments necessary pass in to `xcodebuild` to link these header files.
    - parameter path:                Path to run `xcodebuild` from. Uses current path by default.
    */
    public init?(headerFiles: [String], xcodeBuildArguments: [String], inPath path: String = NSFileManager.defaultManager().currentDirectoryPath) {
        let xcodeBuildOutput = runXcodeBuild(xcodeBuildArguments + ["-dry-run"], inPath: path) ?? ""
        guard let clangArguments = parseCompilerArguments(xcodeBuildOutput, language: .ObjC, moduleName: nil) else {
            fputs("could not parse compiler arguments\n", stderr)
            fputs("\(xcodeBuildOutput)\n", stderr)
            return nil
        }
        self.init(headerFiles: headerFiles, compilerArguments: clangArguments)
    }
}

// MARK: CustomStringConvertible

extension ClangTranslationUnit: CustomStringConvertible {
    /// A textual XML representation of `ClangTranslationUnit`.
    public var description: String {
        let commentXMLs = "\n".join(clangTranslationUnits.map({commentXML($0)}).reduce([], combine: +))
        return "<?xml version=\"1.0\"?>\n<sourcekitten>\n" + commentXMLs + "\n</sourcekitten>"
    }
}

// MARK: Helpers

/**
Returns an array of XML comments by iterating over a Clang translation unit.

- parameter translationUnit: Clang translation unit created from Clang index, file path and compiler arguments.

- returns: An array of XML comments by iterating over a Clang translation unit.
*/
public func commentXML(translationUnit: CXTranslationUnit) -> [String] {
    var commentXMLs = [String]()
    clang_visitChildrenWithBlock(clang_getTranslationUnitCursor(translationUnit)) { cursor, _ in
        if let commentXML = String.fromCString(clang_getCString(clang_FullComment_getAsXML(clang_Cursor_getParsedComment(cursor)))) {
            commentXMLs.append(commentXML)
        }
        return CXChildVisit_Recurse
    }
    return commentXMLs
}

/**
Extracts Objective-C header files and `xcodebuild` arguments from an array of header files followed by `xcodebuild` arguments.

- parameter sourcekittenArguments: Array of Objective-C header files followed by `xcodebuild` arguments.

- returns: Tuple of header files and xcodebuild arguments.
*/
public func parseHeaderFilesAndXcodebuildArguments(sourcekittenArguments: [String]) -> (headerFiles: [String], xcodebuildArguments: [String]) {
    var xcodebuildArguments = sourcekittenArguments
    var headerFiles = [String]()
    while let headerFile = xcodebuildArguments.first where headerFile.isObjectiveCHeaderFile() {
        headerFiles.append(headerFile.absolutePathRepresentation())
        xcodebuildArguments.removeAtIndex(0)
    }
    return (headerFiles, xcodebuildArguments)
}

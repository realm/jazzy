//
//  SourceLocation.swift
//  SourceKitten
//
//  Created by JP Simard on 10/27/15.
//  Copyright © 2015 SourceKitten. All rights reserved.
//

public struct SourceLocation {
    let file: String
    let line: UInt32
    let column: UInt32
    let offset: UInt32

    public func rangeToEndLocation(end: SourceLocation) -> NSRange {
        return NSRange(location: Int(offset), length: Int(end.offset - offset))
    }
}

extension SourceLocation {
    init(clangLocation: CXSourceLocation) {
        var cxfile = CXFile()
        var line: UInt32 = 0
        var column: UInt32 = 0
        var offset: UInt32 = 0
        clang_getSpellingLocation(clangLocation, &cxfile, &line, &column, &offset)
        self.init(file: clang_getFileName(cxfile).str() ?? "<none>",
            line: line, column: column, offset: offset)
    }
}

// MARK: Comparable

extension SourceLocation: Comparable {}

public func ==(lhs: SourceLocation, rhs: SourceLocation) -> Bool {
    return lhs.file.compare(rhs.file) == .OrderedSame &&
        lhs.line == rhs.line &&
        lhs.column == rhs.column &&
        lhs.offset == rhs.offset
}

/// A [strict total order](http://en.wikipedia.org/wiki/Total_order#Strict_total_order)
/// over instances of `Self`.
public func <(lhs: SourceLocation, rhs: SourceLocation) -> Bool {
    // Sort by file path.
    switch lhs.file.compare(rhs.file) {
    case .OrderedDescending:
        return false
    case .OrderedAscending:
        return true
    case .OrderedSame:
        break
    }

    // Then offset.
    return lhs.offset < rhs.offset
}

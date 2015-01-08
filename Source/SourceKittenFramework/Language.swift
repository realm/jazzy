//
//  Language.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-03.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

/// Language Enum
public enum Language {
    /// Represents Swift
    case Swift
    /// Represents Objective-C
    case ObjC
}

/**
Returns an array of swift file names in an array

:param: array Array to be filtered

:returns: the array of swift files
*/
public func swiftFilesFromArray(array: [String]) -> [String] {
    return array.filter {
        $0.rangeOfString(".swift", options: (.BackwardsSearch | .AnchoredSearch)) != nil
    }
}

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
Returns an array of swift file names in a sequence.

:param: sequence Sequence to be filtered.

:returns: The array of swift files.
*/
public func filterSwiftFiles<S: SequenceType where S.Generator.Element == String>(sequence: S) -> [String] {
    return filter(sequence) {
        $0.rangeOfString(".swift", options: (.BackwardsSearch | .AnchoredSearch)) != nil
    }
}

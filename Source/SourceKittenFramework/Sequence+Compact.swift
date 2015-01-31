//
//  Sequence+Compact.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-11.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

/**
Returns an array of the non-nil elements of the input sequence.

:param: sequence Sequence to compact.

:returns: An array of the non-nil elements of the input sequence.
*/
public func compact<T, S: SequenceType where S.Generator.Element == Optional<T>>(sequence: S) -> [T] {
    return filter(sequence, {
        $0 != nil
    }).map {
        $0! // Safe to force unwrap
    }
}

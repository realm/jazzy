//
//  SequenceType+IndexBefore.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-05.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

/**
Returns the index immediately preceding the first value in the sequence exceeding the given value.
Returns nil if there were no matches. This is mostly useful when the sequence contains strictly
increasing values.

:param: value Value to search for.
:param: sequence Sequence to search in.

:returns: Returns the index immediately preceding the first value in the sequence exceeding the given value.
          Returns nil if there were no matches.
*/
internal func indexBefore<T: Comparable, S: SequenceType where S.Generator.Element == T>(value: T, inSequence sequence: S) -> Int? {
    for (index, sequenceValue) in enumerate(sequence) {
        if sequenceValue >= value && index != 0 {
            return index - 1
        }
    }
    return nil
}

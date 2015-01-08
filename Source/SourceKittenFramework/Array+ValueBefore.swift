//
//  Array+ValueBefore.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-05.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

/**
Returns the value at the index prior to the first value meeting or exceeding the comparable value passed in.

:param: value Value to compare.
:param: array Array to search in.

:returns: Value at the index prior to the first value meeting or exceeding the comparable value passed in.
Returns array.first if there were no matches.
*/
func indexBeforeValue<T: Comparable>(value: T, inArray array: [T]) -> Int {
    for (index, arrayValue) in enumerate(array) {
        if arrayValue >= value && index != 0 {
            return index - 1
        }
    }
    return 0
}

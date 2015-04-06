//
//  Array+SourceKitten.swift
//  SourceKitten
//
//  Created by JP Simard on 4/4/15.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

/**
Returns an array containing the last contiguous group of elements matching the filter.

:param: array  Array to filter.
:param: filter Closure to filter elements.
*/
public func filterLastContiguous<T>(array: [T], filter: T -> Bool) -> [T] {
    // remove trailing elements until the last one matches the filter
    var arrayWithTrailingNonMatchesRemoved = array
    while arrayWithTrailingNonMatchesRemoved.last != nil &&
        !filter(arrayWithTrailingNonMatchesRemoved.last!) { // Safe to force unwrap
        arrayWithTrailingNonMatchesRemoved.removeLast()
    }
    var lastContiguousArray = [T]()
    // keep trailing elements until the first one matches the filter
    while arrayWithTrailingNonMatchesRemoved.last != nil &&
        filter(arrayWithTrailingNonMatchesRemoved.last!) { // Safe to force unwrap
        lastContiguousArray.insert(arrayWithTrailingNonMatchesRemoved.removeLast(), atIndex: 0)
    }
    return lastContiguousArray
}

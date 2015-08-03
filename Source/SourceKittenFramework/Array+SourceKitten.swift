//
//  Array+SourceKitten.swift
//  SourceKitten
//
//  Created by JP Simard on 4/4/15.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

/**
Returns an array containing the last contiguous group of elements matching the filter.

- parameter array:  Array to filter.
- parameter filter: Closure to filter elements.
*/
public func filterLastContiguous<T>(array: [T], filter: T -> Bool) -> [T] {
    // remove trailing elements until the last one matches the filter
    var arrayWithTrailingNonMatchesRemoved = array
    while let last = arrayWithTrailingNonMatchesRemoved.last where !filter(last) {
        arrayWithTrailingNonMatchesRemoved.removeLast()
    }
    var lastContiguousArray = [T]()
    // keep trailing elements until the first one matches the filter
    while let last = arrayWithTrailingNonMatchesRemoved.last where filter(last) {
        lastContiguousArray.insert(arrayWithTrailingNonMatchesRemoved.removeLast(),
            atIndex: 0)
    }
    return lastContiguousArray
}

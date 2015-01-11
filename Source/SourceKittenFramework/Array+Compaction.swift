//
//  Array+Compaction.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-11.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

/**
Returns a copy of the input array with nil entries removed.

:param: array Array to compact.

:returns: A copy of the input array with nil entries removed.
*/
public func compact<T>(array: [T?]) -> [T] {
    return array.filter({
        $0 != nil
    }).map {
        $0! // Safe to force unwrap
    }
}

//
//  Dictionary+Merge.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-08.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

/**
Returns a new dictionary by adding the entries of dict2 into dict1, overriding if the key exists.

:param: dict1 Dictionary to merge into.
:param: dict2 Dictionary to merge from.

:returns: A new dictionary by adding the entries of dict2 into dict1, overriding if the key exists.
*/
public func merge<K,V>(var dict1: [K: V], dict2: [K: V]) -> [K: V] {
    for (key, value) in dict2 {
        dict1[key] = value
    }
    return dict1
}

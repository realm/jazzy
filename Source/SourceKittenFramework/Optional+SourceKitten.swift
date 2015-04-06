//
//  Optional+SourceKitten.swift
//  SourceKitten
//
//  Created by JP Simard on 4/5/15.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

/// Returns `f(self)!` iff `self` and `f(self)` are not nil.
public func flatMap<T, U>(x: T?, f: T -> U?) -> U? {
    if let x = x {
        return f(x)
    }
    return nil
}

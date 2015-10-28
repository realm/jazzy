//
//  SourceLocation.swift
//  SourceKitten
//
//  Created by JP Simard on 10/27/15.
//  Copyright © 2015 SourceKitten. All rights reserved.
//

public struct SourceLocation {
    let file: String
    let line: UInt32
    let column: UInt32
    let offset: UInt32
}

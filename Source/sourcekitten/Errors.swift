//
//  Errors.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-15.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import Commandant

/// Possible errors within `sourcekitten`.
enum SourceKittenError {
    /// One or more arguments was invalid.
    case InvalidArgument(description: String)

    /// Failed to read a file at the given path.
    case ReadFailed(path: String)

    /// Failed to generate documentation.
    case DocFailed

    /// A `CommandantError` object corresponding to this SourceKitten error.
    var error: CommandantError {
        switch self {
        case .InvalidArgument(let description):
            return .UsageError(description: description)
        case .ReadFailed(let path):
            return .UsageError(description: "Failed to read file at '\(path)'")
        case .DocFailed:
            return .UsageError(description: "Failed to generate documentation")
        }
    }
}

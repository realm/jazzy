//
//  Errors.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-15.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import Foundation

/// The domain for all errors originating within SourceKitten.
let SourceKittenErrorDomain: NSString = "com.sourcekitten.SourceKitten"

/// Possible error codes with `SourceKittenErrorDomain`.
enum SourceKittenErrorCode: Int {
    case InvalidArgument
    case ReadFailed
    case DocFailed

    func error(userInfo: [NSObject: AnyObject]?) -> NSError {
        return NSError(domain: SourceKittenErrorDomain, code: self.rawValue, userInfo: userInfo)
    }
}

/// Possible errors within `SourceKittenErrorDomain`.
enum SourceKittenError {
    /// One or more arguments was invalid.
    case InvalidArgument(description: String)

    /// Failed to read a file at the given path.
    case ReadFailed(path: String)

    /// Failed to generate documentation.
    case DocFailed

    /// An `NSError` object corresponding to this error code.
    var error: NSError {
        switch self {
        case let .InvalidArgument(description):
            return SourceKittenErrorCode.InvalidArgument.error([
                NSLocalizedDescriptionKey: description
            ])
        case let .ReadFailed(path):
            return SourceKittenErrorCode.ReadFailed.error([
                NSLocalizedDescriptionKey: "Failed to read file at '\(path)'"
            ])
        case let .DocFailed:
            return SourceKittenErrorCode.DocFailed.error([
                NSLocalizedDescriptionKey: "Failed to generate documentation"
            ])
        }
    }
}

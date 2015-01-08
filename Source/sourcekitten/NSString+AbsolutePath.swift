//
//  NSString+AbsolutePath.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-07.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import Foundation

extension NSString {
    /**
    Returns self represented as an absolute path

    :returns: self represented as an absolute path
    */
    func absolutePathRepresentation() -> String {
        if absolutePath {
            return self
        }
        return NSString.pathWithComponents([NSFileManager.defaultManager().currentDirectoryPath, self]).stringByStandardizingPath
    }
}

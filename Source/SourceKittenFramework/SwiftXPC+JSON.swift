//
//  SwiftXPC+JSON.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-06.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import Foundation
import SwiftXPC

/**
Convert XPCDictionary to JSON.

:param: dictionary XPCDictionary to convert.

:returns: Converted JSON.
*/
public func toJSON(dictionary: XPCDictionary) -> String {
    return toJSON(toAnyObject(dictionary))
}

/**
Convert XPCArray of XPCDictionary's to JSON.

:param: array XPCArray of XPCDictionary's to convert.

:returns: Converted JSON.
*/
public func toJSON(array: XPCArray) -> String {
    return toJSON(array.map { toAnyObject($0 as! XPCDictionary) })
}

/**
JSON Object to JSON String.

:param: object Object to convert to JSON.

:returns: JSON string representation of the input object.
*/
public func toJSON(object: AnyObject) -> String {
    if let prettyJSONData = NSJSONSerialization.dataWithJSONObject(object,
        options: .PrettyPrinted,
        error: nil),
        jsonString = NSString(data: prettyJSONData, encoding: NSUTF8StringEncoding) as? String {
        return jsonString
    }
    return ""
}

/**
Convert XPCDictionary to `[String: AnyObject]` for conversion using NSJSONSerialization. See toJSON(_:)

:param: dictionary XPCDictionary to convert.

:returns: JSON-serializable Dictionary.
*/
public func toAnyObject(dictionary: XPCDictionary) -> [String: AnyObject] {
    var anyDictionary = [String: AnyObject]()
    for (key, object) in dictionary {
        switch object {
        case let object as XPCArray:
            anyDictionary[key] = object.map { toAnyObject($0 as! XPCDictionary) }
        case let object as XPCDictionary:
            anyDictionary[key] = toAnyObject(object)
        case let object as String:
            anyDictionary[key] = object
        case let object as NSDate:
            anyDictionary[key] = object
        case let object as NSData:
            anyDictionary[key] = object
        case let object as UInt64:
            anyDictionary[key] = NSNumber(unsignedLongLong: object)
        case let object as Int64:
            anyDictionary[key] = NSNumber(longLong: object)
        case let object as Double:
            anyDictionary[key] = NSNumber(double: object)
        case let object as Bool:
            anyDictionary[key] = NSNumber(bool: object)
        case let object as NSFileHandle:
            anyDictionary[key] = NSNumber(int: object.fileDescriptor)
        default:
            fatalError("Should never happen because we've checked all XPCRepresentable types")
        }
    }
    return anyDictionary
}

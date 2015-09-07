//
//  Request.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-03.
//  Copyright (c) 2015 JP Simard. All rights reserved.
//

import Foundation
import SwiftXPC

/// dispatch_once_t token used to only initialize SourceKit once per session.
private var sourceKitInitializationToken = dispatch_once_t(0)

/// SourceKit UID to String map.
private var uidStringMap = [UInt64: String]()

/**
Cache SourceKit requests for strings from UIDs

- parameter uid: UID received from sourcekitd* responses.

- returns: Cached UID string if available, nil otherwise.
*/
internal func stringForSourceKitUID(uid: UInt64) -> String? {
    if uid < UInt64(UInt32.max) {
        // UID's are always higher than UInt32.max
        return nil
    } else if let string = uidStringMap[uid] {
        return string
    } else if let uidString = String(UTF8String: sourcekitd_uid_get_string_ptr(uid)) {
        uidStringMap[uid] = uidString
        return uidString
    }
    return nil
}

/// Represents a SourceKit request.
public enum Request {
    /// An `editor.open` request for the given File.
    case EditorOpen(File)
    /// A `cursorinfo` request for an offset in the given file, using the `arguments` given.
    case CursorInfo(file: String, offset: Int64, arguments: [String])
    /// A custom request by passing in the xpc_object_t directly.
    case CustomRequest(xpc_object_t)
    /// A `codecomplete` request by passing in the file name, contents, offset
    /// for which to generate code completion options and array of compiler arguments.
    case CodeCompletionRequest(file: String, contents: String, offset: Int64, arguments: [String])

    /// xpc_object_t version of the Request to be sent to SourceKit.
    private var xpcValue: xpc_object_t {
        switch self {
        case .EditorOpen(let file):
            let openRequestUID = sourcekitd_uid_get_from_cstr("source.request.editor.open")
            if let path = file.path {
                return toXPC([
                    "key.request": openRequestUID,
                    "key.name": path,
                    "key.sourcefile": path
                ])
            } else {
                return toXPC([
                    "key.request": openRequestUID,
                    "key.name": String(file.contents.hash),
                    "key.sourcetext": file.contents
                ])
            }
        case .CursorInfo(let file, let offset, let arguments):
            return toXPC([
                "key.request": sourcekitd_uid_get_from_cstr("source.request.cursorinfo"),
                "key.name": file,
                "key.sourcefile": file,
                "key.offset": offset,
                "key.compilerargs": (arguments.map { $0 as XPCRepresentable } as XPCArray)
            ])
        case .CustomRequest(let request):
            return request
        case .CodeCompletionRequest(let file, let contents, let offset, let arguments):
            return toXPC([
                "key.request": sourcekitd_uid_get_from_cstr("source.request.codecomplete"),
                "key.name": file,
                "key.sourcefile": file,
                "key.sourcetext": contents,
                "key.offset": offset,
                "key.compilerargs": (arguments.map { $0 as XPCRepresentable } as XPCArray)
            ])
        }
    }

    /**
    Create a Request.CursorInfo.xpcValue() from a file path and compiler arguments.

    - parameter filePath:  Path of the file to create request.
    - parameter arguments: Compiler arguments.

    - returns: xpc_object_t representation of the Request, if successful.
    */
    internal static func cursorInfoRequestForFilePath(filePath: String?, arguments: [String]) -> xpc_object_t? {
        if let path = filePath {
            return Request.CursorInfo(file: path, offset: 0, arguments: arguments).xpcValue
        }
        return nil
    }

    /**
    Send a Request.CursorInfo by updating its offset. Returns SourceKit response if successful.

    - parameter request: xpc_object_t representation of Request.CursorInfo
    - parameter offset:  Offset to update request.

    - returns: SourceKit response if successful.
    */
    internal static func sendCursorInfoRequest(request: xpc_object_t, atOffset offset: Int64) -> XPCDictionary? {
        if offset == 0 {
            return nil
        }
        xpc_dictionary_set_int64(request, SwiftDocKey.Offset.rawValue, offset)
        return Request.CustomRequest(request).send()
    }

    /**
    Sends the request to SourceKit and return the response as an XPCDictionary.

    - returns: SourceKit output as an XPC dictionary.
    */
    public func send() -> XPCDictionary {
        dispatch_once(&sourceKitInitializationToken) {
            sourcekitd_initialize()
        }
        guard let response = sourcekitd_send_request_sync(xpcValue) else {
            fatalError("SourceKit response nil for request \(self)")
        }
        return replaceUIDsWithSourceKitStrings(fromXPC(response))
    }
}

// MARK: CustomStringConvertible

extension Request: CustomStringConvertible {
    /// A textual representation of `Request`.
    public var description: String { return xpcValue.description }
}

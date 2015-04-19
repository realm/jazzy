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

:param: uid UID received from sourcekitd* responses

:returns: Cached UID string if available, other
*/
internal func stringForSourceKitUID(uid: UInt64) -> String? {
    if uid < 4_300_000_000 {
        // UID's are always higher than 4.3M
        return nil
    } else if let string = uidStringMap[uid] {
        return string
    } else {
        if let uidString = String(UTF8String: sourcekitd_uid_get_string_ptr(uid)) {
            uidStringMap[uid] = uidString
            return uidString
        }
    }
    return nil
}

/// Represents a SourceKit request.
public enum Request {
    /// An `editor.open` request for the given File.
    case EditorOpen(File)
    /// A `cursor.info` request for an offset in the given file, using the `arguments` given.
    case CursorInfo(file: String, offset: Int64, arguments: [String])
    /// A custom request by passing in the xpc_object_t directly.
    case CustomRequest(xpc_object_t)

    /// xpc_object_t version of the Request to be sent to SourceKit.
    private var xpcValue: xpc_object_t {
        switch self {
        case .EditorOpen(let file):
            let openRequestUID = sourcekitd_uid_get_from_cstr("source.request.editor.open")
            if let path = file.path {
                return toXPC([
                    "key.request": openRequestUID,
                    "key.name": "",
                    "key.sourcefile": path
                ])
            } else {
                return toXPC([
                    "key.request": openRequestUID,
                    "key.name": "",
                    "key.sourcetext": file.contents as String
                ])
            }
        case .CursorInfo(let file, let offset, let arguments):
            return toXPC([
                "key.request": sourcekitd_uid_get_from_cstr("source.request.cursorinfo"),
                "key.name": "",
                "key.sourcefile": file,
                "key.offset": offset,
                "key.compilerargs": (arguments.map { $0 as XPCRepresentable } as XPCArray)
            ])
        case .CustomRequest(let request):
            return request
        }
    }

    /**
    Create a Request.CursorInfo.xpcValue() from a file path and compiler arguments.

    :param: filePath  Path of the file to create request.
    :param: arguments Compiler arguments.

    :returns: xpc_object_t representation of the Request, if successful.
    */
    internal static func cursorInfoRequestForFilePath(filePath: String?, arguments: [String]) -> xpc_object_t? {
        if let path = filePath {
            return Request.CursorInfo(file: path, offset: 0, arguments: arguments).xpcValue
        }
        return nil
    }

    /**
    Send a Request.CursorInfo by updating its offset. Returns SourceKit response if successful.

    :param: request xpc_object_t representation of Request.CursorInfo
    :param: offset  Offset to update request.

    :returns: SourceKit response if successful.
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

    :returns: SourceKit output as an XPC dictionary.
    */
    public func send() -> XPCDictionary {
        dispatch_once(&sourceKitInitializationToken) {
            sourcekitd_initialize()
        }
        if let response = sourcekitd_send_request_sync(xpcValue) {
            return replaceUIDsWithSourceKitStrings(fromXPC(response))
        }
        fatalError("SourceKit response nil for request \(self)")
    }
}

// MARK: Printable

extension Request: Printable {
    /// A textual representation of `Request`.
    public var description: String { return xpcValue.description }
}

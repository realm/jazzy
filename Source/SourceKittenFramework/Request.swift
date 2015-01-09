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

public enum Request: Printable {
    case EditorOpen(File)
    case CursorInfo(file: String, offset: Int64, arguments: [String])
    case CustomRequest(xpc_object_t)

    public var description: String { return xpcValue().description }

    private func xpcValue() -> xpc_object_t {
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

    static func cursorInfoRequestForFilePath(filePath: String?, arguments: [String]) -> xpc_object_t? {
        if let path = filePath {
            return Request.CursorInfo(file: path, offset: 0, arguments: arguments).xpcValue()
        }
        return nil
    }

    static func sendCursorInfoRequest(request: xpc_object_t, atOffset offset: Int64) -> XPCDictionary? {
        if offset == 0 {
            return nil
        }
        xpc_dictionary_set_int64(request, SwiftDocKey.Offset.rawValue, offset)
        return Request.CustomRequest(request).send()
    }

    /**
    Sends the request to SourceKit and return the response as an XPCDictionary.

    :returns: SourceKit output as an XPC dictionary
    */
    public func send() -> XPCDictionary {
        dispatch_once(&sourceKitInitializationToken) {
            sourcekitd_initialize(); return
        }
        if let response = sourcekitd_send_request_sync(xpcValue()) {
            return replaceUIDsWithSourceKitStrings(fromXPC(response))
        }
        fatalError("SourceKit response nil for request \(self)")
        return XPCDictionary() // Keep the compiler happy 😄
    }
}

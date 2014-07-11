//
//  main.m
//  SourceKitten
//
//  Created by JP Simard on 7/11/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import <Foundation/Foundation.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        dispatch_queue_t q = dispatch_queue_create("com.dizzytechnology.XPCTest.gcd", 0);
        xpc_connection_t conn = xpc_connection_create("com.apple.SourceKitService", q);
        xpc_connection_set_event_handler(conn, ^(xpc_object_t object) { });
        xpc_connection_resume(conn);

        xpc_object_t dict = xpc_dictionary_create(0, 0, 0);
        xpc_dictionary_set_bool(dict, "ping", true);
        xpc_connection_send_message_with_reply(conn, dict, dispatch_get_global_queue(0, 0), ^(xpc_object_t object) {
            if (xpc_get_type(object) == XPC_TYPE_ERROR) {
                const char *string = xpc_dictionary_get_string(object, XPC_ERROR_KEY_DESCRIPTION);
                NSLog(@"error: %s", string);
            } else {
                NSLog(@"Hello from SourceKit! They were nice enough to send us an empty dictionary! %@ %@", conn, object);
            }
        });
        sleep(10);
    }
    return 0;
}

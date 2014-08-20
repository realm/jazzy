//
//  main.m
//  SourceKitten
//
//  Created by JP Simard on 7/11/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import <Foundation/Foundation.h>

// SourceKit function declarations
void sourcekitd_initialize();
uint64_t sourcekitd_uid_get_from_cstr(const char *);
xpc_object_t sourcekitd_send_request_sync(xpc_object_t);

int main(int argc, const char * argv[])
{
    NSString *executablePath = [[NSBundle mainBundle] bundlePath];
    sourcekitd_initialize();

    // Change to test different approaches
    // 0: docinfo on Swift source file
    // 1: docinfo on Foundation module
    // 2: docinfo on Swift framework
    // 3: docinfo on Objective-C modulemap (doesn't work. used to work with sourcekitd-test binary)
    NSInteger approach = 3;

    // Start with empty XPC request and compiler arguments array to send to sourcekitd
    xpc_object_t request = xpc_dictionary_create(NULL, NULL, 0);
    xpc_object_t compiler_args = xpc_array_create(NULL, 0);

    if (approach == 0) {
        // Approach 0: docinfo on Swift source file
        xpc_dictionary_set_uint64(request, "key.request", sourcekitd_uid_get_from_cstr("source.request.docinfo"));
        xpc_dictionary_set_string(request, "key.sourcefile", [executablePath stringByAppendingPathComponent:@"Musician.swift"].UTF8String);
    } else if (approach == 1) {
        // Approach 1: docinfo on Foundation module
        xpc_dictionary_set_uint64(request, "key.request", sourcekitd_uid_get_from_cstr("source.request.docinfo"));
        xpc_dictionary_set_string(request, "key.modulename", "Foundation");

        xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-sdk"));
        xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("/Applications/Xcode6-Beta6.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.10.sdk"));
    } else if (approach == 2) {
        // Approach 2: docinfo on Swift framework
        xpc_dictionary_set_uint64(request, "key.request", sourcekitd_uid_get_from_cstr("source.request.docinfo"));
        xpc_dictionary_set_string(request, "key.modulename", "SwifterMac");

        xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-I"));
        xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create([executablePath stringByAppendingPathComponent:@"SwifterMac.framework/Versions/A/Modules"].UTF8String));
        xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-sdk"));
        xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("/Applications/Xcode6-Beta6.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.10.sdk"));
    } else if (approach == 3) {
        // Approach 3: docinfo on Objective-C modulemap (doesn't work. used to work with sourcekitd-test binary)
        xpc_dictionary_set_uint64(request, "key.request", sourcekitd_uid_get_from_cstr("source.request.docinfo"));
        xpc_dictionary_set_string(request, "key.modulename", "TempJazzyModule");

        xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-I"));
        xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create(executablePath.UTF8String));
        xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-sdk"));
        xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("/Applications/Xcode6-Beta6.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.10.sdk"));
    }

    // Set the compiler arguments
    xpc_dictionary_set_value(request, "key.compilerargs", compiler_args);

    // Send the request to sourcekit
    xpc_object_t result = sourcekitd_send_request_sync(request);
    if (xpc_get_type(result) == XPC_TYPE_ERROR) {
        // Print error
        const char *string = xpc_dictionary_get_string(result, XPC_ERROR_KEY_DESCRIPTION);
        NSLog(@"error: %s", string);
    } else {
        // Print result
        NSLog(@"%@", result);
    }
}

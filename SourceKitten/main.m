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

int main(int argc, const char * argv[]) {

    ////////////////////////////////
    //
    // 1: Make framework-like structure
    //
    ////////////////////////////////

    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *fmError = nil;

    // 1.1: Module name & directory structure

    NSString *parentModuleName = [NSString stringWithFormat:@"JazzyModule_%@", [[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""]];
    NSString *tmpDir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"io.realm.jazzy"];

    NSString *frameworkDir = [tmpDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.framework", parentModuleName]];
    [fm createDirectoryAtPath:[frameworkDir stringByAppendingPathComponent:@"Headers"]
  withIntermediateDirectories:YES
                   attributes:nil
                        error:&fmError];
    if (fmError) {
        NSLog(@"error creating Headers directory: %@", fmError.localizedDescription);
        return 1;
    }

    [fm createDirectoryAtPath:[frameworkDir stringByAppendingPathComponent:@"Modules"]
  withIntermediateDirectories:NO
                   attributes:nil
                        error:&fmError];
    if (fmError) {
        NSLog(@"error creating Modules directory: %@", fmError.localizedDescription);
        return 1;
    }

    // 1.2: Copy Objective-C header file

    NSString *objCHeaderFilePath = [[NSProcessInfo processInfo] arguments][1];
    NSString *moduleName = [NSString stringWithFormat:@"%@.%@", parentModuleName, [[objCHeaderFilePath lastPathComponent] stringByDeletingPathExtension]];
    [fm copyItemAtPath:objCHeaderFilePath
                toPath:[frameworkDir stringByAppendingPathComponent:[NSString stringWithFormat:@"Headers/%@", [objCHeaderFilePath lastPathComponent]]]
                 error:&fmError];
    if (fmError) {
        NSLog(@"error copying Objective-C header file: %@", fmError.localizedDescription);
        return 1;
    }

    // 1.3: Write umbrella header file

    [fm createFileAtPath:[frameworkDir stringByAppendingPathComponent:[NSString stringWithFormat:@"Headers/%@.h", parentModuleName]] contents:[[NSString stringWithFormat:@"#import <%@/%@>", parentModuleName, [objCHeaderFilePath lastPathComponent]] dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];

    // 1.4: Write module map file

    [fm createFileAtPath:[frameworkDir stringByAppendingPathComponent:@"Modules/module.modulemap"] contents:[[NSString stringWithFormat:@"framework module %@ { umbrella header \"%@.h\" module * { export * } }", parentModuleName, parentModuleName] dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];

    ////////////////////////////////
    //
    // 2: Generate Swift interface using SourceKit
    //
    ////////////////////////////////

    sourcekitd_initialize();

    // 2.1: Build up XPC request to send to SourceKit

    xpc_object_t request = xpc_dictionary_create(NULL, NULL, 0);
    xpc_dictionary_set_uint64(request, "key.request", sourcekitd_uid_get_from_cstr("source.request.editor.open.interface"));
    xpc_dictionary_set_string(request, "key.modulename", moduleName.UTF8String);
    xpc_dictionary_set_string(request, "key.name", [NSString stringWithFormat:@"x-xcode-module://%@", moduleName].UTF8String);

    xpc_object_t compiler_args = xpc_array_create(NULL, 0);
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-sdk"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("/Applications/Xcode6-Beta6.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.10.sdk"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-F"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create(tmpDir.UTF8String));
    xpc_dictionary_set_value(request, "key.compilerargs", compiler_args);

    // 2.2: Send the request to SourceKit
    xpc_object_t result = sourcekitd_send_request_sync(request);
    if (xpc_get_type(result) != XPC_TYPE_DICTIONARY ||
        xpc_dictionary_get_count(request) <= 1) {
        NSLog(@"Error processing SourceKit result");
        return 1;
    }

    // 2.3: Print to stdout
    const char *string = xpc_dictionary_get_string(result, "key.sourcetext");
    [[NSString stringWithCString:string encoding:NSUTF8StringEncoding]
     writeToFile:@"/dev/stdout"
     atomically:NO
     encoding:NSUTF8StringEncoding
     error:nil];

    return 0;
}

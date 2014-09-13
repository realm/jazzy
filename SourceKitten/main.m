//
//  main.m
//  SourceKitten
//
//  Created by JP Simard on 7/11/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XPCKit/XPCKit.h>

// SourceKit function declarations
void sourcekitd_initialize();
uint64_t sourcekitd_uid_get_from_cstr(const char *);
xpc_object_t sourcekitd_send_request_sync(xpc_object_t);

NSArray *usrsInDict(NSDictionary *dict) {
    NSMutableArray *offsets = [NSMutableArray array];
    for (NSDictionary *entityDict in dict[@"key.entities"]) {
        if ([entityDict.allKeys containsObject:@"key.usr"]) {
            [offsets addObject:entityDict[@"key.usr"]];
        }
        if ([entityDict.allKeys containsObject:@"key.entities"]) {
            [offsets addObjectsFromArray:usrsInDict(entityDict)];
        }
    }
    return [offsets copy];
}

void print_usage() {
    printf("Usage: SourceKitten [--swift_file swift_file_path] [--file objc_header_path] [--module module_name --framework_dir /absolute/path/to/framework] [--help]\n");
}

int error(const char *message) {
    printf("Error: %s\n\n", message);
    print_usage();
    return 1;
}

int generate_swift_interface_for_module(NSString *moduleName, NSString *frameworkDir) {

    sourcekitd_initialize();

    // 1: Build up XPC request to send to SourceKit

    xpc_object_t request = xpc_dictionary_create(NULL, NULL, 0);
    xpc_dictionary_set_uint64(request, "key.request", sourcekitd_uid_get_from_cstr("source.request.editor.open.interface"));
    xpc_dictionary_set_string(request, "key.modulename", moduleName.UTF8String);
    xpc_dictionary_set_string(request, "key.name", [NSString stringWithFormat:@"x-xcode-module://%@", moduleName].UTF8String);

    xpc_object_t compiler_args = xpc_array_create(NULL, 0);
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-sdk"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("/Applications/Xcode6-Beta7.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS8.0.sdk"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-F"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create(frameworkDir.UTF8String));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-target"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("armv7-apple-ios8.0"));
    xpc_dictionary_set_value(request, "key.compilerargs", compiler_args);

    // 2: Send the request to SourceKit

    xpc_object_t result = sourcekitd_send_request_sync(request);
    if (xpc_get_type(result) != XPC_TYPE_DICTIONARY ||
        xpc_dictionary_get_count(request) <= 1) {
        NSLog(@"%@", result);
        return error("couldn't process SourceKit results");
    }

    // 3: Print Swift interface

    printf("%s", xpc_dictionary_get_string(result, "key.sourcetext"));
    return 0;
}

int printDocs(const char *sourcetext, NSArray *usrs) {
    NSString *tmpDir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"io.realm.jazzy"];
    NSString *playgroundPath = [tmpDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.playground", [[NSUUID UUID] UUIDString]]];

    xpc_object_t compiler_args = xpc_array_create(NULL, 0);
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-module-name"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("Playground"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-target"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("x86_64-apple-macosx10.10"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-sdk"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("/Applications/Xcode6-Beta7.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.10.sdk"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-F"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("/Applications/Xcode6-Beta7.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-F"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("/Applications/Xcode6-Beta7.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/PrivateFrameworks"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-Xfrontend"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-debugger-support"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-c"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create(playgroundPath.UTF8String));

    {
        // 1: Build up XPC request to send to SourceKit

        xpc_object_t request = xpc_dictionary_create(NULL, NULL, 0);
        xpc_dictionary_set_uint64(request, "key.request", sourcekitd_uid_get_from_cstr("source.request.editor.open"));
        xpc_dictionary_set_string(request, "key.name", playgroundPath.UTF8String);
        xpc_dictionary_set_string(request, "key.sourcetext", sourcetext);

        xpc_dictionary_set_value(request, "key.compilerargs", compiler_args);

        // 2: Send the request to SourceKit

        xpc_object_t result = sourcekitd_send_request_sync(request);
        if (xpc_get_type(result) != XPC_TYPE_DICTIONARY ||
            xpc_dictionary_get_count(request) <= 1) {
            return error("couldn't process SourceKit results");
        }
    }

    NSMutableDictionary *docs = [NSMutableDictionary dictionaryWithCapacity:usrs.count];

    for (NSUInteger cursor = 0; cursor < @(sourcetext).length; cursor++) {
        {
            // 1: Build up XPC request to send to SourceKit

            xpc_object_t request = xpc_dictionary_create(NULL, NULL, 0);
            xpc_dictionary_set_uint64(request, "key.request", sourcekitd_uid_get_from_cstr("source.request.cursorinfo"));
            xpc_dictionary_set_string(request, "key.name", playgroundPath.UTF8String);
            xpc_dictionary_set_string(request, "key.sourcefile", playgroundPath.UTF8String);
            xpc_dictionary_set_int64(request, "key.offset", cursor);

            xpc_dictionary_set_value(request, "key.compilerargs", compiler_args);

            // 2: Send the request to SourceKit

            xpc_object_t result = sourcekitd_send_request_sync(request);
            if (xpc_get_type(result) != XPC_TYPE_DICTIONARY ||
                xpc_dictionary_get_count(request) <= 1) {
                return error("couldn't process SourceKit results");
            }

            // 3: Print result

            const char *doc = xpc_dictionary_get_string(result, "key.doc.full_as_xml");
            if (doc != nil) {
                NSString *usr = @(xpc_dictionary_get_string(result, "key.usr"));
                if (![docs.allKeys containsObject:usr]) {
                    docs[usr] = @(doc);
                }
            }
        }
    }
    NSLog(@"docs: %@", docs);
    return 0;
}

int cursorinfo_playground() {

    NSArray *arguments = [[NSProcessInfo processInfo] arguments];
    if (arguments.count < 3) {
        return error("not enough arguments");
    }

    sourcekitd_initialize();

    const char *sourcetext = [[NSString stringWithContentsOfFile:arguments[2] encoding:NSUTF8StringEncoding error:nil] UTF8String];

    {
        // 1: Build up XPC request to send to SourceKit

        xpc_object_t request = xpc_dictionary_create(NULL, NULL, 0);
        xpc_dictionary_set_uint64(request, "key.request", sourcekitd_uid_get_from_cstr("source.request.docinfo"));
        xpc_dictionary_set_string(request, "key.sourcetext", sourcetext);

        // 2: Send the request to SourceKit

        xpc_object_t result = sourcekitd_send_request_sync(request);
        if (xpc_get_type(result) != XPC_TYPE_DICTIONARY ||
            xpc_dictionary_get_count(request) <= 1) {
            return error("couldn't process SourceKit results");
        }

        // 3: Print result

        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfXPCObject:result];
        // NSLog(@"dict: %@", dict);
        return printDocs(sourcetext, usrsInDict(dict));
    }
    return 1;
}

int generate_swift_interface_for_file() {

    NSArray *arguments = [[NSProcessInfo processInfo] arguments];
    if (arguments.count < 3) {
        return error("not enough arguments");
    }

    ////////////////////////////////
    //
    // Make framework-like structure
    //
    ////////////////////////////////

    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *fmError = nil;

    // 1: Module name & directory structure

    NSString *parentModuleName = [NSString stringWithFormat:@"JazzyModule_%@", [[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""]];
    NSString *tmpDir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"io.realm.jazzy"];

    NSString *frameworkDir = [tmpDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.framework", parentModuleName]];
    [fm createDirectoryAtPath:[frameworkDir stringByAppendingPathComponent:@"Headers"]
  withIntermediateDirectories:YES
                   attributes:nil
                        error:&fmError];
    if (fmError) {
        return error("couldn't create Headers directory");
    }

    [fm createDirectoryAtPath:[frameworkDir stringByAppendingPathComponent:@"Modules"]
  withIntermediateDirectories:NO
                   attributes:nil
                        error:&fmError];
    if (fmError) {
        return error("couldn't create Modules directory");
    }

    // 2: Copy Objective-C header file

    NSString *objCHeaderFilePath = arguments[2];
    NSString *moduleName = [NSString stringWithFormat:@"%@.%@", parentModuleName, [[objCHeaderFilePath lastPathComponent] stringByDeletingPathExtension]];
    [fm copyItemAtPath:objCHeaderFilePath
                toPath:[frameworkDir stringByAppendingPathComponent:[NSString stringWithFormat:@"Headers/%@", [objCHeaderFilePath lastPathComponent]]]
                 error:&fmError];
    if (fmError) {
        return error("couldn't copy Objective-C header file");
    }

    // 3: Write umbrella header file

    [fm createFileAtPath:[frameworkDir stringByAppendingPathComponent:[NSString stringWithFormat:@"Headers/%@.h", parentModuleName]] contents:[[NSString stringWithFormat:@"#import <%@/%@>", parentModuleName, [objCHeaderFilePath lastPathComponent]] dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];

    // 4: Write module map file

    [fm createFileAtPath:[frameworkDir stringByAppendingPathComponent:@"Modules/module.modulemap"] contents:[[NSString stringWithFormat:@"framework module %@ { umbrella header \"%@.h\" module * { export * } }", parentModuleName, parentModuleName] dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];

    // 5: Generate Swift interface

    return generate_swift_interface_for_module(moduleName, tmpDir);
}

int main(int argc, const char * argv[]) {

    NSArray *arguments = [[NSProcessInfo processInfo] arguments];
    if (arguments.count == 1) {
        return error("not enough arguments");
    } else if ([arguments[1] isEqualToString:@"--help"]) {
        print_usage();
        return 0;
    } else if ([arguments[1] isEqualToString:@"--swift_file"]) {
        return cursorinfo_playground();
    } else if ([arguments[1] isEqualToString:@"--file"]) {
        return generate_swift_interface_for_file();
    } else if (arguments.count >= 5 &&
               [arguments[1] isEqualToString:@"--module"] &&
               [arguments[3] isEqualToString:@"--framework_dir"]) {
        return generate_swift_interface_for_module(arguments[2], arguments[4]);
    }

    return error("unable to parse command");
}

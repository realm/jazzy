//
//  main.m
//  SourceKitten
//
//  Created by JP Simard on 7/11/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XPCKit/XPCKit.h>
#import "JAZEntity.h"
#import "sourcekitd.h"

NSArray *entitiesInDict(NSDictionary *dict) {
    NSMutableArray *entities = [NSMutableArray array];
    for (NSDictionary *entityDict in dict[@"key.entities"]) {
        if ([entityDict.allKeys containsObject:@"key.usr"]) {
            JAZEntity *entity = [JAZEntity new];
            entity.usr = [entityDict[@"key.usr"] stringByReplacingOccurrencesOfString:@"8__main__" withString:@"5Jazzy"];
            entity.name = entityDict[@"key.name"];
            entity.kind = JAZEntityKindFromCString(sourcekitd_uid_get_string_ptr([(NSNumber *)entityDict[@"key.kind"] integerValue]));
            if ([entityDict.allKeys containsObject:@"key.entities"]) {
                entity.entities = entitiesInDict(entityDict);
            }
            [entities addObject:entity];
        } else {
            if ([entityDict.allKeys containsObject:@"key.entities"]) {
                [entities addObjectsFromArray:entitiesInDict(entityDict)];
            }
        }
    }
    return [entities copy];
}

void print_usage() {
    printf("Usage: SourceKitten [--swift_file swift_file_path] [--file objc_header_path] [--module module_name --framework_dir /absolute/path/to/framework] [--help]\n");
}

int error(const char *message) {
    printf("Error: %s\n\n", message);
    print_usage();
    return 1;
}

NSString *xcode_path() {
    NSPipe *pipe = [NSPipe pipe];
    NSFileHandle *file = pipe.fileHandleForReading;

    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/xcode-select";
    task.arguments = @[ @"-p" ];
    task.standardOutput = pipe;

    [task launch];

    NSData *data = [file readDataToEndOfFile];
    [file closeFile];

    NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return [output substringToIndex:output.length-1]; // strip trailing newline
}

int generate_swift_interface_for_module(NSString *moduleName, NSString *frameworkDir) {
    sourcekitd_initialize();

    // 1: Build up XPC request to send to SourceKit

    xpc_object_t request = xpc_dictionary_create(NULL, NULL, 0);
    xpc_dictionary_set_uint64(request, "key.request", sourcekitd_uid_get_from_cstr("source.request.editor.open.interface"));
    xpc_dictionary_set_string(request, "key.modulename", moduleName.UTF8String);
    xpc_dictionary_set_string(request, "key.name", [NSString stringWithFormat:@"x-xcode-module://%@", moduleName].UTF8String);

    NSArray *compilerArgs = @[ @"-sdk",
                               [xcode_path() stringByAppendingPathComponent:@"Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS8.0.sdk"],
                               @"-F",
                               frameworkDir,
                               @"-target",
                               @"armv7-apple-ios8.0" ];

    xpc_dictionary_set_value(request, "key.compilerargs", [compilerArgs newXPCObject]);

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

BOOL setDocs(JAZEntity *entity, NSString *usr, NSString *docs) {
    BOOL set = NO;
    if ([entity.usr isEqualToString:usr] && !entity.docs) {
        entity.docs = docs;
        set = YES;
    }
    for (JAZEntity *subEntity in entity.entities) {
        set = setDocs(subEntity, usr, docs);
        if (set) {
            break;
        }
    }
    return set;
}

int printDocs(const char *sourcetext, NSArray *entities) {
    NSString *tmpDir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"io.realm.jazzy"];
    NSString *playgroundPath = [tmpDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.playground", [[NSUUID UUID] UUIDString]]];
    NSArray *compilerArgs = @[ @"-module-name",
                               @"Jazzy",
                               @"-target",
                               @"x86_64-apple-macosx10.10",
                               @"-sdk",
                               [xcode_path() stringByAppendingPathComponent:@"Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.10.sdk"],
                               @"-F",
                               [xcode_path() stringByAppendingPathComponent:@"Platforms/MacOSX.platform/Developer/Library/Frameworks"],
                               @"-F",
                               [xcode_path() stringByAppendingPathComponent:@"Platforms/MacOSX.platform/Developer/Library/PrivateFrameworks"],
                               @"-Xfrontend",
                               @"-debugger-support",
                               @"-c",
                               playgroundPath ];
    xpc_object_t compiler_args = [compilerArgs newXPCObject];

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

            const char *docs = xpc_dictionary_get_string(result, "key.doc.full_as_xml");
            if (docs != nil) {
                NSString *usr = @(xpc_dictionary_get_string(result, "key.usr"));
                for (JAZEntity *entity in entities) {
                    setDocs(entity, usr, @(docs));
                }
            }
        }
    }
    for (JAZEntity *entity in entities) {
        printf("%s", entity.xmlDocs.UTF8String);
    }
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
        return printDocs(sourcetext, entitiesInDict(dict));
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

int cursorinfo(const char *file, NSString *args, int64_t offset) {
    sourcekitd_initialize();

    NSArray *arguments = [args componentsSeparatedByString:@" "];
    arguments = [arguments subarrayWithRange:NSMakeRange(1, arguments.count-1)];
    arguments = [arguments arrayByAddingObjectsFromArray:@[@"-module-cache-path",
                                                           @"/Users/jp/Library/Developer/Xcode/DerivedData/ModuleCache"]];

    xpc_object_t compilerargs = [arguments newXPCObject];
    xpc_object_t request = xpc_dictionary_create(NULL, NULL, 0);
    xpc_dictionary_set_uint64(request, "key.request", sourcekitd_uid_get_from_cstr("source.request.cursorinfo"));
    xpc_dictionary_set_value(request, "key.compilerargs", compilerargs);
    xpc_dictionary_set_int64(request, "key.offset", offset);
    xpc_dictionary_set_string(request, "key.sourcefile", file);

    const char *xml = xpc_dictionary_get_string(sourcekitd_send_request_sync(request), "key.doc.full_as_xml");
    printf("%s\n", xml);
    return 0;
}

int main(int argc, const char * argv[]) {
    return cursorinfo("/Users/jp/Projects/QueryKit/QueryKit/QuerySet.swift", @"/Applications/Xcode6-Beta7.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -target x86_64-apple-macosx10.10 -module-name QueryKit -Onone -sdk /Applications/Xcode6-Beta7.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.10.sdk -g -I /Users/jp/Projects/QueryKit/build/Debug -F /Users/jp/Projects/QueryKit/build/Debug -c -j4 /Users/jp/Projects/QueryKit/QueryKit/Attribute.swift /Users/jp/Projects/QueryKit/QueryKit/Predicate.swift /Users/jp/Projects/QueryKit/QueryKit/ObjectiveC/QKAttribute.swift /Users/jp/Projects/QueryKit/QueryKit/QueryKit.swift /Users/jp/Projects/QueryKit/QueryKit/ObjectiveC/QKQuerySet.swift /Users/jp/Projects/QueryKit/QueryKit/QuerySet.swift /Users/jp/Projects/QueryKit/QueryKit/Expression.swift -output-file-map /Users/jp/Projects/QueryKit/build/QueryKit.build/Debug/QueryKit.build/Objects-normal/x86_64/QueryKit-OutputFileMap.json -serialize-diagnostics -emit-dependencies -emit-module -emit-module-path /Users/jp/Projects/QueryKit/build/QueryKit.build/Debug/QueryKit.build/Objects-normal/x86_64/QueryKit.swiftmodule -Xcc -I/Users/jp/Projects/QueryKit/build/QueryKit.build/Debug/QueryKit.build/swift-overrides.hmap -Xcc -iquote -Xcc /Users/jp/Projects/QueryKit/build/QueryKit.build/Debug/QueryKit.build/QueryKit-generated-files.hmap -Xcc -I/Users/jp/Projects/QueryKit/build/QueryKit.build/Debug/QueryKit.build/QueryKit-own-target-headers.hmap -Xcc -I/Users/jp/Projects/QueryKit/build/QueryKit.build/Debug/QueryKit.build/QueryKit-all-non-framework-target-headers.hmap -Xcc -ivfsoverlay -Xcc /Users/jp/Projects/QueryKit/build/QueryKit.build/all-product-headers.yaml -Xcc -iquote -Xcc /Users/jp/Projects/QueryKit/build/QueryKit.build/Debug/QueryKit.build/QueryKit-project-headers.hmap -Xcc -I/Users/jp/Projects/QueryKit/build/Debug/include -Xcc -I/Applications/Xcode6-Beta7.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/include -Xcc -I/Users/jp/Projects/QueryKit/build/QueryKit.build/Debug/QueryKit.build/DerivedSources/x86_64 -Xcc -I/Users/jp/Projects/QueryKit/build/QueryKit.build/Debug/QueryKit.build/DerivedSources -Xcc -DDEBUG=1 -emit-objc-header -emit-objc-header-path /Users/jp/Projects/QueryKit/build/QueryKit.build/Debug/QueryKit.build/Objects-normal/x86_64/QueryKit-Swift.h -import-underlying-module -Xcc -ivfsoverlay -Xcc /Users/jp/Projects/QueryKit/build/QueryKit.build/Debug/QueryKit.build/unextended-module-overlay.yaml", 358);
//    NSArray *arguments = [[NSProcessInfo processInfo] arguments];
//    if (arguments.count == 1) {
//        return error("not enough arguments");
//    } else if ([arguments[1] isEqualToString:@"--help"]) {
//        print_usage();
//        return 0;
//    } else if ([arguments[1] isEqualToString:@"--swift_file"]) {
//        return cursorinfo_playground();
//    } else if ([arguments[1] isEqualToString:@"--file"]) {
//        return generate_swift_interface_for_file();
//    } else if (arguments.count >= 5 &&
//               [arguments[1] isEqualToString:@"--module"] &&
//               [arguments[3] isEqualToString:@"--framework_dir"]) {
//        return generate_swift_interface_for_module(arguments[2], arguments[4]);
//    }
//
//    return error("unable to parse command");
}

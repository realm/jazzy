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

void print_usage() {
    printf("Usage: SourceKitten [--swift_file swift_file_path] [--swift_file swift_file_path --cursor cursor_position] [--file objc_header_path] [--module module_name --framework_dir /absolute/path/to/framework] [--help]\n");
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

int docinfo_for_file() {

    NSArray *arguments = [[NSProcessInfo processInfo] arguments];
    if (arguments.count < 3) {
        return error("not enough arguments");
    }

    sourcekitd_initialize();

    // 1: Build up XPC request to send to SourceKit

    xpc_object_t request = xpc_dictionary_create(NULL, NULL, 0);
    xpc_dictionary_set_uint64(request, "key.request", sourcekitd_uid_get_from_cstr("source.request.docinfo"));
    xpc_dictionary_set_string(request, "key.sourcetext", [[NSString stringWithContentsOfFile:arguments[2] encoding:NSUTF8StringEncoding error:nil] UTF8String]);

    // 2: Send the request to SourceKit

    xpc_object_t result = sourcekitd_send_request_sync(request);
    if (xpc_get_type(result) != XPC_TYPE_DICTIONARY ||
        xpc_dictionary_get_count(request) <= 1) {
        return error("couldn't process SourceKit results");
    }

    // 3: Print result

    printf("%s", result.description.UTF8String);
    return 0;
}

int cursorinfo() {

    NSArray *arguments = [[NSProcessInfo processInfo] arguments];
    if (arguments.count < 3) {
        return error("not enough arguments");
    }

    sourcekitd_initialize();

    // 1: Build up XPC request to send to SourceKit

    xpc_object_t request = xpc_dictionary_create(NULL, NULL, 0);
    xpc_dictionary_set_uint64(request, "key.request", sourcekitd_uid_get_from_cstr("source.request.cursorinfo"));
    xpc_dictionary_set_string(request, "key.sourcefile", "/Users/jp/realm/code/realm-cocoa/examples/swift/RealmSwiftSimpleExample/RealmSwiftSimpleExample/AppDelegate.swift");
    xpc_dictionary_set_int64(request, "key.offset", 3087);

    xpc_object_t compiler_args = xpc_array_create(NULL, 0);
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-sdk"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("/Applications/Xcode6-Beta7.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator8.0.sdk"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-F"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("/Users/jp/Library/Developer/Xcode/DerivedData/RealmSwiftExamples-eihafzgkfwqrdngfkkikinijizvy/Build/Products/Debug-iphonesimulator"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-parse-as-library"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-c"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-j4"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("/Users/jp/realm/code/realm-cocoa/examples/swift/RealmSwiftSimpleExample/RealmSwiftSimpleExample/AppDelegate.swift"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-Xcc"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-I/Users/jp/Library/Developer/Xcode/DerivedData/RealmSwiftExamples-eihafzgkfwqrdngfkkikinijizvy/Build/Intermediates/RealmSwiftExamples.build/Debug-iphonesimulator/RealmSwiftSimpleExample.build/swift-overrides.hmap"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-Xcc"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-iquote"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-Xcc"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("/Users/jp/Library/Developer/Xcode/DerivedData/RealmSwiftExamples-eihafzgkfwqrdngfkkikinijizvy/Build/Intermediates/RealmSwiftExamples.build/Debug-iphonesimulator/RealmSwiftSimpleExample.build/RealmSwiftSimpleExample-generated-files.hmap"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-Xcc"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-I/Users/jp/Library/Developer/Xcode/DerivedData/RealmSwiftExamples-eihafzgkfwqrdngfkkikinijizvy/Build/Intermediates/RealmSwiftExamples.build/Debug-iphonesimulator/RealmSwiftSimpleExample.build/RealmSwiftSimpleExample-own-target-headers.hmap"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-Xcc"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-I/Users/jp/Library/Developer/Xcode/DerivedData/RealmSwiftExamples-eihafzgkfwqrdngfkkikinijizvy/Build/Intermediates/RealmSwiftExamples.build/Debug-iphonesimulator/RealmSwiftSimpleExample.build/RealmSwiftSimpleExample-all-non-framework-target-headers.hmap"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-Xcc"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-ivfsoverlay"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-Xcc"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("/Users/jp/Library/Developer/Xcode/DerivedData/RealmSwiftExamples-eihafzgkfwqrdngfkkikinijizvy/Build/Intermediates/RealmSwiftExamples.build/all-product-headers.yaml"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-Xcc"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-iquote"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-Xcc"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("/Users/jp/Library/Developer/Xcode/DerivedData/RealmSwiftExamples-eihafzgkfwqrdngfkkikinijizvy/Build/Intermediates/RealmSwiftExamples.build/Debug-iphonesimulator/RealmSwiftSimpleExample.build/RealmSwiftSimpleExample-project-headers.hmap"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-Xcc"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-I/Users/jp/Library/Developer/Xcode/DerivedData/RealmSwiftExamples-eihafzgkfwqrdngfkkikinijizvy/Build/Products/Debug-iphonesimulator/include"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-Xcc"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-I/Applications/Xcode6-Beta7.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/include"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-Xcc"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-I/Users/jp/Library/Developer/Xcode/DerivedData/RealmSwiftExamples-eihafzgkfwqrdngfkkikinijizvy/Build/Intermediates/RealmSwiftExamples.build/Debug-iphonesimulator/RealmSwiftSimpleExample.build/DerivedSources/x86_64"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-Xcc"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-I/Users/jp/Library/Developer/Xcode/DerivedData/RealmSwiftExamples-eihafzgkfwqrdngfkkikinijizvy/Build/Intermediates/RealmSwiftExamples.build/Debug-iphonesimulator/RealmSwiftSimpleExample.build/DerivedSources"));
    xpc_dictionary_set_value(request, "key.compilerargs", compiler_args);

    // 2: Send the request to SourceKit

    xpc_object_t result = sourcekitd_send_request_sync(request);
    if (xpc_get_type(result) != XPC_TYPE_DICTIONARY ||
        xpc_dictionary_get_count(request) <= 1) {
        return error("couldn't process SourceKit results");
    }

    // 3: Print result

    printf("%s", result.description.UTF8String);

    // Prints
//    <OS_xpc_dictionary: <dictionary: 0x100500120> { count = 10, contents =
//        "key.annotated_decl" => <string: 0x1005006d0> { length = 91, contents = "<Declaration>class RLMObject : <Type usr="c:objc(cs)NSObject">NSObject</Type></Declaration>" }
//        "key.kind" => <uint64: 0x100500310>: 4303378664
//        "key.modulename" => <string: 0x100500290> { length = 15, contents = "Realm.RLMObject" }
//        "key.usr" => <string: 0x1005008a0> { length = 19, contents = "c:objc(cs)RLMObject" }
//        "key.doc.full_as_xml" => <string: 0x100500800> { length = 1884, contents = "<Other file="/Users/jp/realm/code/realm-cocoa/Realm/RLMObject.h" line="73" column="12"><Name>RLMObject</Name><USR>c:objc(cs)RLMObject</USR><Declaration>@interface RLMObject : NSObject
//            @end</Declaration><Abstract><Para>  In Realm you define your model classes by subclassing RLMObject and adding properties to be persisted. You then instantiate and use your custom subclasses instead of using the RLMObject class directly.</Para></Abstract><Discussion><Para>     // Dog.h     </Para><Para>     </Para><Para>     // Dog.m      Dog      //none needed</Para><Para> ### Supported property types</Para><Para> - `NSString` - `NSInteger`, `CGFloat`, `int`, `long`, `float`, and `double` - `BOOL` or `bool` - `NSDate` - `NSData` - RLMObject subclasses, so you can have many-to-one relationships. - `RLMArray&lt;X&gt;`, where X is an RLMObject subclass, so you can have many-to-many relationships.</Para><Para> ### Attributes for Properties</Para><Para> You can set which of these properties should be indexed, stored inline, unique, required as well as delete rules for the links by implementing the attributesForProperty: method.</Para><Para> You can set properties to ignore (i.e. transient properties you do not want persisted to a Realm) by implementing ignoredProperties.</Para><Para> You can set default values for properties by implementing defaultPropertyValues.</Para><Para> ### Querying</Para><Para> You can query an object directly via the class methods: allObjects, objectsWhere:, objectsOrderedBy:where: and objectForKeyedSubscript: These methods allow you to easily query a custom subclass for instances of this class in the default Realm. To search in a Realm other than the default Realm use the interface on an RLMRealm instance.</Para><Para> ### Relationships</Para><Para> See our [Cocoa guide](http://realm.io/docs/cocoa/latest) for more details.</Para></Discussion></Other>" }
//            "key.offset" => <int64: 0x100500380>: 2496
//            "key.typename" => <string: 0x100500910> { length = 14, contents = "RLMObject.Type" }
//            "key.name" => <string: 0x100500a50> { length = 9, contents = "RLMObject" }
//            "key.filepath" => <string: 0x1005009d0> { length = 50, contents = "/Users/jp/realm/code/realm-cocoa/Realm/RLMObject.h" }
//            "key.length" => <int64: 0x100500ad0>: 9
//        }>
    return 0;
}

int cursorinfo2() {

    NSArray *arguments = [[NSProcessInfo processInfo] arguments];
    if (arguments.count < 3) {
        return error("not enough arguments");
    }

    sourcekitd_initialize();

    // 1: Build up XPC request to send to SourceKit

    xpc_object_t request = xpc_dictionary_create(NULL, NULL, 0);
    xpc_dictionary_set_uint64(request, "key.request", sourcekitd_uid_get_from_cstr("source.request.cursorinfo"));
    xpc_dictionary_set_string(request, "key.sourcefile", "/Users/jp/Projects/QueryKit/QueryKit/QuerySet.swift");
    xpc_dictionary_set_int64(request, "key.offset", 201);

    xpc_object_t compiler_args = xpc_array_create(NULL, 0);
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-target"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("x86_64-apple-macosx10.10"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-module-name"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("QueryKit"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-Onone"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-sdk"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("/Applications/Xcode6-Beta7.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.10.sdk"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-g"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-module-cache-path"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("/Users/jp/Library/Developer/Xcode/DerivedData/ModuleCache"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-I"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("/Users/jp/Library/Developer/Xcode/DerivedData/QueryKit-aqwcwloqrgrvzqflfqtrdhbnechy/Build/Products/Debug"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-F"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("/Users/jp/Library/Developer/Xcode/DerivedData/QueryKit-aqwcwloqrgrvzqflfqtrdhbnechy/Build/Products/Debug"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-c"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-j4"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("/Users/jp/Projects/QueryKit/QueryKit/Attribute.swift"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("/Users/jp/Projects/QueryKit/QueryKit/Predicate.swift"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("/Users/jp/Projects/QueryKit/QueryKit/ObjectiveC/QKAttribute.swift"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("/Users/jp/Projects/QueryKit/QueryKit/QueryKit.swift"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("/Users/jp/Projects/QueryKit/QueryKit/ObjectiveC/QKQuerySet.swift"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("/Users/jp/Projects/QueryKit/QueryKit/QuerySet.swift"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("/Users/jp/Projects/QueryKit/QueryKit/Expression.swift"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-emit-module"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-emit-module-path"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("/Users/jp/Library/Developer/Xcode/DerivedData/QueryKit-aqwcwloqrgrvzqflfqtrdhbnechy/Build/Intermediates/QueryKit.build/Debug/QueryKit.build/Objects-normal/x86_64/QueryKit.swiftmodule"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-Xcc"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-I/Users/jp/Library/Developer/Xcode/DerivedData/QueryKit-aqwcwloqrgrvzqflfqtrdhbnechy/Build/Intermediates/QueryKit.build/Debug/QueryKit.build/swift-overrides.hmap"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-Xcc"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-iquote"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-Xcc"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("/Users/jp/Library/Developer/Xcode/DerivedData/QueryKit-aqwcwloqrgrvzqflfqtrdhbnechy/Build/Intermediates/QueryKit.build/Debug/QueryKit.build/QueryKit-generated-files.hmap"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-Xcc"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-I/Users/jp/Library/Developer/Xcode/DerivedData/QueryKit-aqwcwloqrgrvzqflfqtrdhbnechy/Build/Intermediates/QueryKit.build/Debug/QueryKit.build/QueryKit-own-target-headers.hmap"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-Xcc"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-I/Users/jp/Library/Developer/Xcode/DerivedData/QueryKit-aqwcwloqrgrvzqflfqtrdhbnechy/Build/Intermediates/QueryKit.build/Debug/QueryKit.build/QueryKit-all-non-framework-target-headers.hmap"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-Xcc"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-ivfsoverlay"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-Xcc"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("/Users/jp/Library/Developer/Xcode/DerivedData/QueryKit-aqwcwloqrgrvzqflfqtrdhbnechy/Build/Intermediates/QueryKit.build/all-product-headers.yaml"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-Xcc"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-iquote"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-Xcc"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("/Users/jp/Library/Developer/Xcode/DerivedData/QueryKit-aqwcwloqrgrvzqflfqtrdhbnechy/Build/Intermediates/QueryKit.build/Debug/QueryKit.build/QueryKit-project-headers.hmap"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-Xcc"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-I/Users/jp/Library/Developer/Xcode/DerivedData/QueryKit-aqwcwloqrgrvzqflfqtrdhbnechy/Build/Products/Debug/include"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-Xcc"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-I/Applications/Xcode6-Beta7.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/include"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-Xcc"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-I/Users/jp/Library/Developer/Xcode/DerivedData/QueryKit-aqwcwloqrgrvzqflfqtrdhbnechy/Build/Intermediates/QueryKit.build/Debug/QueryKit.build/DerivedSources/x86_64"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-Xcc"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-I/Users/jp/Library/Developer/Xcode/DerivedData/QueryKit-aqwcwloqrgrvzqflfqtrdhbnechy/Build/Intermediates/QueryKit.build/Debug/QueryKit.build/DerivedSources"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-Xcc"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-DDEBUG=1"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-emit-objc-header"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-emit-objc-header-path"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("/Users/jp/Library/Developer/Xcode/DerivedData/QueryKit-aqwcwloqrgrvzqflfqtrdhbnechy/Build/Intermediates/QueryKit.build/Debug/QueryKit.build/Objects-normal/x86_64/QueryKit-Swift.h"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-import-underlying-module"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-Xcc"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-ivfsoverlay"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("-Xcc"));
    xpc_array_set_value(compiler_args, XPC_ARRAY_APPEND, xpc_string_create("/Users/jp/Library/Developer/Xcode/DerivedData/QueryKit-aqwcwloqrgrvzqflfqtrdhbnechy/Build/Intermediates/QueryKit.build/Debug/QueryKit.build/unextended-module-overlay.yaml"));
    xpc_dictionary_set_value(request, "key.compilerargs", compiler_args);

    // 2: Send the request to SourceKit

    xpc_object_t result = sourcekitd_send_request_sync(request);
    if (xpc_get_type(result) != XPC_TYPE_DICTIONARY ||
        xpc_dictionary_get_count(request) <= 1) {
        return error("couldn't process SourceKit results");
    }

    // 3: Print result

    printf("%s", result.description.UTF8String);

    // Prints
//    <OS_xpc_dictionary: <dictionary: 0x100306190> { count = 9, contents =
//        "key.annotated_decl" => <string: 0x1003039b0> { length = 220, contents = "<Declaration>public class QuerySet&lt;T : <Type usr="c:objc(cs)NSManagedObject">NSManagedObject</Type>&gt; : <Type usr="s:PSs12SequenceType">SequenceType</Type>, <Type usr="s:PSs9Equatable">Equatable</Type></Declaration>" }
//        "key.kind" => <uint64: 0x100306140>: 4311756008
//        "key.usr" => <string: 0x100306700> { length = 21, contents = "s:C8QueryKit8QuerySet" }
//        "key.doc.full_as_xml" => <string: 0x100306bb0> { length = 339, contents = "<Class file="/Users/jp/Projects/QueryKit/QueryKit/QuerySet.swift" line="14" column="14"><Name>QuerySet</Name><USR>s:C8QueryKit8QuerySet</USR><Declaration>public class QuerySet&lt;T : NSManagedObject&gt; : SequenceType, Equatable</Declaration><Abstract><Para>Represents a lazy database lookup for a set of objects.</Para></Abstract></Class>" }
//        "key.offset" => <int64: 0x100306030>: 196
//        "key.typename" => <string: 0x100306740> { length = 13, contents = "QuerySet.Type" }
//        "key.name" => <string: 0x100306fb0> { length = 8, contents = "QuerySet" }
//        "key.filepath" => <string: 0x100306f30> { length = 51, contents = "/Users/jp/Projects/QueryKit/QueryKit/QuerySet.swift" }
//        "key.length" => <int64: 0x100306780>: 8
//    }>
    return 0;
}

int cursorinfo_playground() {

    NSArray *arguments = [[NSProcessInfo processInfo] arguments];
    if (arguments.count < 5) {
        return error("not enough arguments");
    }

    sourcekitd_initialize();

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
        xpc_dictionary_set_string(request, "key.sourcetext", [[NSString stringWithContentsOfFile:arguments[2] encoding:NSUTF8StringEncoding error:nil] UTF8String]);

        xpc_dictionary_set_value(request, "key.compilerargs", compiler_args);

        // 2: Send the request to SourceKit

        xpc_object_t result = sourcekitd_send_request_sync(request);
        if (xpc_get_type(result) != XPC_TYPE_DICTIONARY ||
            xpc_dictionary_get_count(request) <= 1) {
            return error("couldn't process SourceKit results");
        }
    }

    {
        // 1: Build up XPC request to send to SourceKit

        xpc_object_t request = xpc_dictionary_create(NULL, NULL, 0);
        xpc_dictionary_set_uint64(request, "key.request", sourcekitd_uid_get_from_cstr("source.request.cursorinfo"));
        xpc_dictionary_set_string(request, "key.name", playgroundPath.UTF8String);
        xpc_dictionary_set_string(request, "key.sourcefile", playgroundPath.UTF8String);
        xpc_dictionary_set_int64(request, "key.offset", [arguments[4] integerValue]);

        xpc_dictionary_set_value(request, "key.compilerargs", compiler_args);

        // 2: Send the request to SourceKit

        xpc_object_t result = sourcekitd_send_request_sync(request);
        if (xpc_get_type(result) != XPC_TYPE_DICTIONARY ||
            xpc_dictionary_get_count(request) <= 1) {
            return error("couldn't process SourceKit results");
        }

        // 3: Print result

        printf("%s", xpc_dictionary_get_string(result, "key.doc.full_as_xml"));
    }
    return 0;
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
    } else if (arguments.count >= 5 &&
               [arguments[1] isEqualToString:@"--swift_file"] &&
               [arguments[3] isEqualToString:@"--cursor"]) {
        return cursorinfo_playground();
    } else if ([arguments[1] isEqualToString:@"--swift_file"]) {
        return docinfo_for_file();
    } else if ([arguments[1] isEqualToString:@"--file"]) {
        return generate_swift_interface_for_file();
    } else if (arguments.count >= 5 &&
               [arguments[1] isEqualToString:@"--module"] &&
               [arguments[3] isEqualToString:@"--framework_dir"]) {
        return generate_swift_interface_for_module(arguments[2], arguments[4]);
    }

    return error("unable to parse command");
}

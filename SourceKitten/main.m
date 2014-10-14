//
//  main.m
//  SourceKitten
//
//  Created by JP Simard on 7/11/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XPCKit/XPCKit.h>
#import "sourcekitd.h"
#import "SKTCompilerArgumentTransformer.h"

NSString * const CompilerArgumentTransformerName = @"CompilerArgumentTransformer";

int error(const char *message) {
    printf("Error: %s\n\n", message);
    return 1;
}

int docs_for_swift_compiler_args(NSString *compilerArgsString) {
    sourcekitd_initialize();

    NSValueTransformer *valueTransformer = [NSValueTransformer valueTransformerForName:CompilerArgumentTransformerName];
    NSArray *arguments = [valueTransformer transformedValue:compilerArgsString];
    xpc_object_t compilerargs = [arguments newXPCObject];
    
    NSArray *swiftFiles = [arguments filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self endswith '.swift'"]];

    for (NSString *file in swiftFiles) {
        NSMutableSet *seenDocs = [NSMutableSet set];
        
        xpc_object_t cursorInfoRequest = xpc_dictionary_create(NULL, NULL, 0);
        xpc_dictionary_set_uint64(cursorInfoRequest, "key.request", sourcekitd_uid_get_from_cstr("source.request.cursorinfo"));
        xpc_dictionary_set_value(cursorInfoRequest, "key.compilerargs", compilerargs);
        xpc_dictionary_set_string(cursorInfoRequest, "key.sourcefile", file.UTF8String);

        NSUInteger fileLength = [[[NSString alloc] initWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] length];
        
        for (NSUInteger cursor = 0; cursor < fileLength; cursor++) {
            xpc_dictionary_set_int64(cursorInfoRequest, "key.offset", cursor);

            xpc_object_t result = sourcekitd_send_request_sync(cursorInfoRequest);
            if (!sourcekitd_response_is_error(result)) {
                const char *xml = xpc_dictionary_get_string(result, "key.doc.full_as_xml");
                if (xml != nil) {
                    NSString *xmlString = @(xml);
                    NSNumber *xmlHash = @([xmlString hash]);
                    if (![seenDocs containsObject:xmlHash] &&
                        [xmlString rangeOfString:file].location != NSNotFound) {
                        printf("%s\n", xml);
                        [seenDocs addObject:xmlHash];
                    }
                }
            }
        }
    }

    return 0;
}

void initialize_value_transformer() {
    [NSValueTransformer setValueTransformer:[[SKTCompilerArgumentTransformer alloc] init] forName:CompilerArgumentTransformerName];
}

int main(int argc, const char * argv[]) {
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/xcodebuild";
    NSMutableArray *xcodebuild_args = [NSMutableArray arrayWithCapacity:argc+2];
    for (NSUInteger sourcekittenArgIndex = 1; sourcekittenArgIndex < argc; sourcekittenArgIndex++) {
        [xcodebuild_args addObject:@(argv[sourcekittenArgIndex])];
    }
    [xcodebuild_args addObjectsFromArray:@[@"clean", @"build", @"-dry-run"]];

    task.arguments = xcodebuild_args;
    NSPipe *pipe = [NSPipe pipe];
    NSFileHandle *file = pipe.fileHandleForReading;
    task.standardOutput = pipe;
    task.standardError = pipe;

    [task launch];

    NSString *input = [[NSString alloc] initWithData:[file readDataToEndOfFile] encoding:NSUTF8StringEncoding];
    [file closeFile];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"/usr/bin/swiftc.*" options:0 error:nil];
    NSTextCheckingResult *regexMatch = [regex firstMatchInString:input options:0 range:NSMakeRange(0, input.length)];
    if (regexMatch) {
        initialize_value_transformer();
        return docs_for_swift_compiler_args([input substringWithRange:regexMatch.range]);
    } else {
        error(input.UTF8String);
    }
    return 0;
}

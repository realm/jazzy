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

/*
 Print error message to STDERR
 */
int error(NSString *message) {
    // FIXME: Should print to STDERR
    printf("Error: %s\n\n", message.UTF8String);
    return 1;
}

/*
 Print XML-formatted docs for the specified Xcode project
 */
int docs_for_swift_compiler_args(NSArray *arguments) {
    printf("<jazzy>\n"); // Opening tag

    sourcekitd_initialize();

    // Only create the XPC array of compiler arguments once, to be reused for each request
    xpc_object_t compilerargs = [arguments newXPCObject];

    // Filter the array of compiler arguments to extract the Xcode project's Swift files
    NSArray *swiftFiles = [arguments filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self endswith '.swift'"]];

    // Print docs for each Swift file
    for (NSString *file in swiftFiles) {
        // Keep track of XML documentation we've already printed
        NSMutableSet *seenDocs = [NSMutableSet set];

        // Construct a SourceKit request for getting the "full_as_xml" docs
        xpc_object_t cursorInfoRequest = xpc_dictionary_create(NULL, NULL, 0);
        xpc_dictionary_set_uint64(cursorInfoRequest, "key.request", sourcekitd_uid_get_from_cstr("source.request.cursorinfo"));
        xpc_dictionary_set_value(cursorInfoRequest, "key.compilerargs", compilerargs);
        xpc_dictionary_set_string(cursorInfoRequest, "key.sourcefile", file.UTF8String);

        NSUInteger fileLength = [[[NSString alloc] initWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] length];

        // Send "cursorinfo" SourceKit request for each cursor position in the current file.
        //
        // This is the same request triggered by Option-clicking a token in Xcode,
        // so we are also generating documentation for code that is external to the current project,
        // which is why we filter out docs from outside this file.
        for (NSUInteger cursor = 0; cursor < fileLength; cursor++) {
            xpc_dictionary_set_int64(cursorInfoRequest, "key.offset", cursor);

            // Send request and wait for response
            xpc_object_t response = sourcekitd_send_request_sync(cursorInfoRequest);
            if (!sourcekitd_response_is_error(response)) {
                // Grab XML from response
                const char *xml = xpc_dictionary_get_string(response, "key.doc.full_as_xml");
                if (xml != nil) {
                    // Print XML docs if we haven't already & only if it relates to the current file we're documenting
                    NSString *xmlString = @(xml);
                    if (![seenDocs containsObject:xmlString] &&
                        [xmlString rangeOfString:file].location != NSNotFound) {
                        printf("%s\n", xml);
                        [seenDocs addObject:xmlString];
                    }
                }
            }
        }
    }
    printf("</jazzy>\n"); // Closing tag
    return 0;
}

/*
 Run `xcodebuild clean build -dry-run` along with any passed in build arguments.
 Return STDERR and STDOUT as a combined string.
 */
NSString *run_xcodebuild(int argc, const char * argv[]) {
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/xcodebuild";

    NSMutableArray *xcodebuild_args = [NSMutableArray arrayWithCapacity:argc+2];
    for (NSUInteger sourcekittenArgIndex = 1; sourcekittenArgIndex < argc; sourcekittenArgIndex++) {
        [xcodebuild_args addObject:@(argv[sourcekittenArgIndex])];
    }
    [xcodebuild_args addObjectsFromArray:@[@"clean", @"build", @"-dry-run"]];

    task.arguments = xcodebuild_args;
    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    task.standardError = pipe;

    [task launch];

    NSFileHandle *file = pipe.fileHandleForReading;
    NSString *xcodebuildOutput = [[NSString alloc] initWithData:[file readDataToEndOfFile] encoding:NSUTF8StringEncoding];
    [file closeFile];
    return xcodebuildOutput;
}

/*
 Parses the compiler arguments needed to compile the Swift aspects of an Xcode project
 */
NSArray *swiftc_arguments_from_xcodebuild_output(NSString *xcodebuildOutput) {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"/usr/bin/swiftc.*" options:0 error:nil];
    NSTextCheckingResult *regexMatch = [regex firstMatchInString:xcodebuildOutput options:0 range:NSMakeRange(0, xcodebuildOutput.length)];
    if (regexMatch) {
        [NSValueTransformer setValueTransformer:[[SKTCompilerArgumentTransformer alloc] init] forName:CompilerArgumentTransformerName];
        NSValueTransformer *valueTransformer = [NSValueTransformer valueTransformerForName:CompilerArgumentTransformerName];
        NSString *matchString = [xcodebuildOutput substringWithRange:regexMatch.range];
        return [valueTransformer transformedValue:matchString];
    }
    return nil;
}

/*
 Print XML-formatted docs for the specified Xcode project,
 or Xcode output if no Swift compiler arguments were found.
 */
int main(int argc, const char * argv[]) {
    NSString *xcodebuildOutput = run_xcodebuild(argc, argv);
    NSArray *swiftcArguments = swiftc_arguments_from_xcodebuild_output(xcodebuildOutput);

    if (swiftcArguments) {
        return docs_for_swift_compiler_args(swiftcArguments);
    }

    return error(xcodebuildOutput);
}

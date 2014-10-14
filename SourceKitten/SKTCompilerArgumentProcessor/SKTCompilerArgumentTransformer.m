//
//  SKTCompilerArgumentTransformer.m
//  SourceKitten
//
//  Created by Simone Civetta on 11/10/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import "SKTCompilerArgumentTransformer.h"

@implementation SKTCompilerArgumentTransformer

+ (Class)transformedValueClass
{
    return [NSArray class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)arguments
{
    return (arguments == nil) ? nil : [self process:arguments];
}

- (NSArray *)process:(NSString *)arguments
{
    NSString *compilerArgsString = [arguments stringByReplacingOccurrencesOfString:@"\\ " withString:@"\\\u00a0"];
    NSMutableArray *argumentArray = [[compilerArgsString componentsSeparatedByString:@" "] mutableCopy];

    NSMutableArray *toRemove = [@[] mutableCopy];
    for (NSUInteger i = 0; i < [argumentArray count]; i++) {
        argumentArray[i] = [argumentArray[i] stringByReplacingOccurrencesOfString:@"\\\u00a0" withString:@"\\ "];
        if ([argumentArray[i] isEqualToString:@"-parseable-output"]) {
            [toRemove addObject:argumentArray[i]];
        }
    }

    [argumentArray removeObjectsInArray:toRemove];

    NSArray *unescapedArguments = [argumentArray subarrayWithRange:NSMakeRange(1, argumentArray.count - 1)];
    return unescapedArguments;
}

@end

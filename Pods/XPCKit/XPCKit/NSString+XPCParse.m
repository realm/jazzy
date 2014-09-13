//
//  NSString+XPCParse.m
//  XPCKit
//
//  Created by Steve Streza on 7/25/11. Copyright 2011 XPCKit.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "NSString+XPCParse.h"

@implementation NSString (XPCParse)

+(NSString *)stringWithXPCObject:(xpc_object_t)xpc{
    return [NSString stringWithUTF8String:xpc_string_get_string_ptr(xpc)];
}

-(xpc_object_t)newXPCObject{
    return xpc_string_create([self cStringUsingEncoding:NSUTF8StringEncoding]);
}

@end

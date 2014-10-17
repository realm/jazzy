//
//  NSDate+XPCParse.m
//  XPCKit
//
//  Created by Steve Streza on 9/11/11. Copyright 2011 XPCKit.
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

#import "NSDate+XPCParse.h"
#import <xpc/xpc.h>

@implementation NSDate (XPCParse)

+(NSDate *)dateWithXPCObject:(xpc_object_t)xpc{
	int64_t nanosecondsInterval = xpc_date_get_value(xpc);
	NSTimeInterval interval = nanosecondsInterval / 1000000000.;
	return [NSDate dateWithTimeIntervalSince1970:interval];
	
}

-(xpc_object_t)newXPCObject{
	return xpc_date_create((int64_t)([self timeIntervalSince1970] * 1000000000));
}

@end

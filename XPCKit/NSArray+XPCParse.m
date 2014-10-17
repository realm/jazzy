//
//  NSArray+XPCParse.m
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

#import "NSArray+XPCParse.h"
#import "XPCExtensions.h"

@implementation NSArray (XPCParse)

+(NSArray *)arrayWithContentsOfXPCObject:(xpc_object_t)object{
	NSMutableArray *array = [NSMutableArray array];
	xpc_array_apply(object, ^_Bool(size_t index, xpc_object_t value) {
		id nsValue = [NSObject objectWithXPCObject:value];
		if(nsValue){
			[array insertObject:nsValue atIndex:index];
		}
		return true;
	});
	return [[array copy] autorelease];
}

-(xpc_object_t)newXPCObject{
	xpc_object_t array = xpc_array_create(NULL, 0);
	[self enumerateObjectsUsingBlock:^(id value, NSUInteger index, BOOL *stop) {
		if([value respondsToSelector:@selector(newXPCObject)]){
			xpc_object_t xpcValue = [value newXPCObject];
			xpc_array_set_value(array, XPC_ARRAY_APPEND, xpcValue);
			xpc_release(xpcValue);
		}
	}];
	return array;
}

@end

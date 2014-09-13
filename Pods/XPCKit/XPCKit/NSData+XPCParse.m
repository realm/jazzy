//
//  NSData+XPCParse.m
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

#import "NSData+XPCParse.h"

@implementation NSData (XPCParse)

+(NSData *)dataWithXPCObject:(xpc_object_t)xpcObject{
    NSData *data = nil;
    xpc_type_t type = xpc_get_type(xpcObject);

	// NOTE: mmap'd files do not work right now, this returns inconsistently-sized files for some reason.
	// Only remove the "NO &&" if you know what you're doing.
	if(NO && type == XPC_TYPE_SHMEM){
		void *buffer = NULL;
		size_t length = xpc_shmem_map(xpcObject, &buffer);
		if(length > 0){
			data = [NSData dataWithBytesNoCopy:buffer length:length freeWhenDone:NO];
		}
	}else if(type == XPC_TYPE_DATA){
		data =  [NSData dataWithBytes:xpc_data_get_bytes_ptr(xpcObject)
							   length:xpc_data_get_length(xpcObject)];
	}
	return data;
}

-(xpc_object_t)newXPCObject{
    return xpc_data_create([self bytes], [self length]);
}

@end

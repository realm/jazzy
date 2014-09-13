//
//  NSFileHandle+XPCParse.m
//  XPCKit
//
//  Created by Steve Streza on 9/10/11. Copyright 2011 XPCKit.
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

#import "NSFileHandle+XPCParse.h"

@implementation NSFileHandle (XPCParse)

+(NSFileHandle *)fileHandleWithXPCObject:(xpc_object_t)xpc{
	int fd = xpc_fd_dup(xpc);
	NSFileHandle *handle = [[[NSFileHandle alloc] initWithFileDescriptor:fd closeOnDealloc:YES] autorelease];
	return handle;
}

-(xpc_object_t)newXPCObject{
	int fd = [self fileDescriptor];
	xpc_object_t object = xpc_fd_create(fd);
	return object;
}

@end

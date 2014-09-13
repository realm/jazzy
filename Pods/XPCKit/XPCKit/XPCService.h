//
//  XPCService.h
//  XPCKit
//
//  Created by Steve Streza on 7/27/11. Copyright 2011 XPCKit.
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

#import <Foundation/Foundation.h>
#import "XPCTypes.h"
#import "XPCConnection.h"

@interface XPCService : NSObject {
    NSArray *_connections;
    XPCConnectionHandler _connectionHandler;
}

@property (nonatomic, copy) XPCConnectionHandler connectionHandler;
@property (nonatomic, readonly) NSArray *connections;

+(void)runServiceWithConnectionHandler:(XPCConnectionHandler)connectionHandler;
-(id)initWithConnectionHandler:(XPCConnectionHandler)connectionHandler;

-(void)handleConnection:(XPCConnection *)connection;

+(void)runService;

@end

// You can supply this as the parameter to xpc_main (but you might as
// well just call +[XPService runServiceWithConnectionHandler:])
static void XPCServiceConnectionHandler(xpc_connection_t handler);
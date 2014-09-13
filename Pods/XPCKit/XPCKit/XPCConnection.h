//
//  XPCConnection.h
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

#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>
#import "XPCTypes.h"

@interface XPCConnection : NSObject{
    xpc_connection_t _connection;
	dispatch_queue_t _dispatchQueue;
    XPCEventHandler _eventHandler;
    XPCConnectionHandler _connectionHandler;
}

- (id)initWithMachName:(NSString *)name listener:(BOOL)listen;
- (id)initWithServiceName:(NSString *)serviceName;
- (id)initWithConnection: (xpc_connection_t)connection;

@property (nonatomic, copy)        XPCEventHandler eventHandler;
@property (nonatomic, copy)   XPCConnectionHandler connectionHandler;

@property (nonatomic, readonly)   xpc_connection_t connection;
@property (nonatomic, assign)     dispatch_queue_t dispatchQueue;

// connection properties
@property (nonatomic, readonly) NSString *connectionName;
@property (nonatomic, readonly) NSNumber *connectionEUID;
@property (nonatomic, readonly) NSNumber *connectionEGID;
@property (nonatomic, readonly) NSNumber *connectionProcessID;
@property (nonatomic, readonly) NSString *connectionAuditSessionID;

-(void)sendMessage:(NSDictionary *)message;

-(void)suspend;
-(void)resume;

// handling connections
-(void)receiveConnection:(xpc_connection_t)connection;
@end

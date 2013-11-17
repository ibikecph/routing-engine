//
//  SMAPIOperation.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 17/11/2013.
//  Copyright (C) 2013 City of Copenhagen.
//
//  This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
//  If a copy of the MPL was not distributed with this file, You can obtain one at
//  http://mozilla.org/MPL/2.0/.
//

#import <Foundation/Foundation.h>

@class SMAPIOperation;

@protocol SMAPIOperationDelegate <NSObject>
- (void)queuedRequest:(SMAPIOperation*) object failedWithError:(NSError*)error;
- (void)queuedRequest:(SMAPIOperation*) object finishedWithResult:(id)result;
@end

#define URL_CONNECTION_TIMEOUT 15.0f

@interface SMAPIOperation : NSOperation

@property (nonatomic, weak) id<SMAPIOperationDelegate> delegate;
@property (nonatomic, strong) NSTimer * timeoutTimer;
@property (nonatomic, strong) NSDictionary * startParams;
@property (nonatomic, strong) NSMutableData * responseData;
@property (nonatomic, strong) NSURLConnection * conn;
@property (nonatomic, strong) NSArray * results;

@property BOOL finished;
@property BOOL inProgress;
@property BOOL isStopped;

@property NSInteger statusCode;
@property (nonatomic, strong) NSString * searchString;

- (void)terminate;
- (void)timeoutCancel:(NSTimer*)timer;

- (id)initWithData:(NSDictionary*)d andDelegate:(id<SMAPIOperationDelegate>)dlg;

@end

//
//  SMAPIOperation.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 17/11/2013.
//  Copyright (C) 2013 City of Copenhagen.  All rights reserved.
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

/**
 * \ingroup libs
 * \ingroup api
 * API operation base class
 */
@interface SMAPIOperation : NSOperation

@property (nonatomic, weak) id<SMAPIOperationDelegate> delegate;
@property (nonatomic, strong) NSTimer * timeoutTimer;
@property (nonatomic, strong) NSObject<SearchListItem> *startItem;
@property (nonatomic, strong) NSMutableData * responseData;
@property (nonatomic, strong) NSURLConnection * conn;
@property (nonatomic, strong) NSArray * results;

@property BOOL taskFinished;
@property BOOL inProgress;
@property BOOL isStopped;

@property NSInteger statusCode;
@property (nonatomic, strong) NSString * searchString;

- (void)terminate;
- (void)timeoutCancel:(NSTimer*)timer;

- (id)initWithItem:(NSObject<SearchListItem> *)item andDelegate:(id<SMAPIOperationDelegate>)dlg;

@end

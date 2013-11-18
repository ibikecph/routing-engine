//
//  SMAPIOperation.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 17/11/2013.
//  Copyright (C) 2013 City of Copenhagen.
//
//  This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
//  If a copy of the MPL was not distributed with this file, You can obtain one at
//  http://mozilla.org/MPL/2.0/.
//

#import "SMAPIOperation.h"

@interface SMAPIOperation()
@end

@implementation SMAPIOperation

- (id)initWithData:(NSDictionary*)d andDelegate:(id<SMAPIOperationDelegate>)dlg {
    self = [super init];
    if (self) {
        [self setDelegate:dlg];
        self.startParams = [d objectForKey:@"params"];
    }
    return self;
}

#pragma mark - NSOperation stuff

- (void)startOperation {
    assert(@"Must override this!");
}

- (void)start {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
        return;
    }
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    self.finished = NO;
    self.inProgress = YES;
    [self didChangeValueForKey:@"isFinished"];
    [self didChangeValueForKey:@"isExecuting"];
    self.responseData = [NSMutableData data];
    if (![self finishIfCanceled]) {
        [self startOperation];
        self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:URL_CONNECTION_TIMEOUT target:self selector:@selector(timeoutCancel:) userInfo:nil repeats:NO];
    } else {
        [self terminate];
    }
}

- (void)terminate {
    if (self.timeoutTimer) {
        [self.timeoutTimer invalidate];
        self.timeoutTimer = nil;
    }
    [self willChangeValueForKey:@"isFinished"];
	[self willChangeValueForKey:@"isExecuting"];
	self.finished = YES;
	self.inProgress = NO;
	[self didChangeValueForKey:@"isExecuting"];
	[self didChangeValueForKey:@"isFinished"];
}

- (void)timeoutCancel:(NSTimer*)timer {
    [self cancel];
}

#pragma mark - NSOperation state Delegate methods
- (BOOL)isConcurrent {
	return YES;
}

- (BOOL)isExecuting {
	return self.inProgress;
}

- (BOOL)isFinished {
	return self.finished;
}

- (BOOL)isCancelled {
	return self.isStopped;
}

- (void)cancel {
    if (self.timeoutTimer) {
        [self.timeoutTimer invalidate];
        self.timeoutTimer = nil;
    }
    self.delegate = nil;
    [self willChangeValueForKey:@"isCancelled"];
    self.isStopped = YES;
	[self didChangeValueForKey:@"isCancelled"];
    if (self.isExecuting) {
        [self terminate];
    }
}

- (BOOL) finishIfCanceled{
    if ([self isCancelled]){
        [self terminate];
        return YES;
    }
    return NO;
}

#pragma mark - download delegate

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse*)response {
    if (self.isCancelled) {
        [connection cancel];
        [self terminate];
        return;
    }
    if (self.timeoutTimer) {
        [self.timeoutTimer invalidate];
        self.timeoutTimer = nil;
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if (self.isCancelled) {
        [connection cancel];
        [self terminate];
        return;
    }
    if (self.timeoutTimer) {
        [self.timeoutTimer invalidate];
        self.timeoutTimer = nil;
    }
    [self.responseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    if (self.timeoutTimer) {
        [self.timeoutTimer invalidate];
        self.timeoutTimer = nil;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(queuedRequest:failedWithError:)]) {
            [self.delegate queuedRequest:self failedWithError:error];
        }
    });
    [self terminate];
}

- (void)processResult:(id)result {
    assert(@"Must override this!");
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if (self.timeoutTimer) {
        [self.timeoutTimer invalidate];
        self.timeoutTimer = nil;
    }
    if (self.isCancelled) {
        [connection cancel];
        [self terminate];
        return;
    }
    if (self.responseData) {
        /**
         * process data
         */
        id result = [NSJSONSerialization JSONObjectWithData:self.responseData options:NSJSONReadingAllowFragments error:NULL];
        if (result) {
            NSString * s = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
            debugLog(@"***          result: %@", s);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self processResult:result];
                if (self.delegate && [self.delegate respondsToSelector:@selector(queuedRequest:finishedWithResult:)]) {
                    [self.delegate queuedRequest:self finishedWithResult:self.results];
                }
            });            
        }
    }
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    self.finished = YES;
    self.inProgress = NO;
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
    [self terminate];
}

@end

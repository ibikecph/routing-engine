//
//  SMAPIQueue.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 17/11/2013.
//  Copyright (C) 2013 City of Copenhagen.  All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
//  If a copy of the MPL was not distributed with this file, You can obtain one at
//  http://mozilla.org/MPL/2.0/.
//

#import "SMAPIQueue.h"

@implementation SMAPIQueue

#define MAX_CONCURENT_OPERATIONS 4

- (id)initWithMaxOperations:(NSInteger)maxOps {
    self = [super init];
	if (self) {
        [self setQueue:[[NSOperationQueue alloc] init]];
        self.queue.name = @"API queue";
        if (maxOps == 0) {
            [self.queue setMaxConcurrentOperationCount:MAX_CONCURENT_OPERATIONS];
        } else {
            [self.queue setMaxConcurrentOperationCount:maxOps];
        }
    [self.queue addObserver:self forKeyPath:@"operations" options:NSKeyValueObservingOptionNew context:NULL];
    }
    return self;
}

- (void)sleepOperationBody; {
    sleep(0.5f);
}

- (void)addTasks:(NSString *)srchString {
    UnknownSearchListItem *item = [SMAddressParser parseAddress:srchString];
    if ((item.number == nil || [item.number isEqualToString:@""]) &&
        (item.city == nil || [item.city isEqualToString:@""]) &&
        (item.zip == nil || [item.zip isEqualToString:@""])) {
        [self addKMSPlacesTask:item];
        [self addKMSStreetTask:item];
    } else {
        [self addKMSAddressTask:item];
    }
    
    if ((item.number == nil || [item.number isEqualToString:@""]) && srchString.length > 2) {
        [self addFoursquareTask:item];
    }
}

- (SMFoursquareOperation*)addFoursquareTask:(NSObject<SearchListItem> *)item {
//    @synchronized (self.queue) {
        SMFoursquareOperation * task = [[SMFoursquareOperation alloc] initWithItem:item andDelegate:self];
        [task setQueuePriority:NSOperationQueuePriorityNormal];
        [self.queue addOperation:task];
        return task;
//    }
    return nil;
}

- (SMKMSStreetOperation*)addKMSStreetTask:(NSObject<SearchListItem> *)item {
//    @synchronized (self.queue) {
        SMKMSStreetOperation * task = [[SMKMSStreetOperation alloc] initWithItem:item andDelegate:self];
        [task setQueuePriority:NSOperationQueuePriorityNormal];
        [self.queue addOperation:task];
        return task;
//    }
    return nil;
}

- (SMKMSAddressOperation*)addKMSAddressTask:(NSObject<SearchListItem> *)item {
//    @synchronized (self.queue) {
        SMKMSAddressOperation * task = [[SMKMSAddressOperation alloc] initWithItem:item andDelegate:self];
        [task setQueuePriority:NSOperationQueuePriorityNormal];
        [self.queue addOperation:task];
        return task;
//    }
    return nil;
}

- (SMKMSPlacesOperation*)addKMSPlacesTask:(NSObject<SearchListItem> *)item {
//    @synchronized (self.queue) {
        SMKMSPlacesOperation * task = [[SMKMSPlacesOperation alloc] initWithItem:item andDelegate:self];
        [task setQueuePriority:NSOperationQueuePriorityNormal];
        [self.queue addOperation:task];
        return task;
//    }
    return nil;
}


- (void)cancelTask:(SMAPIOperation*)task {
    @synchronized(self.queue) {
        [task cancel];
    }
}

#pragma mark - file download delegate

- (void)stopAllRequests {
//    @synchronized(self.queue) {
        [self.queue cancelAllOperations];
        debugLog(@"Cancel all operations!");
//    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.queue && [keyPath isEqualToString:@"operations"]) {
        debugLog(@"Operations queue: %@ count: %d", self.queue, self.queue.operationCount);
    }
}

#pragma mark - api operations delegate

- (void)queuedRequest:(SMAPIOperation *)object failedWithError:(NSError *)error {
    @synchronized(self.queue) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(queuedRequest:failedWithError:)]) {
            [self.delegate queuedRequest:object failedWithError:error];
        }
    }
}

- (void)queuedRequest:(SMAPIOperation *)object finishedWithResult:(id)result {
    @synchronized(self.queue) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(queuedRequest:finishedWithResult:)]) {
            [self.delegate queuedRequest:object finishedWithResult:result];
        }
    }
}

@end

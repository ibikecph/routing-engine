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
        self.queue.maxConcurrentOperationCount = maxOps ?: MAX_CONCURENT_OPERATIONS;
        [self.queue addObserver:self forKeyPath:@"operations" options:NSKeyValueObservingOptionNew context:NULL];
    }
    return self;
}

- (void)addTasks:(NSString *)searchString {
    UnknownSearchListItem *item = [SMAddressParser parseAddress:searchString];
    if (item.number.length == 0 &&
        item.city.length == 0 &&
        item.zip.length == 0) {
        [self addKMSPlacesTask:item];
        [self addKMSStreetTask:item];
    } else {
        [self addKMSAddressTask:item];
    }
    
    if (item.number.length == 0 && searchString.length > 2) {
        [self addFoursquareTask:item];
    }
}

- (SMFoursquareOperation*)addFoursquareTask:(NSObject<SearchListItem> *)item {
    SMFoursquareOperation * task = [[SMFoursquareOperation alloc] initWithItem:item andDelegate:self];
    [task setQueuePriority:NSOperationQueuePriorityNormal];
    [self.queue addOperation:task];
    return task;
}

- (SMKMSStreetOperation*)addKMSStreetTask:(NSObject<SearchListItem> *)item {
    SMKMSStreetOperation * task = [[SMKMSStreetOperation alloc] initWithItem:item andDelegate:self];
    [task setQueuePriority:NSOperationQueuePriorityNormal];
    [self.queue addOperation:task];
    return task;
}

- (SMKMSAddressOperation*)addKMSAddressTask:(NSObject<SearchListItem> *)item {
    SMKMSAddressOperation * task = [[SMKMSAddressOperation alloc] initWithItem:item andDelegate:self];
    [task setQueuePriority:NSOperationQueuePriorityNormal];
    [self.queue addOperation:task];
    return task;
}

- (SMKMSPlacesOperation*)addKMSPlacesTask:(NSObject<SearchListItem> *)item {
    SMKMSPlacesOperation * task = [[SMKMSPlacesOperation alloc] initWithItem:item andDelegate:self];
    [task setQueuePriority:NSOperationQueuePriorityNormal];
    [self.queue addOperation:task];
    return task;
}

- (void)cancelTask:(SMAPIOperation*)task {
    @synchronized(self.queue) {
        [task cancel];
    }
}

#pragma mark - file download delegate

- (void)stopAllRequests {
    [self.queue cancelAllOperations];
    debugLog(@"Cancel all operations!");
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.queue && [keyPath isEqualToString:@"operations"]) {
        debugLog(@"Operations queue: %@ count: %ld", self.queue, self.queue.operationCount);
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

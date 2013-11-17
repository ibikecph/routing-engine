//
//  SMAPIQueue.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 17/11/2013.
//  Copyright (C) 2013 City of Copenhagen.
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
//    [self.queue addObserver:self forKeyPath:@"operations" options:NSKeyValueObservingOptionNew context:NULL];
    }
    return self;
}

- (void)sleepOperationBody; {
    sleep(0.5f);
}

- (void)addTasks:(NSString *)srchString {
    NSDictionary * d = [SMAddressParser parseAddress:srchString];
    [self addFoursquareTask:@{@"params" : @{@"text" : srchString}}];
    if ([d objectForKey:@"number"] == nil && [d objectForKey:@"city"] == nil && [d objectForKey:@"zip"] == nil) {
        [self addKMSPlacesTask:@{@"params" : d}];
        [self addKMSStreetTask:@{@"params" : d}];
    } else {
        [self addKMSAddressTask:@{@"params" : d}];
    }
}

- (SMFoursquareOperation*)addFoursquareTask:(NSDictionary*)taskDict {
    @synchronized (self.queue) {
        SMFoursquareOperation * task = [[SMFoursquareOperation alloc] initWithData:taskDict andDelegate:self.delegate];
        [task setQueuePriority:NSOperationQueuePriorityNormal];
        [self.queue addOperation:task];
        return task;
    }
    return nil;
}

- (SMKMSStreetOperation*)addKMSStreetTask:(NSDictionary*)taskDict {
    @synchronized (self.queue) {
        SMKMSStreetOperation * task = [[SMKMSStreetOperation alloc] initWithData:taskDict andDelegate:self.delegate];
        [task setQueuePriority:NSOperationQueuePriorityNormal];
        [self.queue addOperation:task];
        return task;
    }
    return nil;
}

- (SMKMSAddressOperation*)addKMSAddressTask:(NSDictionary*)taskDict {
    @synchronized (self.queue) {
        SMKMSAddressOperation * task = [[SMKMSAddressOperation alloc] initWithData:taskDict andDelegate:self.delegate];
        [task setQueuePriority:NSOperationQueuePriorityNormal];
        [self.queue addOperation:task];
        return task;
    }
    return nil;
}

- (SMKMSPlacesOperation*)addKMSPlacesTask:(NSDictionary*)taskDict {
    @synchronized (self.queue) {
        SMKMSPlacesOperation * task = [[SMKMSPlacesOperation alloc] initWithData:taskDict andDelegate:self.delegate];
        [task setQueuePriority:NSOperationQueuePriorityNormal];
        [self.queue addOperation:task];
        return task;
    }
    return nil;
}


- (void)cancelTask:(SMAPIOperation*)task {
    @synchronized(self.queue) {
        [task cancel];
    }
}

#pragma mark - file download delegate

- (void)stopAllRequests {
    @synchronized(self.queue) {
        [self.queue cancelAllOperations];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.queue && [keyPath isEqualToString:@"operations"]) {
        debugLog(@"Operations queue: %@ count: %d", self.queue, self.queue.operationCount);
    }
}


@end

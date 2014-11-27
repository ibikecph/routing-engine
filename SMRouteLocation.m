//
//  SMRouteLocation.m
//  I Bike CPH
//
//  Created by Tobias Due Munk on 27/11/14.
//  Copyright (c) 2014 I Bike CPH. All rights reserved.
//

#import "SMRouteLocation.h"

@implementation SMRouteLocation

- (instancetype)initWithLocation:(CLLocation *)location date:(NSDate *)date
{
    self = [super init];
    if (self) {
        self.location = location;
        self.date = date;
    }
    return self;
}

@end
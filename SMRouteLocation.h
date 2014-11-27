//
//  SMRouteLocatio.h
//  I Bike CPH
//
//  Created by Tobias Due Munk on 27/11/14.
//  Copyright (c) 2014 I Bike CPH. All rights reserved.
//

#import <Foundation/Foundation.h>

@import CoreLocation;

@interface SMRouteLocation : NSObject

@property (strong, nonatomic) CLLocation *location;
@property (strong, nonatomic) NSDate *date;

- (instancetype)initWithLocation:(CLLocation *)location date:(NSDate *)date;

@end

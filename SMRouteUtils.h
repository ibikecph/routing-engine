//
//  SMRouteUtils.h
//  testRouteMe
//
//  Created by Rasko Gojkovic on 6/10/13.
//  Copyright (c) 2013 Rasko Gojkovic. All rights reserved.
//

#import <Foundation/Foundation.h>

#define POINTS_EXACT_NAME 20
#define POINTS_EXACT_ADDRESS 10
#define POINTS_PART_NAME 1
#define POINTS_PART_ADDRESS 1
#define MINIMUM_PASS_LENGTH 3

@interface SMRouteUtils : NSObject


// Format distance string (choose between meters and kilometers)
NSString *formatDistance(float distance);
// Format time duration string (choose between seconds and hours)
NSString *formatTime(float seconds);
// Format time passed between two dates
NSString *formatTimePassed(NSDate *startDate, NSDate *endDate);
// Calculate how many calories are burned given speed and time spent cycling
float caloriesBurned(float avgSpeed, float timeSpent);
// Calculate expected arrival time
NSString *expectedArrivalTime(NSInteger seconds);

NSString *formatTimeLeft(NSInteger seconds);

+ (NSString*)routeFilenameFromTimestampForExtension:(NSString*) ext;

+ (NSInteger)pointsForName:(NSString*)name andAddress:(NSString*)address andTerms:(NSString*)srchString;

@end

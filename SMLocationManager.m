//
//  SMLocationManager.m
//  TestMap
//
//  Created by Ivan Pavlovic on 11/1/12.
//  Copyright (C) 2013 City of Copenhagen.  All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
//  If a copy of the MPL was not distributed with this file, You can obtain one at 
//  http://mozilla.org/MPL/2.0/.
//

#import "SMLocationManager.h"
#import <CoreLocation/CoreLocation.h>

@implementation SMLocationManager

@synthesize hasValidLocation, lastValidLocation, locationServicesEnabled;

+ (SMLocationManager *)instance {
	static SMLocationManager *instance;
	
	if (instance == nil) {
		instance = [[SMLocationManager alloc] init];
	}
	
	return instance;
}

- (id)init {
	self = [super init];
	
	if (self != nil)
	{
		hasValidLocation = NO;
		locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        locationManager.distanceFilter = kCLDistanceFilterNone;
		
        locationServicesEnabled = NO;
        [locationManager requestAlwaysAuthorization];
	}
	return self;
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusAuthorizedAlways) {
        
        [locationManager startUpdatingLocation];
        [locationManager startMonitoringSignificantLocationChanges];
        
        locationServicesEnabled = YES;
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
   
    CLLocation *lastLocation = locations.lastObject;
    
	hasValidLocation = NO;
	lastValidLocation = nil;
	
	if (!signbit(lastLocation.horizontalAccuracy)) {
		hasValidLocation = YES;
		lastValidLocation = lastLocation;
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshPosition" object:self userInfo:@{@"locations" : locations}];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
	NSLog(@"didFailWithError");
	if ([error domain] == kCLErrorDomain)
	{
		switch ([error code])
		{
			case kCLErrorDenied:
				[locationManager stopUpdatingLocation];
                locationServicesEnabled = NO;
                NSLog(@"Location services denied!");
				break;
			case kCLErrorLocationUnknown:
                NSLog(@"Location unknown!");
				break;
            default:
                NSLog(@"Location error: %@", error.localizedDescription);
		}
	}
}

#pragma mark  - location service


- (void)start {
    if (locationManager != nil) {
        [locationManager requestAlwaysAuthorization];
        [locationManager startUpdatingLocation];
        [locationManager startMonitoringSignificantLocationChanges];
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    }
}

- (void)idle {
    if (locationManager != nil) {
        [locationManager requestAlwaysAuthorization];
        [locationManager startUpdatingLocation];
        [locationManager startMonitoringSignificantLocationChanges];
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
    }
}

- (void)stop {
    if (locationManager != nil) {
        [locationManager stopUpdatingLocation];
        [locationManager stopMonitoringSignificantLocationChanges];
    }
}




@end

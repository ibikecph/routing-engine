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
		
		BOOL enabled;
		/*if([locationManager respondsToSelector:@selector(locationServicesEnabled)]){
         enabled = [locationManager locationServicesEnabled];
         } else {
         enabled = locationManager.locationServicesEnabled;
         }*/
        
        if ([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            locationServicesEnabled = NO;
            [locationManager requestWhenInUseAuthorization];
        } else {
            
            enabled = [CLLocationManager locationServicesEnabled];
            
            if (enabled == YES) {
                [locationManager startUpdatingLocation];
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopLocationService:)  name:UIApplicationDidEnterBackgroundNotification object:nil];
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartLocationService:) name:UIApplicationWillEnterForegroundNotification object:nil];
            }
            locationServicesEnabled = YES;
        }
        
	}
	return self;
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        
        [locationManager startUpdatingLocation];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopLocationService:)  name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartLocationService:) name:UIApplicationWillEnterForegroundNotification object:nil];
        
        locationServicesEnabled = YES;
        
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
	hasValidLocation = NO;
	lastValidLocation = nil;
	
	if (!signbit(newLocation.horizontalAccuracy)) {
		hasValidLocation = YES;
		lastValidLocation = newLocation;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshPosition" object:nil];
	}
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
		}
	}
}

#pragma mark  - location service


- (void)stopLocationService:(UIApplication *)application {
    if (locationManager != nil) {
        [locationManager stopUpdatingLocation];
        [locationManager stopUpdatingHeading];
    }
}


- (void)restartLocationService:(UIApplication *)application {
    if (locationManager != nil) {
        if ([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [locationManager requestWhenInUseAuthorization];
        }
        [locationManager startUpdatingLocation];
        [locationManager startUpdatingHeading];
    }
}

@end

//
//  SMLocationManager.h
//  TestMap
//
//  Created by Ivan Pavlovic on 11/1/12.
//  Copyright (C) 2013 City of Copenhagen.
//
//  This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
//  If a copy of the MPL was not distributed with this file, You can obtain one at 
//  http://mozilla.org/MPL/2.0/.
//

#import <Foundation/Foundation.h> 
#import <CoreLocation/CoreLocation.h>

@interface SMLocationManager : NSObject<CLLocationManagerDelegate>
{
	CLLocationManager *locationManager;
	CLLocation *lastValidLocation;
	BOOL hasValidLocation;
    BOOL locationServicesEnabled;
}

@property (readonly, nonatomic) BOOL hasValidLocation;
@property (readonly, nonatomic) CLLocation *lastValidLocation;
@property BOOL locationServicesEnabled;


+ (SMLocationManager *)instance;
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation;

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error;

@end

//
//  SMGPSUtil.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 05/03/2013.
//  Copyright (C) 2013 City of Copenhagen.  All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
//  If a copy of the MPL was not distributed with this file, You can obtain one at 
//  http://mozilla.org/MPL/2.0/.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface SMGPSUtil : NSObject

// Calculates distance between location C and path AB in meters.
double distanceFromLineInMeters(CLLocationCoordinate2D C, CLLocationCoordinate2D A, CLLocationCoordinate2D B);

CLLocationCoordinate2D closestCoordinate(CLLocationCoordinate2D C, CLLocationCoordinate2D A, CLLocationCoordinate2D B);

/**
 * Compares coordinates of two CLLocations - returnns true if they are the same
 */
BOOL sameCoordinates(CLLocation *loc1, CLLocation *loc2);
+ (double) bearingBetweenStartLocation:(CLLocation *)startLocation andEndLocation:(CLLocation *)endLocation;

/*
 * Decoder for the Encoded Polyline Algorithm Format
 * https://developers.google.com/maps/documentation/utilities/polylinealgorithm
 */
+ (NSMutableArray*)decodePolyline:(NSString *)encodedString;

@end

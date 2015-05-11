//
//  SMGeocoder.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 07/02/2013.
//  Copyright (C) 2013 City of Copenhagen.  All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
//  If a copy of the MPL was not distributed with this file, You can obtain one at 
//  http://mozilla.org/MPL/2.0/.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class KortforItem;

/**
 * \ingroup libs
 * Geocoder/reverse geocoder
 *
 * uses KFT, OIOREST or Apple's API
 */
@interface SMGeocoder : NSObject

/**
 * geocoding function that uses eithe Apple's, OIOREST or KFT geocoder
 */
+ (void)geocode:(NSString*)str completionHandler:(void (^)(NSArray* placemarks, NSError* error)) handler;
+ (void)oiorestGeocode:(NSString*)str completionHandler:(void (^)(NSArray* placemarks, NSError* error)) handler;
+ (void)appleGeocode:(NSString*)str completionHandler:(void (^)(NSArray* placemarks, NSError* error)) handler;

/**
 * reverse geocoding
 * uses eithe Apple's, OIOREST or KFT reverse geocoder
 */
+ (void)reverseGeocode:(CLLocationCoordinate2D)coord completionHandler:(void (^)(KortforItem *kortforItem, NSError* error)) handler;
+ (void)oiorestReverseGeocode:(CLLocationCoordinate2D)coord completionHandler:(void (^)(NSDictionary * response, NSError* error)) handler;

@end

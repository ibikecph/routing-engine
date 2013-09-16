//
//  SMNerbyPlaces.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 06/02/2013.
//  Copyright (C) 2013 City of Copenhagen.
//
//  This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
//  If a copy of the MPL was not distributed with this file, You can obtain one at 
//  http://mozilla.org/MPL/2.0/.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class SMNearbyPlaces;

@protocol SMNearbyPlacesDelegate <NSObject>

- (void)nearbyPlaces:(SMNearbyPlaces*)owner foundLocations:(NSArray*)locations;

@end

@interface SMNearbyPlaces : NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (nonatomic, weak) id<SMNearbyPlacesDelegate> delegate;

@property (nonatomic, strong) NSString * title;
@property (nonatomic, strong) NSString * subtitle;
@property (nonatomic, strong) CLLocation * coord;

- (id)initWithDelegate:(id<SMNearbyPlacesDelegate>)dlg;
- (void)findPlacesForLocation:(CLLocation*) loc;

@end

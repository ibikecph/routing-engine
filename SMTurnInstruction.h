//
//  SMTurnInstructions.h
//  I Bike CPH
//
//  Created by Petra Markovic on 1/28/13.
//  Copyright (C) 2013 City of Copenhagen.  All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
//  If a copy of the MPL was not distributed with this file, You can obtain one at 
//  http://mozilla.org/MPL/2.0/.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#define kVehicleBike 1
#define kVehicleWalk 2
#define kVehicleFerry 3
#define kVehicleTrain 4

typedef enum {
    NoTurn = 0, //Give no instruction at all
    GoStraight = 1,
    TurnSlightRight = 2,
    TurnRight = 3,
    TurnSharpRight = 4,
    UTurn = 5,
    TurnSharpLeft = 6,
    TurnLeft = 7,
    TurnSlightLeft = 8,
    ReachViaPoint = 9,
    HeadOn = 10,
    EnterRoundAbout = 11,
    LeaveRoundAbout = 12,
    StayOnRoundAbout = 13,
    StartAtEndOfStreet = 14,
    ReachedYourDestination = 15,
    StartPushingBikeInOneway = 16,
    StopPushingBikeInOneway = 17,
    ReachingDestination = 100
} TurnDirection;

@interface SMTurnInstruction : NSObject {
    // We need this array to calculate the location, since we only keep array index of the turn location (waypointsIndex),
    // not the locaiton itself.
    // We keep index so we know where turn location in this array of route locations is.
    // (needed for some SMRoute distance calculations, see where waypointsIndex is used in SMRoute.m)
//    __weak NSArray *waypoints;
}

@property (nonatomic, assign)TurnDirection drivingDirection;
@property (nonatomic, strong) NSString *ordinalDirection;
@property (nonatomic, strong) NSString *wayName;
@property int lengthInMeters;
@property int timeInSeconds;
@property (nonatomic, strong) NSString *lengthWithUnit;
@property(nonatomic, strong) NSString* smallImageName;
/**
 * Length to next turn in units (km or m)
 * This value will not auto update
 */
@property (nonatomic, strong) NSString *fixedLengthWithUnit;
@property (nonatomic, strong) NSString *directionAbrevation; // N: north, S: south, E: east, W: west, NW: North West, ...
@property float azimuth;

/**
 * Indicate type of transport
 *
 * 1 - bike
 * 2 - walking
 * 3 - ferry
 * 4 - train
 */
@property NSInteger vehicle;


@property int waypointsIndex;
@property (nonatomic, strong) CLLocation *loc;

@property (nonatomic, strong) NSString * shortDescriptionString;
@property (nonatomic, strong) NSString * descriptionString;
@property (nonatomic, strong) NSString * fullDescriptionString;

- (CLLocation *)getLocation;

// Returns only string representation of the driving direction
//- (NSString *)descriptionString;
// Returns only string representation of the driving direction including wayname
//- (NSString *)fullDescriptionString; // including wayname

- (UIImage *)smallDirectionIcon;
- (UIImage *)largeDirectionIcon;

- (void)generateDescriptionString;
- (void)generateStartDescriptionString;
- (void)generateFullDescriptionString;
- (void)generateShortDescriptionString;

@end

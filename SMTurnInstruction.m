//
//  SMTurnInstructions.m
//  I Bike CPH
//
//  Created by Petra Markovic on 1/28/13.
//  Copyright (C) 2013 City of Copenhagen.  All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
//  If a copy of the MPL was not distributed with this file, You can obtain one at 
//  http://mozilla.org/MPL/2.0/.
//

#import "SMTurnInstruction.h"

@implementation SMTurnInstruction
@synthesize drivingDirection= _drivingDirection;
NSString *icons[] = {
    @"no icon",
    @"up",
    @"right-ward",
    @"right",
    @"right",
    @"u-turn",
    @"left",
    @"left",
    @"left-ward",
    @"location",
    @"up",
    @"roundabout",
    @"roundabout",
    @"roundabout",
    @"up",
    @"flag",
    @"walk",
    @"bike",
    @"near-destination",
};


- (CLLocation *)getLocation {
    return self.loc;
//    if (waypoints && self.waypointsIndex >= 0 && self.waypointsIndex < waypoints.count)
//        return [waypoints objectAtIndex:self.waypointsIndex];
//    return nil;
}

// Returns full direction names for abbreviations N NE E SE S SW W NW
NSString *directionString(NSString *abbreviation) {
    NSString * s = translateString([@"direction_" stringByAppendingString:abbreviation]);
    return s;
}

// Returns only string representation of the driving direction
- (void)generateDescriptionString {
    NSString *key = [@"direction_" stringByAppendingFormat:@"%d", self.drivingDirection];
    if (self.routeType == SMRouteTypeBike || self.routeType == SMRouteTypeWalk) {

        NSString *desc = [NSString stringWithFormat:translateString(key), translateString([@"direction_number_" stringByAppendingString:self.ordinalDirection])];
        self.descriptionString = desc;
    } else {
        self.descriptionString = [NSString stringWithFormat:translateString(key), self.routeLineDestination];
    }
}

- (void)generateStartDescriptionString {
    if (self.routeType == SMRouteTypeBike || self.routeType == SMRouteTypeWalk) {
        NSString *key = [@"first_direction_" stringByAppendingFormat:@"%d", self.drivingDirection];
        NSString *desc = [NSString stringWithFormat:translateString(key), translateString([@"direction_" stringByAppendingString:self.directionAbrevation]), translateString([@"direction_number_" stringByAppendingString:self.ordinalDirection])];
        self.descriptionString = desc;
    } else {
        NSString *key = [@"direction_" stringByAppendingFormat:@"%d", self.drivingDirection];
        self.descriptionString = [NSString stringWithFormat:translateString(key), self.routeLineStart,self.routeLineName, self.routeLineDestination];
    }
}

- (void)generateShortDescriptionString {
    self.shortDescriptionString = self.wayName;
}


// Returns only string representation of the driving direction including wayname
- (void)generateFullDescriptionString {
    NSString *key = [@"direction_" stringByAppendingFormat:@"%d", self.drivingDirection];

    if (self.routeType == SMRouteTypeBike || self.routeType == SMRouteTypeWalk) {
        if (self.drivingDirection != 0 && self.drivingDirection != 15 && self.drivingDirection != 100) {
            self.fullDescriptionString = [NSString stringWithFormat:@"%@ %@", translateString(key), self.wayName];
            return;
        }
        self.fullDescriptionString = [NSString stringWithFormat:@"%@", translateString(key)];
    } else if(self.drivingDirection == 18) {
        self.fullDescriptionString = [NSString stringWithFormat:translateString(key), self.routeLineStart, self.routeLineName, self.routeLineDestination];
    } else if (self.drivingDirection == 19) {
        self.fullDescriptionString = [NSString stringWithFormat:translateString(key), self.routeLineDestination];
    }
}

- (UIImage *)directionIcon {
    return [UIImage imageNamed:self.imageName];
}

// Full textual representation of the object, used mainly for debugging
- (NSString *)description {
    return [NSString stringWithFormat:@"%@ %@ [SMTurnInstruction: %d, %d, %@, %@, %f, (%f, %f)]",
            [self descriptionString],
            self.wayName,
            self.lengthInMeters,
            self.timeInSeconds,
            self.lengthWithUnit,
            self.directionAbrevation,
            self.azimuth,
            [self getLocation].coordinate.latitude, [self getLocation].coordinate.longitude];
}

-(void)setDrivingDirection:(TurnDirection)drivingDirection {
    _drivingDirection = drivingDirection;
    self.imageName = icons[self.drivingDirection];
}

- (void)setRouteType:(SMRouteType)routeType {
    _routeType = routeType;

    if (self.drivingDirection == 18 || self.drivingDirection == 19) { // For public transport, override icon.
        switch (self.routeType) {
            case SMRouteTypeSTrain: self.imageName = @"STrainDirection"; break;
            case SMRouteTypeTrain: self.imageName = @"TrainDirection"; break;
            case SMRouteTypeBus: self.imageName = @"BusDirection"; break;
            case SMRouteTypeFerry: self.imageName = @"FerryDirection"; break;
            case SMRouteTypeMetro: self.imageName = @"MetroDirection"; break;
            case SMRouteTypeWalk: self.imageName = @"WalkDirection"; break;
            default: break;
        }
    }
}

@end

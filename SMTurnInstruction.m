//
//  SMTurnInstructions.m
//  I Bike CPH
//
//  Created by Petra Markovic on 1/28/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMTurnInstruction.h"

@implementation SMTurnInstruction

NSString *iconsSmall[] = {
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

NSString *iconsLarge[] = {
    @"no icon",
    @"white-up",
    @"white-right-ward",
    @"white-right",
    @"white-right",
    @"white-u-turn",
    @"white-left",
    @"white-left",
    @"white-left-ward",
    @"location",
    @"white-up",
    @"white-roundabout",
    @"white-roundabout",
    @"white-roundabout",
    @"white-up",
    @"white-flag",
    @"white-walk",
    @"white-bike",
    @"white-near-destination",
};


- (CLLocation *)getLocation {
    return self.loc;
//    if (waypoints && self.waypointsIndex >= 0 && self.waypointsIndex < waypoints.count)
//        return [waypoints objectAtIndex:self.waypointsIndex];
//    return nil;
}

// Returns full direction names for abbreviations N NE E SE S SW W NW
NSString *directionString(NSString *abbreviation) {
    return translateString([@"direction_" stringByAppendingString:abbreviation]);
}

// Returns only string representation of the driving direction
- (void)generateDescriptionString {
    NSString *key = [@"direction_" stringByAppendingFormat:@"%d", self.drivingDirection];
    NSString *desc = [NSString stringWithFormat:translateString(key), translateString([@"direction_number_" stringByAppendingString:self.ordinalDirection])];
    self.descriptionString = desc;
}

- (void)generateStartDescriptionString {
    NSString *key = [@"first_direction_" stringByAppendingFormat:@"%d", self.drivingDirection];
    NSString *desc = [NSString stringWithFormat:translateString(key), translateString([@"direction_" stringByAppendingString:self.directionAbrevation]), translateString([@"direction_number_" stringByAppendingString:self.ordinalDirection])];
    self.descriptionString = desc;
}


// Returns only string representation of the driving direction including wayname
- (void)generateFullDescriptionString {
    NSString *key = [@"direction_" stringByAppendingFormat:@"%d", self.drivingDirection];

    if (self.drivingDirection != 0 && self.drivingDirection != 15 && self.drivingDirection != 100) {
        self.fullDescriptionString = [NSString stringWithFormat:@"%@ %@", translateString(key), self.wayName];
        return;
    }
    self.fullDescriptionString = [NSString stringWithFormat:@"%@", translateString(key)];
}

- (UIImage *)smallDirectionIcon {
    return [UIImage imageNamed:iconsSmall[self.drivingDirection]];
}

- (UIImage *)largeDirectionIcon {
    return [UIImage imageNamed:iconsLarge[self.drivingDirection]];
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


@end

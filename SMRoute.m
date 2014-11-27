 //
//  SMRoute.m
//  I Bike CPH
//
//  Created by Petra Markovic on 1/28/13.
//  Copyright (C) 2013 City of Copenhagen.  All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
//  If a copy of the MPL was not distributed with this file, You can obtain one at 
//  http://mozilla.org/MPL/2.0/.
//

#import "SMLocationManager.h"
#import "SMRoute.h"
#import "SMGPSUtil.h"
//#import "SMUtil.h"
#import "SMRouteUtils.h"

#define MAX_DISTANCE_FROM_PATH 30 // in meters

@interface SMRoute()
@property (nonatomic, strong) SMRequestOSRM * request;
@property (nonatomic, strong) CLLocation * lastRecalcLocation;
@property (nonatomic, strong) NSObject * recalcMutex;
@property CGFloat distanceFromRoute;
@property (nonatomic, strong) NSMutableArray *allTurnInstructions;
@property NSUInteger nextWaypoint;
@end

@implementation SMRoute {
    double minDistance;
}

- (id)init {
    self = [super init];
    if (self) {
        self.routeType= SMRouteTypeNormal;
        self.distanceLeft = -1;
        self.tripDistance = -1;
        self.caloriesBurned = -1;
        self.averageSpeed = -1;
        approachingTurn = NO;
        self.lastVisitedWaypointIndex = -1;
        self.recalculationInProgress = NO;
        self.lastRecalcLocation = [[CLLocation alloc] initWithLatitude:0 longitude:0];
        self.recalcMutex = [NSObject new];
        self.osrmServer = OSRM_SERVER;
        self.nextWaypoint = 0;
    }
    return self;
}

- (id)initWithRouteStart:(CLLocationCoordinate2D)start andEnd:(CLLocationCoordinate2D)end andDelegate:(id<SMRouteDelegate>)dlg {
    return [self initWithRouteStart:start andEnd:end andDelegate:dlg andJSON:nil];
}

- (id)initWithRouteStart:(CLLocationCoordinate2D)start andEnd:(CLLocationCoordinate2D)end andDelegate:(id<SMRouteDelegate>)dlg andJSON:(NSDictionary*) routeJSON {
    self = [self init];
    if (self) {
        self.routeType= SMRouteTypeNormal;
        [self setLocationStart:start];
        [self setLocationEnd:end];
        [self setDelegate:dlg];
        if (routeJSON == nil) {
            SMRequestOSRM * r = [[SMRequestOSRM alloc] initWithDelegate:self];
            [self setRequest:r];
            [r setOsrmServer:self.osrmServer];
            [r setAuxParam:@"startRoute"];
            [r getRouteFrom:start to:end via:nil];
        } else {
            [self setupRoute:routeJSON];
        }
    }
    return self;
}

- (BOOL) isTooFarFromRouteSegment:(CLLocation *)loc from:(SMTurnInstruction *)turnA to:(SMTurnInstruction *)turnB maxDistance:(double)maxDistance {
    double min = MAXFLOAT;

    for (int i = MAX(self.lastVisitedWaypointIndex, 0); i < turnB.waypointsIndex; i++) {
        CLLocation *a = [self.waypoints objectAtIndex:i];
        CLLocation *b = [self.waypoints objectAtIndex:(i + 1)];
        double d = distanceFromLineInMeters(loc.coordinate, a.coordinate, b.coordinate);
        if (d < 0.0)
            continue;
        if (d <= min) {
            min = d;
            self.lastVisitedWaypointIndex = i;
        }
        if (min < 2) {
            // Close enough :)
            break;
        }
    }
    
    if (min <= maxDistance && min < self.distanceFromRoute) {
        self.distanceFromRoute = min;

        CLLocation *a = [self.waypoints objectAtIndex:self.lastVisitedWaypointIndex];
        CLLocation *b = [self.waypoints objectAtIndex:(self.lastVisitedWaypointIndex + 1)];
        CLLocationCoordinate2D coord = closestCoordinate(loc.coordinate, a.coordinate, b.coordinate);

//        double d = distanceFromLineInMeters(coord, a.coordinate, b.coordinate);

        
//        self.lastCorrectedHeading = [SMGPSUtil bearingBetweenStartLocation:a andEndLocation:[[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude]];
        if ([a distanceFromLocation:b] > 0.0f) {
            debugLog(@"=============================");
            debugLog(@"Last visited waypoint index: %d", self.lastVisitedWaypointIndex);
            debugLog(@"Location A: %@", a);
            debugLog(@"Location B: %@", b);
            self.lastCorrectedHeading = [SMGPSUtil bearingBetweenStartLocation:a andEndLocation:b];
            debugLog(@"Heading: %f", self.lastCorrectedHeading);
            debugLog(@"Closest point: (%f %f)", coord.latitude, coord.longitude);
            debugLog(@"=============================");
        }
        if (self.visitedLocations && self.visitedLocations.count > 0) {
            self.lastCorrectedLocation = [[CLLocation alloc] initWithCoordinate:coord altitude:loc.altitude horizontalAccuracy:loc.horizontalAccuracy verticalAccuracy:loc.verticalAccuracy course:loc.course speed:loc.speed timestamp:loc.timestamp];
        }
    }
    
    return min > maxDistance;
}

- (BOOL)checkLocation:(CLLocation*)loc withMaxDistance:(CGFloat)maxDistance {
    SMTurnInstruction *currentTurn = [self.turnInstructions objectAtIndex:0];
    SMTurnInstruction *nextTurn = [self.turnInstructions objectAtIndex:MIN([self.turnInstructions count] - 1, MAX_TURNS)];
    if (nextTurn) {
        if (![self isTooFarFromRouteSegment:loc from:nil to:nextTurn maxDistance:maxDistance])  {
            if (self.lastVisitedWaypointIndex > currentTurn.waypointsIndex) {
                [self updateSegmentBasedOnWaypoint];
                approachingTurn = YES;
            }
            self.snapArrow = YES;
            return NO;
        }
    }
    self.snapArrow = NO;
    return YES;
}

- (BOOL) isTooFarFromRoute:(CLLocation *)loc maxDistance:(int)maxDistance {
    /**
     * last turn we passed
     */
    SMTurnInstruction *lastTurn = [self.pastTurnInstructions lastObject];
    if (self.turnInstructions.count > 0) {
        SMTurnInstruction *currentTurn = [self.turnInstructions objectAtIndex:0];
        @synchronized(self.turnInstructions) {
            self.lastCorrectedLocation = [[CLLocation alloc] initWithCoordinate:loc.coordinate altitude:loc.altitude horizontalAccuracy:loc.horizontalAccuracy verticalAccuracy:loc.verticalAccuracy course:loc.course speed:loc.speed timestamp:loc.timestamp];
            if (!lastTurn) {
                /**
                 * we have passed no turns. check if we have managed to get on the route somehow
                 */
                if (currentTurn) {
                    double currentDistanceFromStart = [loc distanceFromLocation:currentTurn.loc];
                    debugLog(@"Current distance from start: %.6f", currentDistanceFromStart);
                    if (currentDistanceFromStart > maxDistance) {
                        return [self checkLocation:loc withMaxDistance:maxDistance];                        
                    }
                }
                return NO;
            }
            
            self.distanceFromRoute = MAXFLOAT;
            return [self checkLocation:loc withMaxDistance:maxDistance];            
        }
    }
    return NO;
}


- (double)getCorrectedHeading {
    return self.lastCorrectedHeading;
}

- (void) recalculateRoute:(CLLocation *)loc {
    @synchronized(self.recalcMutex) {
        if (self.recalculationInProgress) {
            return;
        }
    }
    
    self.snapArrow = NO;
    
    CGFloat distance = [loc distanceFromLocation:self.lastRecalcLocation];
    if (distance < MIN_DISTANCE_FOR_RECALCULATION) {
        return;
    }
    debugLog(@"Distance: %f", distance);
    self.lastRecalcLocation = loc;
    
    @synchronized(self.recalcMutex) {
        self.recalculationInProgress = YES;
    }
    debugLog(@"Recalculating route!");
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(routeRecalculationStarted)]) {
        [self.delegate routeRecalculationStarted];
    }
    
    CLLocation *end = [self getEndLocation];
    if (!loc || !end)
        return;
    
    
    SMRequestOSRM  * r = [[SMRequestOSRM alloc] initWithDelegate:self];
    [self setRequest:r];
    [r setOsrmServer:self.osrmServer];
    [r setAuxParam:@"routeRecalc"];
    
    // Uncomment code below if previous part of the route needs to be displayed.
    //        NSMutableArray *viaPoints = [NSMutableArray array];
    //        for (SMTurnInstruction *turn in self.pastTurnInstructions)
    //            [viaPoints addObject:turn.loc];
    //        [viaPoints addObject:loc];
    //        [r getRouteFrom:((CLLocation *)[self.waypoints objectAtIndex:0]).coordinate to:end.coordinate via:viaPoints];
    
    [r getRouteFrom:loc.coordinate to:end.coordinate via:nil checksum:self.routeChecksum destinationHint:self.destinationHint];

}

//double course(CLLocation *loc1, CLLocation *loc2) {
//    return 0.0;
//}

- (void) updateSegment {
    debugLog(@"Update segment!!!!");
    if (!self.delegate) {
        NSLog(@"Warning: delegate not set while in updateSegment()!");
        return;
    }

    if (self.turnInstructions.count > 0) {
        @synchronized(self.turnInstructions) {
            [self.pastTurnInstructions addObject:[self.turnInstructions objectAtIndex:0]];
            debugLog(@"===========================");
            debugLog(@"Past instructions: %@", self.pastTurnInstructions);
            debugLog(@"===========================");
            [self.turnInstructions removeObjectAtIndex:0];
            [self.delegate updateTurn:YES];
        }
        

        if (self.turnInstructions.count == 0)
            [self.delegate reachedDestination];
    }
}

- (BOOL) approachingFinish {
    return /*approachingTurn && */self.turnInstructions.count == 1;
}

//- (void) visitLocation:(CLLocation *)loc {
//    
//    @synchronized(self.visitedLocations) {
//        [self updateDistances:loc];
//        if (!self.visitedLocations)
//            self.visitedLocations = [NSMutableArray array];
//        [self.visitedLocations addObject:@{
//         @"location" : loc,
//         @"date" : [NSDate date]
//         }];
//    }
//
//    @synchronized(self.turnInstructions) {
//        if (self.turnInstructions.count <= 0)
//            return;        
//    }
//    
//    @synchronized(self.recalcMutex) {
//        if (self.recalculationInProgress) {
//            return;
//        }
//    }
//
//
//    // Check if we are finishing:
//    double distanceToFinish = [loc distanceFromLocation:[self getEndLocation]];
//    double speed = loc.speed > 0 ? loc.speed : 5;
//    int timeToFinish = 100;
//    if (speed > 0) {
//        timeToFinish = distanceToFinish / speed;
//        debugLog(@"finishing in %d", timeToFinish);
//    }
//    /**
//     * are we close to the finish (< 10m or 3s left)?
//     */
//    if (distanceToFinish < 10.0 || timeToFinish <= 3) {
//        if (self.turnInstructions.count == 1) {
//            /**
//             * if there was only one instruction left go through usual channels
//             */
//            approachingTurn = NO;
//            [self updateSegmentBasedOnWaypoint];
//            return;
//        } else {
//            /**
//             * we have somehow skipped most of the route (going through a park or unknown street)
//             */
//            [self.delegate reachedDestination];
//            return;
//        }
//    }
//
////    // are we approaching some turn or are we past some turn
////    if (approachingTurn) {
////        SMTurnInstruction *nextTurn = [self.turnInstructions objectAtIndex:0];
////        
////        double d = [loc distanceFromLocation:[nextTurn getLocation]];
////        if (self.turnInstructions.count > 0 && d > 20.0) {
////            if (loc.course >= 0.0)
////                debugLog(@"loc.course: %f turn->azimuth: %f", loc.course, nextTurn.azimuth);
////
////            approachingTurn = NO;
////
////            debugLog(@"Past turn: %@", nextTurn.wayName);
////            [self updateSegmentBasedOnWaypoint];
////        }
////    } else if (!approachingTurn) {
////        for (int i = 0; i < self.turnInstructions.count; i++) {
////            SMTurnInstruction *nextTurn = [self.turnInstructions objectAtIndex:i];
////            double distanceFromTurn = [loc distanceFromLocation:[nextTurn getLocation]];
////            if ((distanceFromTurn < 10.0 || (i == self.turnInstructions.count - 1 && distanceFromTurn < 20.0))) {
//////                && (loc.course < 0.0 || fabs(loc.course - nextTurn.azimuth) <= 20.0)) {
////                approachingTurn = YES;
////                if (i > 0)
////                    [self updateSegmentBasedOnWaypoint];
////                debugLog(@"Approaching turn %@ in %.1g m", nextTurn.wayName, distanceFromTurn);
////                break;
////            }
////        }
////    }
//    
//    // Check if we went too far from the calculated route and, if so, recalculate route
//    // max allowed distance depends on location's accuracy
//    int maxD = loc.horizontalAccuracy >= 0 ? (loc.horizontalAccuracy / 3 + 20) : MAX_DISTANCE_FROM_PATH;
//    if (![self approachingFinish] && self.delegate && [self isTooFarFromRoute:loc maxDistance:maxD]) {
//        approachingTurn = NO;
//        [self recalculateRoute:loc];
//    }
//    
//    
//}

- (CLLocation *) getStartLocation {
    if (self.waypoints && self.waypoints.count > 0)
        return [self.waypoints objectAtIndex:0];
    return NULL;
}

- (CLLocation *) getEndLocation {
    if (self.waypoints && self.waypoints.count > 0)
        return [self.waypoints lastObject];
    return NULL;
}

- (CLLocation *) getFirstVisitedLocation {
    if (self.visitedLocations && self.visitedLocations.count > 0)
        return ((CLLocation *)self.visitedLocations.firstObject);
    return NULL;
}

- (CLLocation *) getLastVisitedLocation {
    if (self.visitedLocations && self.visitedLocations.count > 0)
        return ((CLLocation *)self.visitedLocations.lastObject);
    return NULL;
}

/*
 * Decoder for the Encoded Polyline Algorithm Format
 * https://developers.google.com/maps/documentation/utilities/polylinealgorithm
 */
NSMutableArray* decodePolyline (NSString *encodedString) {
    
    const char *bytes = [encodedString UTF8String];
    size_t len = strlen(bytes);
    
    int lat = 0, lng = 0;
    
    NSMutableArray *locations = [NSMutableArray array];
    for (int i = 0; i < len;) {
        for (int k = 0; k < 2; k++) {
            
            uint32_t delta = 0;
            int shift = 0;
            
            unsigned char c;
            do {
                c = bytes[i++] - 63;
                delta |= (c & 0x1f) << shift;
                shift += 5;
            } while (c & 0x20);
            
            delta = (delta & 0x1) ? ((~delta >> 1) | 0x80000000) : (delta >> 1);
            (k == 0) ? (lat += delta) : (lng += delta);
        }
        //      debugLog(@"decodePolyline(): (%d, %d)", lat, lng);
        
        [locations addObject:[[CLLocation alloc] initWithLatitude:((double)lat / [SMRouteSettings sharedInstance].route_polyline_precision) longitude:((double)lng / [SMRouteSettings sharedInstance].route_polyline_precision)]];
    }
    
    return locations;
}

+ (NSString *)encodePolyline:(NSArray *)locations
{
    NSMutableString *encodedString = [NSMutableString string];
    int val = 0;
    int value = 0;
    CLLocationCoordinate2D prevCoordinate = CLLocationCoordinate2DMake(0, 0);
    
    for (CLLocation *location in locations) {
        CLLocationCoordinate2D coordinate = location.coordinate;
        
        // Encode latitude
        val = round((coordinate.latitude - prevCoordinate.latitude) * [SMRouteSettings sharedInstance].route_polyline_precision);
        val = (val < 0) ? ~(val<<1) : (val <<1);
        while (val >= 0x20) {
            int value = (0x20|(val & 31)) + 63;
            [encodedString appendFormat:@"%c", value];
            val >>= 5;
        }
        [encodedString appendFormat:@"%c", val + 63];
        
        // Encode longitude
        val = round((coordinate.longitude - prevCoordinate.longitude) * [SMRouteSettings sharedInstance].route_polyline_precision);
        val = (val < 0) ? ~(val<<1) : (val <<1);
        while (val >= 0x20) {
            value = (0x20|(val & 31)) + 63;
            [encodedString appendFormat:@"%c", value];
            val >>= 5;
        }
        [encodedString appendFormat:@"%c", val + 63];
        
        prevCoordinate = coordinate;
    }
    
    return encodedString;
}

- (BOOL) parseFromJson:(NSDictionary *)jsonRoot delegate:(id<SMRouteDelegate>) dlg {
    

//    SMRoute *route = [[SMRoute alloc] init];
    @synchronized(self.waypoints) {
        self.waypoints = [SMGPSUtil decodePolyline:jsonRoot[@"route_geometry"]];
    }

    if (self.waypoints.count < 2)
        return NO;

    @synchronized(self.turnInstructions) {
        self.turnInstructions = [NSMutableArray array];
    }
    @synchronized(self.pastTurnInstructions) {
        self.pastTurnInstructions = [NSMutableArray array];
    }
    self.estimatedTimeForRoute = [jsonRoot[@"route_summary"][@"total_time"] integerValue];
    self.estimatedRouteDistance = [jsonRoot[@"route_summary"][@"total_distance"] integerValue];
    self.routeChecksum = nil;
    self.destinationHint = nil;
    
    if (jsonRoot[@"hint_data"] && jsonRoot[@"hint_data"][@"checksum"]) {
        self.routeChecksum = [NSString stringWithFormat:@"%@", jsonRoot[@"hint_data"][@"checksum"]];
    }
    
    if (jsonRoot[@"hint_data"] && jsonRoot[@"hint_data"][@"locations"] && [jsonRoot[@"hint_data"][@"locations"] isKindOfClass:[NSArray class]]) {
        self.destinationHint = [NSString stringWithFormat:@"%@", [jsonRoot[@"hint_data"][@"locations"] lastObject]];
    }
    
    NSArray *routeInstructions = jsonRoot[@"route_instructions"];
    if (routeInstructions && routeInstructions.count > 0) {
        int prevlengthInMeters = 0;
        NSString *prevlengthWithUnit = @"";
        BOOL isFirst = YES;
        for (id jsonObject in routeInstructions) {
            SMTurnInstruction *instruction = [[SMTurnInstruction alloc] init];

            NSArray * arr = [[NSString stringWithFormat:@"%@", [jsonObject objectAtIndex:0]] componentsSeparatedByString:@"-"];
            int pos = [(NSString*)[arr objectAtIndex:0] intValue];
            
            if (pos <= 17) {
                instruction.drivingDirection = pos;
                if ([arr count] > 1 && [arr objectAtIndex:1]) {
                    instruction.ordinalDirection = [arr objectAtIndex:1];
                } else {
                    instruction.ordinalDirection = @"";
                }
                instruction.wayName = (NSString *)[jsonObject objectAtIndex:1];
                
                if ([instruction.wayName rangeOfString:@"\\{.+\\:.+\\}" options:NSRegularExpressionSearch].location != NSNotFound) {
                    instruction.wayName = translateString(instruction.wayName);
                }
                
                instruction.lengthInMeters = prevlengthInMeters;
                prevlengthInMeters = [(NSNumber *)[jsonObject objectAtIndex:2] intValue];
                instruction.timeInSeconds = [(NSNumber *)[jsonObject objectAtIndex:4] intValue];
                instruction.lengthWithUnit = prevlengthWithUnit;
                /**
                 * Save length to next turn with units so we don't have to generate it each time
                 * It's formatted just the way we like it
                 */
                instruction.fixedLengthWithUnit = formatDistance(prevlengthInMeters);
                prevlengthWithUnit = (NSString *)[jsonObject objectAtIndex:5];
                instruction.directionAbrevation = (NSString *)[jsonObject objectAtIndex:6];
                instruction.azimuth = [(NSNumber *)[jsonObject objectAtIndex:7] floatValue];
                instruction.vehicle = 0;
                if ([jsonObject count] > 8) {
                    instruction.vehicle = [(NSNumber *)[jsonObject objectAtIndex:8] intValue];
                }
                
                if (isFirst) {
                    [instruction generateStartDescriptionString];
                    isFirst = NO;
                } else {
                    [instruction generateDescriptionString];
                }
                [instruction generateFullDescriptionString];
                
                [instruction generateShortDescriptionString];
                
                int position = [(NSNumber *)[jsonObject objectAtIndex:3] intValue];
                instruction.waypointsIndex = position;
                //          instruction->waypoints = route;
                
                if (self.waypoints && position >= 0 && position < self.waypoints.count)
                    instruction.loc = [self.waypoints objectAtIndex:position];
                
                @synchronized(self.turnInstructions) {
                    [self.turnInstructions addObject:instruction];
                }
                
            }
//          [route.turnInstructions addObject:[SMTurnInstruction parseInstructionFromJson:obj withRoute:route.waypoints]];
            
        }
        
        self.longestDistance = 0.0f;
        self.longestStreet = @"";
        
        if ([jsonRoot[@"route_name"] isKindOfClass:[NSArray class]] && [jsonRoot[@"route_name"] count] > 0) {
            self.longestStreet = [jsonRoot[@"route_name"] firstObject];
        }
//        self.longestStreet = [jsonRoot[@"route_name"] componentsJoinedByString:@", "];
        if (self.longestStreet == nil || [[self.longestStreet stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]) {
            for (int i = 1; i < self.turnInstructions.count - 1; i++) {
                SMTurnInstruction * inst = [self.turnInstructions objectAtIndex:i];
                if (inst.lengthInMeters > self.longestDistance) {
                    self.longestDistance = inst.lengthInMeters;
                    SMTurnInstruction * inst1 = [self.turnInstructions objectAtIndex: i - 1];
                    self.longestStreet = inst1.wayName;
                }
            }
        }
        
        if ([self.longestStreet rangeOfString:@"\\{.+\\:.+\\}" options:NSRegularExpressionSearch].location != NSNotFound) {
            self.longestStreet = translateString(self.longestStreet);
        }
        
        
    }
    
    @synchronized(self.turnInstructions) {
        self.allTurnInstructions = [NSMutableArray arrayWithArray:self.turnInstructions];
    }

    self.lastVisitedWaypointIndex = -1;
    
    CLLocation *a = [self.waypoints objectAtIndex:0];
    CLLocation *b = [self.waypoints objectAtIndex:1];
    self.lastCorrectedHeading = [SMGPSUtil bearingBetweenStartLocation:a andEndLocation:b];

    self.snapArrow = NO;
    return YES;
}

- (void)updateDistances:(CLLocation *)loc {
    if (self.tripDistance < 0.0) {
        self.tripDistance = 0.0;
    }
    if (self.visitedLocations.count > 0) {
        self.tripDistance += [loc distanceFromLocation:((CLLocation *)self.visitedLocations.lastObject)];
    }

    if (self.distanceLeft < 0.0) {
        self.distanceLeft = self.estimatedRouteDistance;
    }

    else if (self.turnInstructions.count > 0) {
        // calculate distance from location to the next turn
        SMTurnInstruction *nextTurn = [self.turnInstructions objectAtIndex:0];
        nextTurn.lengthInMeters = [self calculateDistanceToNextTurn:loc];
        nextTurn.lengthWithUnit = formatDistance(nextTurn.lengthInMeters);
        @synchronized(self.turnInstructions) {
            [self.turnInstructions setObject:nextTurn atIndexedSubscript:0];
        }
        self.distanceLeft = nextTurn.lengthInMeters;

        // calculate distance from next turn to the end of the route
        for (int i = 1; i < self.turnInstructions.count; i++) {
            self.distanceLeft += ((SMTurnInstruction *)[self.turnInstructions objectAtIndex:i]).lengthInMeters;
        }
        debugLog(@"distance left: %.1f", self.distanceLeft);
    }
}

- (NSDictionary*) save {
    // TODO save visited locations and posibly some other info
    debugLog(@"Saving route");
    return @{@"data" : [NSKeyedArchiver archivedDataWithRootObject:self.visitedLocations], @"polyline" : [SMRoute encodePolyline:self.visitedLocations]};
}

/*
 * Calculates distance from given location to next turn
 */
- (CGFloat)calculateDistanceToNextTurn:(CLLocation *)loc {
    if (self.turnInstructions.count == 0)
        return 0.0f;

    SMTurnInstruction *nextTurn = [self.turnInstructions objectAtIndex:0];

    // If first turn still hasn't been reached, return linear distance to it.
    if (self.pastTurnInstructions.count == 0)
        return [loc distanceFromLocation:nextTurn.loc];

    int firstIndex = self.lastVisitedWaypointIndex >= 0 ? self.lastVisitedWaypointIndex + 1 : 0;
    CGFloat distance = 0.0f;
    if (firstIndex < self.waypoints.count) {
        distance = [loc distanceFromLocation:[self.waypoints objectAtIndex:firstIndex]];
        if (nextTurn.waypointsIndex <= self.waypoints.count) {
            for (int i = firstIndex; i < nextTurn.waypointsIndex; i++) {
                double d = [((CLLocation *)[self.waypoints objectAtIndex:i]) distanceFromLocation:[self.waypoints objectAtIndex:(i + 1)]];
                distance += d;
            }
        }
    }

    debugLog(@"distance to next turn: %.1f", distance);
    return distance;
}

- (CGFloat)calculateDistanceTraveled {
    if (self.tripDistance >= 0) {
        return self.tripDistance;
    }
    CGFloat distance = 0.0f;
    
    if ([self.visitedLocations count] > 1) {
        CLLocation * startLoc = ((CLLocation *)self.visitedLocations.firstObject);
        for (int i = 1; i < [self.visitedLocations count]; i++) {
            CLLocation *loc = ((CLLocation *)self.visitedLocations[i]);
            distance += [loc distanceFromLocation:startLoc];
            startLoc = loc;
        }
    }
    
    self.tripDistance = roundf(distance);
    
    return self.tripDistance;
}

- (CGFloat)calculateAverageSpeed {
    CGFloat distance = [self calculateDistanceTraveled];
    CGFloat avgSpeed = 0.0f;
    if ([self.visitedLocations count] > 1) {
        NSDate * startLoc = ((CLLocation *)self.visitedLocations.firstObject).timestamp;
        NSDate * endLoc = ((CLLocation *)self.visitedLocations.lastObject).timestamp;
        if ([endLoc timeIntervalSinceDate:startLoc] > 0) {
            avgSpeed = distance / ([endLoc timeIntervalSinceDate:startLoc]);            
        }
    }
    self.averageSpeed = roundf(avgSpeed * 30.6)/10.0f;
    return self.averageSpeed;
}


- (NSString*)timePassed {
    if ([self.visitedLocations count] > 1) {
        NSDate * startDate = ((CLLocation *)self.visitedLocations.firstObject).timestamp;
        NSDate * endDate = ((CLLocation *)self.visitedLocations.lastObject).timestamp;
        return formatTimePassed(startDate, endDate);
    }
    return @"";
}

- (CGFloat)calculateCaloriesBurned {
    if (self.caloriesBurned >= 0) {
        return self.caloriesBurned;
    }
    
    CGFloat avgSpeed = [self calculateAverageSpeed];
    CGFloat timeSpent = 0.0f;
    if ([self.visitedLocations count] > 1) {
        NSDate * startLoc = ((CLLocation *)self.visitedLocations.firstObject).timestamp;
        NSDate * endLoc = ((CLLocation *)self.visitedLocations.lastObject).timestamp;
        timeSpent = [endLoc timeIntervalSinceDate:startLoc] / 3600.0f;
    }

    return self.caloriesBurned = caloriesBurned(avgSpeed, timeSpent);
}

- (void)setupRoute:(id)jsonRoot{
    BOOL done = [self parseFromJson:jsonRoot delegate:nil];
    if (done) {
//        approachingTurn = NO;
        self.tripDistance = 0.0f;
        @synchronized(self.pastTurnInstructions) {
            self.pastTurnInstructions = [NSMutableArray array];
        }
        
        if ([SMLocationManager instance].hasValidLocation) {
            [self updateDistances:[SMLocationManager instance].lastValidLocation];
        }
    }
}


#pragma mark - osrm request delegate

- (void)request:(SMRequestOSRM *)req failedWithError:(NSError *)error {
    if ([req.auxParam isEqualToString:@"routeRecalc"]) {
        @synchronized(self.recalcMutex) {
            self.recalculationInProgress = NO;
        }
        if ([req.auxParam isEqualToString:@"routeRecalc"] && self.delegate) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate serverError];
            });
        }
    }
}

- (void)serverNotReachable {
    
}

- (void)request:(SMRequestOSRM *)req finishedWithResult:(id)res {
    if ([req.auxParam isEqualToString:@"startRoute"]) {
        NSString * response = [[NSString alloc] initWithData:req.responseData encoding:NSUTF8StringEncoding];
        if (response) {
            id jsonRoot = [NSJSONSerialization JSONObjectWithData:req.responseData options:NSJSONReadingAllowFragments error:nil];//[[[SBJsonParser alloc] init] objectWithString:response];
            if (!jsonRoot || ([jsonRoot isKindOfClass:[NSDictionary class]] == NO) || ([jsonRoot[@"status"] intValue] != 0)) {
                if (self.delegate) {
                    [self.delegate routeNotFound];
                };
                return;
            }
            [self setupRoute:jsonRoot];
            if (self.delegate && [self.delegate respondsToSelector:@selector(startRoute:)]) {
                [self.delegate startRoute:self];
            }
        }

    } else if ([req.auxParam isEqualToString:@"routeRecalc"]) {
        NSString * response = [[NSString alloc] initWithData:req.responseData encoding:NSUTF8StringEncoding];
        if (response) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                
                
                id jsonRoot = [NSJSONSerialization JSONObjectWithData:req.responseData options:NSJSONReadingAllowFragments error:nil];//[[[SBJsonParser alloc] init] objectWithString:response];
                if (!jsonRoot || ([jsonRoot isKindOfClass:[NSDictionary class]] == NO) || ([jsonRoot[@"status"] intValue] != 0)) {
                    if (self.delegate) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.delegate routeRecalculationDone];
                            return;
                        });
                    }
                };
                
                BOOL done = [self parseFromJson:jsonRoot delegate:nil];
                if (done) {
//                    approachingTurn = NO;
                    if ([SMLocationManager instance].hasValidLocation) {
                        [self updateDistances:[SMLocationManager instance].lastValidLocation];
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (self.delegate && [self.delegate respondsToSelector:@selector(routeRecalculationDone)]) {
                            [self.delegate routeRecalculationDone];
                        }
                        [self.delegate updateRoute];
                        @synchronized(self.recalcMutex) {
                            self.recalculationInProgress = NO;
                        }
                    });
                }
                
                
                
            });
        }
    }
}

- (BOOL)isOnPath {
    return self.snapArrow;
}

#pragma mark - new methods

- (void)updateSegmentBasedOnWaypoint {
//    debugLog(@"updateSegmentBasedOnWaypoint!!!!");
    if (!self.delegate) {
        NSLog(@"Warning: delegate not set while in updateSegment()!");
        return;
    }
    
    NSUInteger currentIndex = 0;
    NSMutableArray * past = [NSMutableArray array];
    NSMutableArray * future = [NSMutableArray array];
    for (int i = 0; i < self.allTurnInstructions.count; i++) {
        SMTurnInstruction * currentTurn = [self.allTurnInstructions objectAtIndex:i];
        if (self.lastVisitedWaypointIndex < currentTurn.waypointsIndex) {
            currentIndex = i;
            [future addObject:currentTurn];
        } else {
            [past addObject:currentTurn];
        }
    }
    @synchronized(self.turnInstructions) {
        self.pastTurnInstructions = past;
        self.turnInstructions = future;
    }
    
//    if ([self.turnInstructions isEqual:future] == NO || [self.pastTurnInstructions isEqual:past] == NO) {
//        [self.delegate updateTurn:YES];
//    }
    
    [self.delegate updateTurn:YES];
    
    if (self.turnInstructions.count == 0) {
        [self.delegate reachedDestination];
    }
}

- (BOOL)findNearestRouteSegmentForLocation:(CLLocation *)loc withMaxDistance:(CGFloat)maxDistance {
    double min = MAXFLOAT;

    locLog(@"Last visited waypoint index: %d", self.lastVisitedWaypointIndex);

    
    /**
     * first check the most likely position
     */
    NSInteger startPoint = MAX(self.lastVisitedWaypointIndex, 0);
    
    for (int i = startPoint; i < MIN(self.waypoints.count - 1, startPoint + 5); i++) {
        CLLocation *a = [self.waypoints objectAtIndex:i];
        CLLocation *b = [self.waypoints objectAtIndex:(i + 1)];
        double d = distanceFromLineInMeters(loc.coordinate, a.coordinate, b.coordinate);
        if (d < 0.0)
            continue;
        if (d <= min) {
            min = d;
            self.lastVisitedWaypointIndex = i;
        }
        if (min < 2) {
            // Close enough :)
            break;
        }
    }
    
    /**
     * then check the remaining waypoints
     */
    if (min > maxDistance) {
        locLog(@"entered FUTURE block!");
        startPoint = MIN(self.waypoints.count - 1, startPoint + 5);
        for (int i = startPoint; i < MIN(self.waypoints.count - 1, startPoint + 5); i++) {
            CLLocation *a = [self.waypoints objectAtIndex:i];
            CLLocation *b = [self.waypoints objectAtIndex:(i + 1)];
            double d = distanceFromLineInMeters(loc.coordinate, a.coordinate, b.coordinate);
            if (d < 0.0)
                continue;
            if (d <= min) {
                min = d;
                self.lastVisitedWaypointIndex = i;
            }
            if (min < 2) {
                // Close enough :)
                break;
            }
        }
    }
    /**
     * check if the user went back
     */
    if (min > maxDistance) {
        locLog(@"entered PAST block!");
        startPoint = 0;
        for (int i = startPoint; i < MIN(self.waypoints.count - 1, self.lastVisitedWaypointIndex); i++) {
            CLLocation *a = [self.waypoints objectAtIndex:i];
            CLLocation *b = [self.waypoints objectAtIndex:(i + 1)];
            double d = distanceFromLineInMeters(loc.coordinate, a.coordinate, b.coordinate);
            if (d < 0.0)
                continue;
            if (d <= min) {
                min = d;
                self.lastVisitedWaypointIndex = i;
            }
            if (min < 2) {
                // Close enough :)
                break;
            }
        }
    }
    
    if (self.lastVisitedWaypointIndex < 0) {
        /**
         * check the distance from start
         */
        min = [loc distanceFromLocation:[self.waypoints objectAtIndex:0]];
        /**
         * if we are less then 5m away from start snap the arrow
         *
         * heading is left as sent by the GPS so that you know if you're moving in the wrong direction
         */
        if (min < 5) {
            self.distanceFromRoute = min;
            self.lastVisitedWaypointIndex = 0;
            
            CLLocation *a = [self.waypoints objectAtIndex:self.lastVisitedWaypointIndex];
            CLLocation *b = [self.waypoints objectAtIndex:(self.lastVisitedWaypointIndex + 1)];
            CLLocationCoordinate2D coord = closestCoordinate(loc.coordinate, a.coordinate, b.coordinate);
            
            self.lastCorrectedHeading = [SMGPSUtil bearingBetweenStartLocation:loc andEndLocation:a];
            self.lastCorrectedLocation = [[CLLocation alloc] initWithCoordinate:coord altitude:loc.altitude horizontalAccuracy:loc.horizontalAccuracy verticalAccuracy:loc.verticalAccuracy course:loc.course speed:loc.speed timestamp:loc.timestamp];
//            self.snapArrow = YES;

        }
    } else if (min <= maxDistance && self.lastVisitedWaypointIndex >= 0) {
        self.distanceFromRoute = min;
        
        CLLocation *a = [self.waypoints objectAtIndex:self.lastVisitedWaypointIndex];
        CLLocation *b = [self.waypoints objectAtIndex:(self.lastVisitedWaypointIndex + 1)];
        CLLocationCoordinate2D coord = closestCoordinate(loc.coordinate, a.coordinate, b.coordinate);
        
        if ([a distanceFromLocation:b] > 0.0f) {
            locLog(@"=========");
            locLog(@"Last visited waypoint index: %d", self.lastVisitedWaypointIndex);
            locLog(@"Loc A: (%f, %f)", a.coordinate.latitude, a.coordinate.longitude);
            locLog(@"Loc B: (%f, %f)", b.coordinate.latitude, b.coordinate.longitude);
            self.lastCorrectedHeading = [SMGPSUtil bearingBetweenStartLocation:a andEndLocation:b];
            locLog(@"Heading: %f", self.lastCorrectedHeading);
            locLog(@"Closest: (%f %f)", coord.latitude, coord.longitude);
            locLog(@"=========");
        }
        self.lastCorrectedLocation = [[CLLocation alloc] initWithCoordinate:coord altitude:loc.altitude horizontalAccuracy:loc.horizontalAccuracy verticalAccuracy:loc.verticalAccuracy course:loc.course speed:loc.speed timestamp:loc.timestamp];
        self.snapArrow = YES;
    } else {
        locLog(@"too far from location");
        self.snapArrow = NO;
        self.lastCorrectedLocation = loc;
    }
    return min > maxDistance;
}

- (void) visitLocation:(CLLocation *)loc {
    self.snapArrow = YES;
    int maxD = loc.horizontalAccuracy >= 0 ? MAX((loc.horizontalAccuracy / 3 + 20), MAX_DISTANCE_FROM_PATH) : MAX_DISTANCE_FROM_PATH;
    BOOL isTooFar = NO;
    @synchronized(self.visitedLocations) {
        [self updateDistances:loc];
        if (!self.visitedLocations)
            self.visitedLocations = [NSMutableArray array];
        [self.visitedLocations addObject:loc];
        self.distanceFromRoute = MAXFLOAT;
        isTooFar = [self findNearestRouteSegmentForLocation:loc withMaxDistance:maxD];
        [self updateSegmentBasedOnWaypoint];
    }
    
    @synchronized(self.turnInstructions) {
        if (self.turnInstructions.count <= 0)
            return;
    }
    
    @synchronized(self.recalcMutex) {
        if (self.recalculationInProgress) {
            return;
        }
    }
    
    // Check if we are finishing:
    double distanceToFinish = MIN([self.lastCorrectedLocation distanceFromLocation:[self getEndLocation]], [loc distanceFromLocation:[self getEndLocation]]);
    double speed = loc.speed > 0 ? loc.speed : 5;
    int timeToFinish = 100;
    if (speed > 0) {
        timeToFinish = distanceToFinish / speed;
        locLog(@"finishing in %ds %.0fm max distance: %.0fm", timeToFinish, roundf(distanceToFinish), roundf(maxD));
    }
    /**
     * are we close to the finish (< 10m or 3s left)?
     */
    if (distanceToFinish < 10.0 || timeToFinish <= 3) {
        [self.delegate reachedDestination];
        return;
    }
    
    if (isTooFar) {
        self.snapArrow = NO;
        self.lastVisitedWaypointIndex = -1;
        [self recalculateRoute:loc];
    }
    
    
}

@end

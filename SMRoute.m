 //
//  SMRoute.m
//  I Bike CPH
//
//  Created by Petra Markovic on 1/28/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMLocationManager.h"
#import "SMRoute.h"
#import "SMGPSUtil.h"
#import "SMUtil.h"

#define MAX_DISTANCE_FROM_PATH 20 // in meters

@interface SMRoute()
@property (nonatomic, strong) SMRequestOSRM * request;
@property (nonatomic, strong) CLLocation * lastRecalcLocation;
@property (nonatomic, strong) NSObject * recalcMutex;
@property CGFloat distanceFromRoute;
@end

@implementation SMRoute {
    double minDistance;
}

- (id)init {
    self = [super init];
    if (self) {
        self.distanceLeft = -1;
        self.tripDistance = -1;
        self.caloriesBurned = -1;
        self.averageSpeed = -1;
        approachingTurn = NO;
        self.lastVisitedWaypointIndex = -1;
        self.recalculationInProgress = NO;
        self.lastRecalcLocation = [[CLLocation alloc] initWithLatitude:0 longitude:0];
        self.recalcMutex = [NSObject new];
    }
    return self;
}

- (id)initWithRouteStart:(CLLocationCoordinate2D)start andEnd:(CLLocationCoordinate2D)end andDelegate:(id<SMRouteDelegate>)dlg {
    return [self initWithRouteStart:start andEnd:end andDelegate:dlg andJSON:nil];
}

- (id)initWithRouteStart:(CLLocationCoordinate2D)start andEnd:(CLLocationCoordinate2D)end andDelegate:(id<SMRouteDelegate>)dlg andJSON:(NSDictionary*) routeJSON {
    self = [self init];
    if (self) {
        [self setLocationStart:start];
        [self setLocationEnd:end];
        [self setDelegate:dlg];
        if (routeJSON == nil) {
            SMRequestOSRM * r = [[SMRequestOSRM alloc] initWithDelegate:self];
            [self setRequest:r];
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

    for (int i = self.lastVisitedWaypointIndex; i < turnB.waypointsIndex; i++) {
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
                [self updateSegment];
                approachingTurn = YES;
            }
            return NO;
        }
    }
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
    return approachingTurn && self.turnInstructions.count == 1;
}

- (void) visitLocation:(CLLocation *)loc {
    
    @synchronized(self.visitedLocations) {
        [self updateDistances:loc];
        if (!self.visitedLocations)
            self.visitedLocations = [NSMutableArray array];
        [self.visitedLocations addObject:@{
         @"location" : loc,
         @"date" : [NSDate date]
         }];
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
    double distanceToFinish = [loc distanceFromLocation:[self getEndLocation]];
    double speed = loc.speed > 0 ? loc.speed : 5;
    int timeToFinish = 100;
    if (speed > 0) {
        timeToFinish = distanceToFinish / speed;
        debugLog(@"finishing in %d", timeToFinish);
    }
    /**
     * are we close to the finish (< 10m or 3s left)?
     */
    if (distanceToFinish < 10.0 || timeToFinish <= 3) {
        if (self.turnInstructions.count == 1) {
            /**
             * if there was only one instruction left go through usual channels
             */
            approachingTurn = NO;
            [self updateSegment];
            return;
        } else {
            /**
             * we have somehow skipped most of the route (going through a park or unknown street)
             */
            [self.delegate reachedDestination];
            return;
        }
    }

    // are we approaching some turn or are we past some turn
    if (approachingTurn) {
        SMTurnInstruction *nextTurn = [self.turnInstructions objectAtIndex:0];
        
        double d = [loc distanceFromLocation:[nextTurn getLocation]];
        if (self.turnInstructions.count > 0 && d > 20.0) {
            if (loc.course >= 0.0)
                debugLog(@"loc.course: %f turn->azimuth: %f", loc.course, nextTurn.azimuth);

            approachingTurn = NO;

//            if (loc.course >= 0.0 && fabs(loc.course - nextTurn.azimuth) > 20.0) {
//                debugLog(@"Missed turn!");
//            } else {
                debugLog(@"Past turn: %@", nextTurn.wayName);
                [self updateSegment];
//            }
        }
    } else if (!approachingTurn) {
        for (int i = 0; i < self.turnInstructions.count; i++) {
            SMTurnInstruction *nextTurn = [self.turnInstructions objectAtIndex:i];
            double distanceFromTurn = [loc distanceFromLocation:[nextTurn getLocation]];
            if ((distanceFromTurn < 10.0 || (i == self.turnInstructions.count - 1 && distanceFromTurn < 20.0))) {
//                && (loc.course < 0.0 || fabs(loc.course - nextTurn.azimuth) <= 20.0)) {
                approachingTurn = YES;
                if (i > 0)
                    [self updateSegment];
                debugLog(@"Approaching turn %@ in %.1g m", nextTurn.wayName, distanceFromTurn);
                break;
            }
        }
    }
    
    // Check if we went too far from the calculated route and, if so, recalculate route
    // max allowed distance depends on location's accuracy
    int maxD = loc.horizontalAccuracy >= 0 ? (loc.horizontalAccuracy / 3 + 20) : MAX_DISTANCE_FROM_PATH;
    if (![self approachingFinish] && self.delegate && [self isTooFarFromRoute:loc maxDistance:maxD]) {
        approachingTurn = NO;
        [self recalculateRoute:loc];
    }
}

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
        return [[self.visitedLocations objectAtIndex:0] objectForKey:@"location"];
    return NULL;
}

- (CLLocation *) getLastVisitedLocation {
    if (self.visitedLocations && self.visitedLocations.count > 0)
        return [[self.visitedLocations lastObject] objectForKey:@"location"];
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

        [locations addObject:[[CLLocation alloc] initWithLatitude:((double)lat / 1e5) longitude:((double)lng / 1e5)]];
    }

    return locations;
}

- (BOOL) parseFromJson:(NSDictionary *)jsonRoot delegate:(id<SMRouteDelegate>) dlg {
    

//    SMRoute *route = [[SMRoute alloc] init];
    @synchronized(self.waypoints) {
        self.waypoints = decodePolyline([jsonRoot objectForKey:@"route_geometry"]);
    }

    if (self.waypoints.count < 2)
        return NO;

    @synchronized(self.turnInstructions) {
        self.turnInstructions = [NSMutableArray array];
    }
    @synchronized(self.pastTurnInstructions) {
        self.pastTurnInstructions = [NSMutableArray array];
    }
    self.estimatedTimeForRoute = [[[jsonRoot objectForKey:@"route_summary"] objectForKey:@"total_time"] integerValue];
    self.estimatedRouteDistance = [[[jsonRoot objectForKey:@"route_summary"] objectForKey:@"total_distance"] integerValue];
    self.routeChecksum = nil;
    self.destinationHint = nil;
    
    if ([jsonRoot objectForKey:@"hint_data"] && [[jsonRoot objectForKey:@"hint_data"] objectForKey:@"checksum"]) {
        self.routeChecksum = [NSString stringWithFormat:@"%@", [[jsonRoot objectForKey:@"hint_data"] objectForKey:@"checksum"]];
    }
    
    if ([jsonRoot objectForKey:@"hint_data"] && [[jsonRoot objectForKey:@"hint_data"] objectForKey:@"locations"] && [[[jsonRoot objectForKey:@"hint_data"] objectForKey:@"locations"] isKindOfClass:[NSArray class]]) {
        self.destinationHint = [NSString stringWithFormat:@"%@", [[[jsonRoot objectForKey:@"hint_data"] objectForKey:@"locations"] lastObject]];
    }
    
    NSArray *routeInstructions = [jsonRoot objectForKey:@"route_instructions"];
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
                
                if (isFirst) {
                    [instruction generateStartDescriptionString];
                    isFirst = NO;
                } else {
                    [instruction generateDescriptionString];
                }
                [instruction generateFullDescriptionString];
                
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
        self.longestStreet = [[jsonRoot objectForKey:@"route_name"] componentsJoinedByString:@", "];
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
        
    }

    self.lastVisitedWaypointIndex = 0;
    return YES;
}

- (void)updateDistances:(CLLocation *)loc {
    if (self.tripDistance < 0.0) {
        self.tripDistance = 0.0;
    }
    if (self.visitedLocations.count > 0) {
        self.tripDistance += [loc distanceFromLocation:[[self.visitedLocations lastObject] objectForKey:@"location"]];
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

- (NSData*) save {
    // TODO save visited locations and posibly some other info
    debugLog(@"Saving route");
    return [NSKeyedArchiver archivedDataWithRootObject:self.visitedLocations];
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
        CLLocation * startLoc = [[self.visitedLocations objectAtIndex:0]  objectForKey:@"location"];
        for (int i = 1; i < [self.visitedLocations count]; i++) {
            distance += [[[self.visitedLocations objectAtIndex:i] objectForKey:@"location"] distanceFromLocation:startLoc];
            startLoc = [[self.visitedLocations objectAtIndex:i] objectForKey:@"location"];
        }
    }
    
    self.tripDistance = roundf(distance);
    
    return self.tripDistance;
}

- (CGFloat)calculateAverageSpeed {
    CGFloat distance = [self calculateDistanceTraveled];
    CGFloat avgSpeed = 0.0f;
    if ([self.visitedLocations count] > 1) {
        NSDate * startLoc = [[self.visitedLocations objectAtIndex:0] objectForKey:@"date"];
        NSDate * endLoc = [[self.visitedLocations lastObject] objectForKey:@"date"];
        if ([endLoc timeIntervalSinceDate:startLoc] > 0) {
            avgSpeed = distance / ([endLoc timeIntervalSinceDate:startLoc]);            
        }
    }
    self.averageSpeed = roundf(avgSpeed * 30.6)/10.0f;
    return self.averageSpeed;
}


- (NSString*)timePassed {
    if ([self.visitedLocations count] > 1) {
        NSDate * startDate = [[self.visitedLocations objectAtIndex:0] objectForKey:@"date"];
        NSDate * endDate = [[self.visitedLocations lastObject] objectForKey:@"date"];
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
        NSDate * startLoc = [[self.visitedLocations objectAtIndex:0] objectForKey:@"date"];
        NSDate * endLoc = [[self.visitedLocations lastObject] objectForKey:@"date"];
        timeSpent = [endLoc timeIntervalSinceDate:startLoc] / 3600.0f;
    }

    return self.caloriesBurned = caloriesBurned(avgSpeed, timeSpent);
}

- (void)setupRoute:(id)jsonRoot{
    BOOL done = [self parseFromJson:jsonRoot delegate:nil];
    if (done) {
        approachingTurn = NO;
        self.tripDistance = 0.0f;
        @synchronized(self.pastTurnInstructions) {
            self.pastTurnInstructions = [NSMutableArray array];
        }
        
        if ([SMLocationManager instance].hasValidLocation) {
            [self updateDistances:[SMLocationManager instance].lastValidLocation];
        }
        
//        if (self.delegate && [self.delegate respondsToSelector:@selector(startRoute)]) {
//            [self.delegate startRoute];
//        }
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

- (void)request:(SMRequestOSRM *)req finishedWithResult:(id)res {
    if ([req.auxParam isEqualToString:@"startRoute"]) {
        NSString * response = [[NSString alloc] initWithData:req.responseData encoding:NSUTF8StringEncoding];
        if (response) {
            id jsonRoot = [NSJSONSerialization JSONObjectWithData:req.responseData options:NSJSONReadingAllowFragments error:nil];//[[[SBJsonParser alloc] init] objectWithString:response];
            if (!jsonRoot || ([jsonRoot isKindOfClass:[NSDictionary class]] == NO) || ([[jsonRoot objectForKey:@"status"] intValue] != 0)) {
                if (self.delegate) {
                    [self.delegate routeNotFound];
                };
                return;
            }
//            BOOL done = [self parseFromJson:jsonRoot delegate:nil];
//            if (done) {
//                approachingTurn = NO;
//                self.tripDistance = 0.0f;
//                @synchronized(self.pastTurnInstructions) {
//                    self.pastTurnInstructions = [NSMutableArray array];
//                }
//                
//                if ([SMLocationManager instance].hasValidLocation) {
//                    [self updateDistances:[SMLocationManager instance].lastValidLocation];
//                }
//                if (self.delegate && [self.delegate respondsToSelector:@selector(startRoute)]) {
//                    [self.delegate startRoute];
//                }
//            }
            [self setupRoute:jsonRoot];
            if (self.delegate && [self.delegate respondsToSelector:@selector(startRoute)]) {
                [self.delegate startRoute];
            }
        }

    } else if ([req.auxParam isEqualToString:@"routeRecalc"]) {
        NSString * response = [[NSString alloc] initWithData:req.responseData encoding:NSUTF8StringEncoding];
        if (response) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                
                
                id jsonRoot = [NSJSONSerialization JSONObjectWithData:req.responseData options:NSJSONReadingAllowFragments error:nil];//[[[SBJsonParser alloc] init] objectWithString:response];
                if (!jsonRoot || ([jsonRoot isKindOfClass:[NSDictionary class]] == NO) || ([[jsonRoot objectForKey:@"status"] intValue] != 0)) {
                    if (self.delegate) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.delegate routeRecalculationDone];
                            return;
                        });
                    }
                };
                
                BOOL done = [self parseFromJson:jsonRoot delegate:nil];
                if (done) {
                    approachingTurn = NO;
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


@end

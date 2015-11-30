//
//  SMRoute.h
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

typedef enum SMRouteType : NSUInteger {
    SMRouteTypeBike = 0,
    SMRouteTypeWalk = 1,
    SMRouteTypeSTrain = 2,
    SMRouteTypeMetro = 3,
    SMRouteTypeBus = 4,
    SMRouteTypeFerry = 5,
    SMRouteTypeTrain = 6,
} SMRouteType;

#import "SMTurnInstruction.h"
#import "SMRequestOSRM.h"

@class SMRoute;

@protocol SMRouteDelegate <NSObject>
@required
- (void) updateTurn:(BOOL)firstElementRemoved;
- (void) reachedDestination;
- (void) updateRoute;
- (void) startRoute:(SMRoute*)route;
- (void) routeNotFound;
- (void) serverError;

@optional
- (void) routeRecalculationStarted;
- (void) routeRecalculationDone;
@end

@interface SMRoute : NSObject <SMRequestOSRMDelegate> {
    BOOL approachingTurn;
    double distanceFromStart;
}

@property (nonatomic, weak) id<SMRouteDelegate> delegate;

@property (nonatomic, strong) NSMutableArray *waypoints;
@property (nonatomic, strong) NSMutableArray *pastTurnInstructions; // turn instrucitons from first to the last passed turn
@property (nonatomic, strong) NSMutableArray *turnInstructions; // turn instruaciton from next to the last
@property (nonatomic, strong) NSMutableArray *visitedLocations;
@property (nonatomic, assign) SMRouteType routeType;
//@property (nonatomic, strong) SMTurnInstruction *lastTurn;

@property CGFloat distanceLeft;
@property CGFloat tripDistance;
@property CGFloat averageSpeed;
@property CGFloat caloriesBurned;

@property CLLocationCoordinate2D locationStart;
@property CLLocationCoordinate2D locationEnd;
@property NSString *startDescription;
@property NSString *endDescription;
@property NSDate *startDate;
@property NSDate *endDate;
@property NSString *transportLine;
@property BOOL recalculationInProgress;
@property NSInteger estimatedTimeForRoute;
@property NSInteger estimatedRouteDistance;
@property NSString * routeChecksum;
@property NSString * destinationHint;
@property CGFloat distanceToFinishRange;

@property (nonatomic, strong) CLLocation * lastCorrectedLocation;
@property double lastCorrectedHeading;

@property (nonatomic, strong) NSString * longestStreet;
@property NSInteger longestDistance;


@property NSInteger lastVisitedWaypointIndex;

@property BOOL snapArrow;

@property (nonatomic, strong) NSString * osrmServer;

- (void) visitLocation:(CLLocation *)loc;
- (CLLocation *) getStartLocation;
- (CLLocation *) getEndLocation;
- (CLLocation *) getFirstVisitedLocation;
- (CLLocation *) getLastVisitedLocation;
- (NSDictionary*) save;

- (CGFloat)calculateDistanceTraveled;
- (CGFloat)calculateAverageSpeed;
- (CGFloat)calculateCaloriesBurned;
- (NSString*)timePassed;

- (id)initWithRouteStart:(CLLocationCoordinate2D)start andEnd:(CLLocationCoordinate2D)end andDelegate:(id<SMRouteDelegate>)dlg;
- (id)initWithRouteStart:(CLLocationCoordinate2D)start andEnd:(CLLocationCoordinate2D)end andDelegate:(id<SMRouteDelegate>)dlg andJSON:(NSDictionary*) routeJSON;
- (void) recalculateRoute:(CLLocation *)loc;

- (double)getCorrectedHeading;
- (BOOL) isOnPath;
@end

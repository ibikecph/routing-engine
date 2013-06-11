//
//  SMRouteConsts.h
//  testRouteMe
//
//  Created by Rasko Gojkovic on 6/10/13.
//  Copyright (c) 2013 Rasko Gojkovic. All rights reserved.
//

#ifndef testRouteMe_SMRouteConsts_h
#define testRouteMe_SMRouteConsts_h

#import "SMTranslation.h"

#if DISTRIBUTION_VERSION
#define debugLog(args...)    // NO logs
#else
#define debugLog(args...)    NSLog(@"%@", [NSString stringWithFormat: args])
#endif

#define translateString(txt) [SMTranslation decodeString:(txt)]

#define OSRM_SERVER @"http://routes.ibikecph.dk"
#define TILE_SOURCE [[RMOpenStreetMapSource alloc] init]

#define MIN_DISTANCE_FOR_RECALCULATION 20.0

#define ZOOM_TO_TURN_DURATION 4 // in seconds
#define DEFAULT_MAP_ZOOM 18.5
#define DEFAULT_TURN_ZOOM 18.5
#define MAX_MAP_ZOOM 20
#define PATH_COLOR [UIColor colorWithRed:0.0f/255.0f green:174.0f/255.0f blue:239.0f/255.0f alpha:1.0f]
#define PATH_OPACITY 0.8f

#define MAX_TURNS 4

#define TIME_FORMAT @"HH.mm"
#define TIME_DAYS_SHORT @"d"
#define TIME_HOURS_SHORT @"h"
#define TIME_MINUTES_SHORT @"min"
#define TIME_SECONDS_SHORT @"s"
#define DISTANCE_KM_SHORT @"km"
#define DISTANCE_M_SHORT @"m"


#endif

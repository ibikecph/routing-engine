//
//  SMRouteConsts.h
//  testRouteMe
//
//  Created by Rasko Gojkovic on 6/10/13.
//  Copyright (C) 2013 City of Copenhagen.  All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
//  If a copy of the MPL was not distributed with this file, You can obtain one at 
//  http://mozilla.org/MPL/2.0/.
//

#ifndef testRouteMe_SMRouteConsts_h
#define testRouteMe_SMRouteConsts_h

#import "SMTranslation.h"
#import "SMRouteSettings.h"

#if DISTRIBUTION_VERSION
#define debugLog(args...)    // NO logs
#else
#define debugLog(args...)    NSLog(@"%@", [NSString stringWithFormat: args])
#define locLog(args...)    [[NSNotificationCenter defaultCenter] postNotificationName:@"notificationAddDebugText" object:nil userInfo:@{@"text" : [NSString stringWithFormat: args]}];
#endif

#define translateString(txt) [SMTranslation decodeString:(txt)]


#define TILE_SOURCE [[RMOpenStreetMapSource alloc] init]

//#define TILE_SOURCE [[SMiBikeCPHMapTileSource alloc] init]

#define MIN_DISTANCE_FOR_RECALCULATION 20.0

#define MAX_TURNS 4

#define TIME_FORMAT @"HH.mm"
#define TIME_DAYS_SHORT @"d"
#define TIME_HOURS_SHORT @"h"
#define TIME_MINUTES_SHORT @"min"
#define TIME_SECONDS_SHORT @"s"
#define DISTANCE_KM_SHORT @"km"
#define DISTANCE_M_SHORT @"m"



#define OSRM_ADDRESS [SMRouteSettings sharedInstance].osrm_address
#define OSRM_SERVER [SMRouteSettings sharedInstance].osrm_server
#define OSRM_SERVER_CARGO [SMRouteSettings sharedInstance].osrm_server_cargo
#define OSRM_SERVER_GREEN [SMRouteSettings sharedInstance].osrm_server_green

#define OSRM_SERVERS @[@{@"name" : translateString(@"bike_type_1"), @"image" : @"normal_grey", @"imageHighlighted" : @"normal_white", @"server" : OSRM_SERVER}, \
@{@"name" : translateString(@"bike_type_2"), @"image" :  @"cargo_grey", @"imageHighlighted" : @"cargo_white", @"server" : OSRM_SERVER_CARGO},\
@{@"name" : translateString(@"bike_type_3"), @"image" :  @"green_grey", @"imageHighlighted" : @"green_white", @"server" : OSRM_SERVER_GREEN}]

#define GEOCODING_SEARCH_RADIUS   [[SMRouteSettings sharedInstance].geocoding_search_radius floatValue]

#define PLACES_SEARCH_RADIUS [SMRouteSettings sharedInstance].places_search_radius
#define KORT_SEARCH_RADIUS [SMRouteSettings sharedInstance].kort_search_radius
#define KORT_SERVICE [SMRouteSettings sharedInstance].kort_service
#define FOURSQUARE_SEARCH_RADIUS [SMRouteSettings sharedInstance].foursquare_search_radius
#define PLACES_LANGUAGE [SMRouteSettings sharedInstance].places_language
#define OIOREST_SEARCH_RADIUS [SMRouteSettings sharedInstance].oiorest_search_radius
#define OIOREST_AUTOCOMPLETE_SEARCH_RADIUS [SMRouteSettings sharedInstance].oiorest_autocomplete_search_radius
#define ROUTE_POLYLINE_PRECISION [SMRouteSettings sharedInstance].route_polyline_precision

#define USE_APPLE_GEOCODER [[SMRouteSettings sharedInstance].use_apple_geocoder boolValue]

//from keys.h
#define FOURSQUARE_ID [SMRouteSettings sharedInstance].foursquare_id
#define FOURSQUARE_SECRET [SMRouteSettings sharedInstance].foursquare_secret
#define KOMMUNE_KODE @"0101"



#endif

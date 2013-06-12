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
#import "SMRouteSettings.h"

#if DISTRIBUTION_VERSION
#define debugLog(args...)    // NO logs
#else
#define debugLog(args...)    NSLog(@"%@", [NSString stringWithFormat: args])
#endif

#define translateString(txt) [SMTranslation decodeString:(txt)]




#define TILE_SOURCE [[RMOpenStreetMapSource alloc] init]

#define MIN_DISTANCE_FOR_RECALCULATION 20.0

#define MAX_TURNS 4

#define TIME_FORMAT @"HH.mm"
#define TIME_DAYS_SHORT @"d"
#define TIME_HOURS_SHORT @"h"
#define TIME_MINUTES_SHORT @"min"
#define TIME_SECONDS_SHORT @"s"
#define DISTANCE_KM_SHORT @"km"
#define DISTANCE_M_SHORT @"m"



//#define OSRM_ADDRESS @"routes.ibikecph.dk"
#define OSRM_ADDRESS [SMRouteSettings sharedInstance].osrm_address
//#define OSRM_SERVER @"http://routes.ibikecph.dk"
#define OSRM_SERVER [SMRouteSettings sharedInstance].osrm_server
//#define OSRM_SERVER_CARGO @"http://routes.ibikecph.dk/cargobike"
#define OSRM_SERVER_CARGO [SMRouteSettings sharedInstance].osrm_server_cargo

//#define GEOCODING_SEARCH_RADIUS 50000.0f
#define GEOCODING_SEARCH_RADIUS   [[SMRouteSettings sharedInstance].geocoding_search_radius floatValue]

//#define PLACES_SEARCH_RADIUS @"20000"
#define PLACES_SEARCH_RADIUS [SMRouteSettings sharedInstance].places_search_radius
//#define FOURSQUARE_SEARCH_RADIUS @"20000"
#define FOURSQUARE_SEARCH_RADIUS [SMRouteSettings sharedInstance].foursquare_search_radius
//#define PLACES_LANGUAGE @"da"
#define PLACES_LANGUAGE [SMRouteSettings sharedInstance].places_language
//#define OIOREST_SEARCH_RADIUS @"50"
#define OIOREST_SEARCH_RADIUS [SMRouteSettings sharedInstance].oiorest_search_radius
//#define OIOREST_AUTOCOMPLETE_SEARCH_RADIUS @"20000"
#define OIOREST_AUTOCOMPLETE_SEARCH_RADIUS [SMRouteSettings sharedInstance].oiorest_autocomplete_search_radius

//#define USE_APPLE_GEOCODER YES
#define USE_APPLE_GEOCODER [[SMRouteSettings sharedInstance].use_apple_geocoder boolValue]

//from keys.h
//#define GOOGLE_ANALYTICS_KEY @"UA-32719126-2"
#define GOOGLE_ANALYTICS_KEY [SMRouteSettings sharedInstance].google_analytics_key
//#define GOOGLE_API_KEY @"AIzaSyAZwBZgYS-61R-gIvp4GtnekJGGrIKh0Dk"
#define GOOGLE_API_KEY [SMRouteSettings sharedInstance].google_api_key

//#define FOURSQUARE_ID @"AFXG5WVI4UTINRGVJZ52ZAWRK454EN4J3FZRJB03J4ZMXQX1"
#define FOURSQUARE_ID [SMRouteSettings sharedInstance].foursquare_id
//#define FOURSQUARE_SECRET @"D2EU4WKSQ2WHQGOK4FJVNRDZUJ4S4YTZVBO1FM4V03NRJWYK"
#define FOURSQUARE_SECRET [SMRouteSettings sharedInstance].foursquare_secret

//#define HOCKEYAPP_BETA_IDENTIFIER @"1817c1e050c09560ff329120cc64b2f8"
#define HOCKEYAPP_BETA_IDENTIFIER [SMRouteSettings sharedInstance].hockeyapp_beta_identifier
//#define HOCKEYAPP_LIVE_IDENTIFIER @"1817c1e050c09560ff329120cc64b2f8"
#define HOCKEYAPP_LIVE_IDENTIFIER [SMRouteSettings sharedInstance].hockeyapp_live_identifier

//#define FB_APP_ID @"478150322233312"
#define FB_APP_ID [SMRouteSettings sharedInstance].fb_app_id


#endif

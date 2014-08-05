//
//  SMRouteSettings.h
//  testRouteMe
//
//  Created by Rasko Gojkovic on 6/12/13.
//  Copyright (C) 2013 City of Copenhagen.
//
//  This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
//  If a copy of the MPL was not distributed with this file, You can obtain one at 
//  http://mozilla.org/MPL/2.0/.
//

#import <Foundation/Foundation.h>


#define DEFAULT_ROUTESETTINGS_FILENAME @"smroute_settings"
#define DEFAULT_PRIVATE_SUFIX @"_private"

@interface SMRouteSettings : NSObject

@property (nonatomic, strong) NSString*  osrm_address;
@property (nonatomic, strong) NSString*  osrm_server;
@property (nonatomic, strong) NSString*  osrm_server_cargo;
@property (nonatomic, strong) NSString*  osrm_server_green;

@property (nonatomic, strong) NSNumber*  geocoding_search_radius; //float

@property (nonatomic, strong) NSString*  places_search_radius;
@property (nonatomic, strong) NSString*  foursquare_search_radius;
@property (nonatomic, assign) int  kort_search_radius;
@property (nonatomic, strong) NSString*  kort_service;
@property (nonatomic, strong) NSString*  places_language;
@property (nonatomic, strong) NSString*  oiorest_search_radius;
@property (nonatomic, strong) NSString*  oiorest_autocomplete_search_radius;

@property (nonatomic, strong) NSNumber*  use_apple_geocoder; //BOOL

//@property (nonatomic, strong) NSString*  google_analytics_key;
//@property (nonatomic, strong) NSString*  google_api_key;
@property (nonatomic, strong) NSString*  foursquare_id;
@property (nonatomic, strong) NSString*  foursquare_secret;
@property (nonatomic, strong) NSString*  foursquare_categories;
@property (nonatomic, strong) NSString*  foursquare_limit;
//@property (nonatomic, strong) NSString*  hockeyapp_beta_identifier;
//@property (nonatomic, strong) NSString*  hockeyapp_live_identifier;
//@property (nonatomic, strong) NSString*  fb_app_id;
@property (nonatomic, strong) NSString*  kort_username;
@property (nonatomic, strong) NSString*  kort_password;
@property (nonatomic, strong) NSString*  kort_max_results;
@property CGFloat route_polyline_precision;



+(SMRouteSettings*)sharedInstance;
@end

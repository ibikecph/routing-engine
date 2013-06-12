//
//  SMRouteSettings.m
//  testRouteMe
//
//  Created by Rasko Gojkovic on 6/12/13.
//  Copyright (c) 2013 Rasko Gojkovic. All rights reserved.
//

#import "SMRouteSettings.h"


//#define OSRM_ADDRESS @"routes.ibikecph.dk"
//#define OSRM_SERVER @"http://routes.ibikecph.dk"
//#define OSRM_SERVER_CARGO @"http://routes.ibikecph.dk/cargobike"
//
//#define GEOCODING_SEARCH_RADIUS 50000.0f
//
//#define PLACES_SEARCH_RADIUS @"20000"
//#define FOURSQUARE_SEARCH_RADIUS @"20000"
//#define PLACES_LANGUAGE @"da"
//#define OIOREST_SEARCH_RADIUS @"50"
//#define OIOREST_AUTOCOMPLETE_SEARCH_RADIUS @"20000"
//
//#define USE_APPLE_GEOCODER YES
//
////from keys.h
//#define GOOGLE_ANALYTICS_KEY @"UA-32719126-2"
//#define GOOGLE_API_KEY @"AIzaSyAZwBZgYS-61R-gIvp4GtnekJGGrIKh0Dk"
//
//#define FOURSQUARE_ID @"AFXG5WVI4UTINRGVJZ52ZAWRK454EN4J3FZRJB03J4ZMXQX1"
//#define FOURSQUARE_SECRET @"D2EU4WKSQ2WHQGOK4FJVNRDZUJ4S4YTZVBO1FM4V03NRJWYK"
//
//#define HOCKEYAPP_BETA_IDENTIFIER @"1817c1e050c09560ff329120cc64b2f8"
//#define HOCKEYAPP_LIVE_IDENTIFIER @"1817c1e050c09560ff329120cc64b2f8"
//
//#define FB_APP_ID @"478150322233312"

static NSLock * _sharingLock;

@implementation SMRouteSettings


-(void)defaultInitialization{
    
    self.osrm_address = nil;
    self.osrm_server = nil;
    self.osrm_server_cargo = nil;
    
    self.geocoding_search_radius = [NSNumber numberWithFloat:50000.0];
    self.places_search_radius = @"20000";
    self.foursquare_search_radius = @"20000";
    self.places_language = @"da";
    self.oiorest_search_radius = @"50";
    self.oiorest_autocomplete_search_radius = @"20000";
    self.use_apple_geocoder = [NSNumber numberWithBool:YES];
    
    //keys
    self.google_analytics_key = nil;
    self.google_api_key = nil;
    self.foursquare_id = nil;
    self.foursquare_secret = nil;
    self.hockeyapp_beta_identifier = nil;
    self.hockeyapp_live_identifier = nil;
    self.fb_app_id = nil;
}

-(void)loadFromDefaultPlist{
    [self defaultInitialization];
    
    NSString * filePath = [[NSBundle mainBundle] pathForResource:DEFAULT_ROUTESETTINGS_FILENAME ofType:@"plist"];
    if(!filePath) return;
    
    NSDictionary * dict = [NSDictionary dictionaryWithContentsOfFile:filePath];
    
    NSString * lwKey;
    for(NSString * keyStr in dict.allKeys){
        lwKey = [keyStr lowercaseString];
        //check if getter exist (that should be sufficient for this class)
        if([self respondsToSelector:NSSelectorFromString(lwKey)]){
            [self setValue:[dict valueForKey:keyStr] forKey:lwKey];
        }
    }
}

+(void)initialize{
    _sharingLock = [NSLock new];
}

+(SMRouteSettings*)sharedInstance{
    static SMRouteSettings * _shared_instance = nil;
    
    [_sharingLock lock];
    if(!_shared_instance){
        _shared_instance = [SMRouteSettings new];
        [_shared_instance loadFromDefaultPlist];
    }
    [_sharingLock unlock];
    
    return _shared_instance;
}
@end

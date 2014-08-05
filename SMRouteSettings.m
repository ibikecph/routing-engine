//
//  SMRouteSettings.m
//  testRouteMe
//
//  Created by Rasko Gojkovic on 6/12/13.
//  Copyright (C) 2013 City of Copenhagen.
//
//  This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
//  If a copy of the MPL was not distributed with this file, You can obtain one at 
//  http://mozilla.org/MPL/2.0/.
//

#import "SMRouteSettings.h"

static NSLock * _sharingLock;

@implementation SMRouteSettings


-(void)defaultInitialization{
    
    self.osrm_address = nil;
    self.osrm_server = nil;
    self.osrm_server_cargo = nil;
    
    self.geocoding_search_radius = [NSNumber numberWithFloat:50000.0];
    self.places_search_radius = @"20000";
    self.foursquare_search_radius = @"20000";
    self.foursquare_categories = @"";
    self.places_language = @"da";
    self.oiorest_search_radius = @"50";
    self.kort_search_radius= 50000;
    self.kort_service= @"RestGeokeys";
    self.oiorest_autocomplete_search_radius = @"20000";
    self.use_apple_geocoder = [NSNumber numberWithBool:YES];
    
    //keys
//    self.google_analytics_key = nil;
//    self.google_api_key = nil;
    self.foursquare_id = nil;
    self.foursquare_secret = nil;
    self.kort_max_results = @"10";
    
    self.foursquare_limit = @"10";
    self.route_polyline_precision = 1e5;
//    self.hockeyapp_beta_identifier = nil;
//    self.hockeyapp_live_identifier = nil;
//    self.fb_app_id = nil;
}

-(void)loadFromDefaultPlist{
    [self defaultInitialization];
    
    [self loadSettingsFromBundlePlist:DEFAULT_ROUTESETTINGS_FILENAME];
    [self loadSettingsFromBundlePlist:[DEFAULT_ROUTESETTINGS_FILENAME stringByAppendingString:DEFAULT_PRIVATE_SUFIX]];
    
//    NSString * filePath = [[NSBundle mainBundle] pathForResource:DEFAULT_ROUTESETTINGS_FILENAME ofType:@"plist"];
//    if(!filePath) return;
//    
//    NSDictionary * dict = [NSDictionary dictionaryWithContentsOfFile:filePath];
//    
//    NSString * lwKey;
//    for(NSString * keyStr in dict.allKeys){
//        lwKey = [keyStr lowercaseString];
//        //check if getter exist (that should be sufficient for this class)
//        if([self respondsToSelector:NSSelectorFromString(lwKey)]){
//            [self setValue:[dict valueForKey:keyStr] forKey:lwKey];
//        }
//    }
//    
//    filePath = [[NSBundle mainBundle] pathForResource:DEFAULT_ROUTESETTINGS_FILENAME ofType:@"plist"];
//    if(!filePath) return;
}

-(BOOL) loadSettingsFromBundlePlist:(NSString*)fileName{
    NSString * filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"plist"];
    if(!filePath) return NO;
    
    NSDictionary * dict = [NSDictionary dictionaryWithContentsOfFile:filePath];
    
    NSString * lwKey;
    for(NSString * keyStr in dict.allKeys){
        lwKey = [keyStr lowercaseString];
        //check if getter exist (that should be sufficient for this class)
        if([self respondsToSelector:NSSelectorFromString(lwKey)]){
            [self setValue:[dict valueForKey:keyStr] forKey:lwKey];
        }
    }
    
    return YES;
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

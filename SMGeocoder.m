//
//  SMGeocoder.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 07/02/2013.
//  Copyright (C) 2013 City of Copenhagen.
//
//  This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
//  If a copy of the MPL was not distributed with this file, You can obtain one at 
//  http://mozilla.org/MPL/2.0/.
//

#import "SMGeocoder.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import "SMLocationManager.h"
#import "NSString+URLEncode.h"
#import "SMAddressParser.h"

@implementation SMGeocoder

+ (void)geocode:(NSString*)str completionHandler:(void (^)(NSArray* placemarks, NSError* error)) handler {
//    if (USE_APPLE_GEOCODER) {
//        [SMGeocoder appleGeocode:str completionHandler:handler];
//    } else {
//        [SMGeocoder oiorestGeocode:str completionHandler:handler];
//    }
    [SMGeocoder kortGeocode:str completionHandler:handler];
}

+ (void)oiorestGeocode:(NSString*)str completionHandler:(void (^)(NSArray* placemarks, NSError* error)) handler{
    NSString * s = [NSString stringWithFormat:@"http://geo.oiorest.dk/adresser.json?q=%@", [str urlEncode]];
    NSURLRequest * req = [NSURLRequest requestWithURL:[NSURL URLWithString:s]];
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * response, NSData * data, NSError *error) {
        
        id res = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];//[[[SBJsonParser alloc] init] objectWithData:data];
        if ([res isKindOfClass:[NSArray class]] == NO) {
            res = @[res];
        }
        if (error) {
            handler(@[], error);
        } else if ([(NSArray*)res count] == 0) {
            handler(@[], [NSError errorWithDomain:NSOSStatusErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey : @"Wrong data returned from the OIOREST"}]);
        } else {
            NSMutableArray * arr = [NSMutableArray array];
            for (NSDictionary * d in (NSArray*) res) {
                NSDictionary * dict = @{
                                        (NSString *)kABPersonAddressStreetKey : [NSString stringWithFormat:@"%@ %@", [[d objectForKey:@"vejnavn"] objectForKey:@"navn"], [d objectForKey:@"husnr"]],
                                        (NSString *)kABPersonAddressZIPKey : [[d objectForKey:@"postnummer"] objectForKey:@"nr"],
                                        (NSString *)kABPersonAddressCityKey : [[d objectForKey:@"kommune"] objectForKey:@"navn"],
                                        (NSString *)kABPersonAddressCountryKey : @"Denmark"
                                        };
                MKPlacemark * pl = [[MKPlacemark alloc]
                                    initWithCoordinate:CLLocationCoordinate2DMake([[[d objectForKey:@"wgs84koordinat"] objectForKey:@"bredde"] doubleValue], [[[d objectForKey:@"wgs84koordinat"] objectForKey:@"længde"] doubleValue])
                                    addressDictionary:dict];
                [arr addObject:pl];
            }
            handler(arr, nil);
        }
    }];
}

+ (void)kortPlaceGeocode:(NSString*)str completionHandler:(void (^)(NSArray* placemarks, NSError* error)) handler {
    NSString* URLString= [[NSString stringWithFormat:@"http://kortforsyningen.kms.dk/?servicename=%@&method=sted&stednavn=*%@*&geop=%lf,%lf&georef=EPSG:4326&outgeoref=EPSG:4326&login=%@&password=%@&hits=%@", KORT_SERVICE,
                           str, [SMLocationManager instance].lastValidLocation.coordinate.longitude, [SMLocationManager instance].lastValidLocation.coordinate.latitude, [SMRouteSettings sharedInstance].kort_username, [SMRouteSettings sharedInstance].kort_password, [SMRouteSettings sharedInstance].kort_max_results] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURLRequest * req = [NSURLRequest requestWithURL:[NSURL URLWithString:URLString]];
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * response, NSData * data, NSError *error) {
        
        id res = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];//[[[SBJsonParser alloc] init] objectWithData:data];
        if (error) {
            handler(@[], error);
        } else if ([(NSArray*)res count] == 0) {
            handler(@[], [NSError errorWithDomain:NSOSStatusErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey : @"Wrong data returned from the KMS"}]);
        } else {
            NSString* nameKey= @"navn";
            NSDictionary* json= (NSDictionary*)res;
            NSMutableCharacterSet * set = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
            [set addCharactersInString:@","];
            NSMutableArray * arr = [NSMutableArray array];
            for (NSString* key in json.allKeys) {
                if ([key isEqualToString:@"features"]) {
                    NSArray* features= [json objectForKey:key]; // array of features (dictionaries)
                    for(NSDictionary* feature in features){
                        NSMutableDictionary * val = [NSMutableDictionary dictionaryWithDictionary: @{@"source" : @"autocomplete",
                                                                                                     @"subsource" : @"places",
                                                                                                     @"order" : @2
                                                                                                     }];
                        
                        
                        NSDictionary* attributes=[feature objectForKey:@"properties"];
                        NSArray* geometryInfo= [feature objectForKey:@"bbox"];
                        [val setObject:[NSNumber numberWithDouble:([[geometryInfo objectAtIndex:1] doubleValue] + [[geometryInfo objectAtIndex:3] doubleValue])/2.0f] forKey:@"lat"];
                        [val setObject:[NSNumber numberWithDouble:([[geometryInfo objectAtIndex:0] doubleValue] + [[geometryInfo objectAtIndex:2] doubleValue])/2.0f] forKey:@"long"];
                        
                        NSString* streetName= [[attributes objectForKey:nameKey] stringByTrimmingCharactersInSet:set];
                        if(!streetName) {
                            continue;
                        }
                        
                        [val setObject:streetName forKey:@"name"];
                        
                        [val setObject:[NSNumber numberWithDouble:[[attributes objectForKey:@"afstand_afstand"] doubleValue]] forKey:@"distance"];
                        
                        NSDictionary * dict = @{
                                                (NSString *)kABPersonAddressStreetKey : [val objectForKey:@"name"]
                                                };
                        MKPlacemark * pl = [[MKPlacemark alloc]
                                            initWithCoordinate:CLLocationCoordinate2DMake([[val objectForKey:@"lat"] doubleValue], [[val objectForKey:@"long"] doubleValue])
                                            addressDictionary:dict];
                        [arr addObject:pl];
                    }
                    
                }
            }
            handler(arr, nil);
        }
    }];
}

+ (void)kortAddressGeocode:(NSDictionary*)dict completionHandler:(void (^)(NSArray* placemarks, NSError* error)) handler {
    NSString * s = @"";
    NSMutableArray * arr = [NSMutableArray array];
    if ([dict objectForKey:@"street"]) {
        [arr addObject:[NSString stringWithFormat:@"vejnavn=*%@*", [dict objectForKey:@"street"]]];
    }
    if ([dict objectForKey:@"number"]) {
        [arr addObject:[NSString stringWithFormat:@"husnr=%@", [dict objectForKey:@"number"]]];
    }
    if ([dict objectForKey:@"city"]) {
        [arr addObject:[NSString stringWithFormat:@"postdist=*%@*", [dict objectForKey:@"city"]]];
    }
    if ([dict objectForKey:@"zip"]) {
        [arr addObject:[NSString stringWithFormat:@"postnr=%@", [dict objectForKey:@"zip"]]];
    }
    
    s = [arr componentsJoinedByString:@"&"];
    
    NSString * URLString= [[NSString stringWithFormat:@"http://kortforsyningen.kms.dk/?servicename=%@&method=adresse&%@&geop=%lf,%lf&georef=EPSG:4326&outgeoref=EPSG:4326&login=%@&password=%@&hits=%@&geometry=true", KORT_SERVICE,
                            s, [SMLocationManager instance].lastValidLocation.coordinate.longitude, [SMLocationManager instance].lastValidLocation.coordinate.latitude, [SMRouteSettings sharedInstance].kort_username, [SMRouteSettings sharedInstance].kort_password, [SMRouteSettings sharedInstance].kort_max_results] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSURLRequest * req = [NSURLRequest requestWithURL:[NSURL URLWithString:URLString]];
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * response, NSData * data, NSError *error) {
        
        id res = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];//[[[SBJsonParser alloc] init] objectWithData:data];
        if (error) {
            handler(@[], error);
        } else if ([(NSArray*)res count] == 0) {
            handler(@[], [NSError errorWithDomain:NSOSStatusErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey : @"Wrong data returned from the OIOREST"}]);
        } else {
            NSString* nameKey2= @"vej_navn";
            NSString* zipKey= @"postdistrikt_kode";
            NSString* houseKey= @"husnr";
            NSString* distanceKey= @"afstand_afstand";
            NSString* municipalityKey= @"postdistrikt_navn";
            
            NSMutableArray * arr = [NSMutableArray array];
            NSDictionary* json= (NSDictionary*)res;
            NSMutableCharacterSet * set = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
            [set addCharactersInString:@","];
            for (NSString* key in json.allKeys) {
                if ([key isEqualToString:@"features"]) {
                    NSArray* features= [json objectForKey:key]; // array of features (dictionaries)
                    for(NSDictionary* feature in features){
                        NSMutableDictionary * val = [NSMutableDictionary dictionaryWithDictionary: @{}];
                        
                        
                        NSDictionary* attributes=[feature objectForKey:@"properties"];
                        NSArray* geometryInfo= [[feature objectForKey:@"geometry"] objectForKey:@"coordinates"];
                        [val setObject:[NSNumber numberWithDouble:[[geometryInfo objectAtIndex:1] doubleValue]] forKey:@"lat"];
                        [val setObject:[NSNumber numberWithDouble:[[geometryInfo objectAtIndex:0] doubleValue]] forKey:@"long"];
                        
                        
                        NSString* streetName= [attributes objectForKey:nameKey2];
                        if(!streetName) {
                            continue;
                        }
                        NSString* municipalityName= [attributes objectForKey:municipalityKey];
                        if (!municipalityName) {
                            municipalityName= @"";
                        }
                        
                        NSString* municipalityCode= [attributes objectForKey:zipKey];
                        if (!municipalityCode) {
                            municipalityCode= @"";
                        }
                        
                        NSString* houseNumber = [NSString stringWithFormat:@"%@", [attributes objectForKey:houseKey]];
                        
                        double distance = [[attributes objectForKey:distanceKey] doubleValue];
                        [val setObject:[NSNumber numberWithDouble:distance] forKey:@"distance"];
                        
                        NSDictionary * dict = @{
                                                (NSString *)kABPersonAddressStreetKey : [NSString stringWithFormat:@"%@ %@", streetName, houseNumber],
                                                (NSString *)kABPersonAddressZIPKey : municipalityCode,
                                                (NSString *)kABPersonAddressCityKey : municipalityName,
                                                (NSString *)kABPersonAddressCountryKey : @"Denmark"
                                                };
                        MKPlacemark * pl = [[MKPlacemark alloc]
                                            initWithCoordinate:CLLocationCoordinate2DMake([[val objectForKey:@"lat"] doubleValue], [[val objectForKey:@"long"] doubleValue])
                                            addressDictionary:dict];
                        
                        [arr addObject:pl];
                    }
                }
            }
            handler(arr, nil);
        }
    }];
}


+ (void)kortGeocode:(NSString*)str completionHandler:(void (^)(NSArray* placemarks, NSError* error)) handler{
    NSDictionary * d = [SMAddressParser parseAddress:str];
    if ([d objectForKey:@"number"] == nil && [d objectForKey:@"city"] == nil && [d objectForKey:@"zip"] == nil) {
        [self kortPlaceGeocode:str completionHandler:handler];
    } else {
        [self kortAddressGeocode:d completionHandler:handler];
    }
}


+ (void)appleGeocode:(NSString*)str completionHandler:(void (^)(NSArray* placemarks, NSError* error)) handler {
    CLGeocoder * cl = [[CLGeocoder alloc] init];
    [cl geocodeAddressString:str completionHandler:^(NSArray *placemarks, NSError *error) {
        NSMutableArray * ret = [NSMutableArray array];
        for (CLPlacemark * pl in placemarks) {
            if ([SMLocationManager instance].hasValidLocation) {
                [ret addObject:[[MKPlacemark alloc] initWithPlacemark:pl]];
            } else {
                [ret addObject:[[MKPlacemark alloc] initWithPlacemark:pl]];
            }
        }
        handler(ret, error);
    }];
}

+ (void)appleReverseGeocode:(CLLocationCoordinate2D)coord completionHandler:(void (^)(NSDictionary * response, NSError* error)) handler {
    CLGeocoder * cl = [[CLGeocoder alloc] init];
    [cl reverseGeocodeLocation:[[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude] completionHandler:^(NSArray *placemarks, NSError *error) {
        NSString * title = @"";
        NSString * subtitle = @"";
        NSMutableArray * arr = [NSMutableArray array];
        if ([placemarks count] > 0) {
            MKPlacemark * d = [placemarks objectAtIndex:0];
            title = [NSString stringWithFormat:@"%@", [[d addressDictionary] objectForKey:@"Street"]?[[d addressDictionary] objectForKey:@"Street"]:@""];
            subtitle = [NSString stringWithFormat:@"%@ %@", [[d addressDictionary] objectForKey:@"ZIP"]?[[d addressDictionary] objectForKey:@"ZIP"]:@"", [[d addressDictionary] objectForKey:@"City"]?[[d addressDictionary] objectForKey:@"City"]:@""];
            for (MKPlacemark* d in placemarks) {
                [arr addObject:@{
                 @"street" : [[d addressDictionary] objectForKey:@"Street"]?[[d addressDictionary] objectForKey:@"Street"]:@"",
                 @"house_number" : @"",
                 @"zip" : [[d addressDictionary] objectForKey:@"ZIP"]?[[d addressDictionary] objectForKey:@"ZIP"]:@"",
                 @"city" : [[d addressDictionary] objectForKey:@"City"]?[[d addressDictionary] objectForKey:@"City"]:@""
                 }];
            }
        }
        handler(@{@"title" : title, @"subtitle" : subtitle, @"near": arr}, nil);
    }];
}


+ (void)oiorestReverseGeocode:(CLLocationCoordinate2D)coord completionHandler:(void (^)(NSDictionary * response, NSError* error)) handler {
    NSString* s = [NSString stringWithFormat:@"http://geo.oiorest.dk/adresser/%f,%f.json", coord.latitude, coord.longitude];
    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:s]];
    
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            handler(@{}, error);
        } else {
            if (data) {
                NSString * s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                id res = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];//[[[SBJsonParser alloc] init] objectWithData:data];
                if (res == nil) {
                    handler(@{}, [NSError errorWithDomain:NSOSStatusErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Wrong data returned from the OIOREST: %@", s]}]);
                    return;
                }
                if ([res isKindOfClass:[NSArray class]] == NO) {
                    res = @[res];
                }
                NSMutableArray* arr = [NSMutableArray array];
                NSString* title = @"";
                NSString* subtitle = @"";
                if ([(NSArray*)res count] > 0) {
                    NSDictionary* d = [res objectAtIndex:0];
                    title = [NSString stringWithFormat:@"%@ %@", [[d objectForKey:@"vejnavn"] objectForKey:@"navn"], [d objectForKey:@"husnr"]];
                    subtitle = [NSString stringWithFormat:@"%@ %@", [[d objectForKey:@"postnummer"] objectForKey:@"nr"], [[d objectForKey:@"kommune"] objectForKey:@"navn"]];
                }
                for (NSDictionary* d in res) {
                    [arr addObject:@{
                     @"street" : [[d objectForKey:@"vejnavn"] objectForKey:@"navn"],
                     @"house_number" : [d objectForKey:@"husnr"],
                     @"zip" : [[d objectForKey:@"postnummer"] objectForKey:@"nr"],
                     @"city" : [[d objectForKey:@"kommune"] objectForKey:@"navn"]
                     }];
                }
                 handler(@{@"title" : title, @"subtitle" : subtitle, @"near": arr}, nil);
            } else {
                handler(@{}, [NSError errorWithDomain:NSOSStatusErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey : @"Wrong data returned from the OIOREST"}]);
            }
        }
    }];
}

/**
 * use KMS to get coordinates at location.
 * we fetch 10 nearest coordinates and order by distance
 */
+ (void)kortReverseGeocode:(CLLocationCoordinate2D)coord completionHandler:(void (^)(NSDictionary * response, NSError* error)) handler {
    
    NSString* URLString= [[NSString stringWithFormat:@"http://kortforsyningen.kms.dk/?servicename=%@&hits=10&method=nadresse&geop=%lf,%lf&georef=EPSG:4326&georad=%d&outgeoref=EPSG:4326&login=%@&password=%@&geometry=false", KORT_SERVICE,
                           coord.longitude, coord.latitude, KORT_SEARCH_RADIUS, [SMRouteSettings sharedInstance].kort_username, [SMRouteSettings sharedInstance].kort_password] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    debugLog(@"Kort: %@", URLString);
    NSURLRequest * req = [NSURLRequest requestWithURL:[NSURL URLWithString:URLString]];
    
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            handler(@{}, error);
        } else {
            if (data) {
                NSString * s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                id res = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];//[[[SBJsonParser alloc] init] objectWithData:data];
                if (res == nil || [res isKindOfClass:[NSDictionary class]] == NO) {
                    handler(@{}, [NSError errorWithDomain:NSOSStatusErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Wrong data returned from the KORT: %@", s]}]);
                    return;
                }
                NSDictionary * json = (NSDictionary*)res;
                
                NSArray * x = [[json objectForKey:@"features"] sortedArrayUsingComparator:^NSComparisonResult(NSDictionary * obj1, NSDictionary * obj2) {
                    return [[[obj1 objectForKey:@"properties"] objectForKey:@"afstand_afstand"] compare:[[obj2 objectForKey:@"properties"] objectForKey:@"afstand_afstand"]];
                }];
                
                NSMutableArray * arr = [NSMutableArray array];

                NSString* title = @"";
                NSString* subtitle = @"";
                if ([x count] > 0) {
                    NSDictionary* d = [[x objectAtIndex:0] objectForKey:@"properties"];
                    title = [NSString stringWithFormat:@"%@ %@", [d objectForKey:@"vej_navn"], [d objectForKey:@"husnr"]];
                    subtitle = [NSString stringWithFormat:@"%@ %@", [d objectForKey:@"postdistrikt_kode"], [d objectForKey:@"postdistrikt_navn"]];
                }
                for (NSDictionary* d1 in x) {
                    NSDictionary* d = [d1 objectForKey:@"properties"];
                    [arr addObject:@{
                                     @"street" : [d objectForKey:@"vej_navn"],
                                     @"house_number" : [d objectForKey:@"husnr"],
                                     @"zip" : [d objectForKey:@"postdistrikt_kode"],
                                     @"city" : [d objectForKey:@"postdistrikt_navn"]
                                     }];
                }
                handler(@{@"title" : title, @"subtitle" : subtitle, @"near": arr}, nil);
            } else {
                handler(@{}, [NSError errorWithDomain:NSOSStatusErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey : @"Wrong data returned from the OIOREST"}]);
            }
        }
    }];
}

+ (void)reverseGeocode:(CLLocationCoordinate2D)coord completionHandler:(void (^)(NSDictionary * response, NSError* error)) handler {
//    if (USE_APPLE_GEOCODER) {
//        [SMGeocoder appleReverseGeocode:coord completionHandler:handler];
//    } else {
//        [SMGeocoder oiorestReverseGeocode:coord completionHandler:handler];
//    }
    [SMGeocoder kortReverseGeocode:coord completionHandler:handler];
}

@end

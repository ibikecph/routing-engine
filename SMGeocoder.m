//
//  SMGeocoder.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 07/02/2013.
//  Copyright (C) 2013 City of Copenhagen.  All rights reserved.
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
            NSMutableArray *arr = [NSMutableArray array];
            for (NSDictionary *d in (NSArray *)res) {
                OiorestItem *item = [[OiorestItem alloc] initWithJsonDictionary:d];
                NSDictionary * dict = @{
                                        (NSString *)kABPersonAddressStreetKey : [NSString stringWithFormat:@"%@ %@", item.street, item.number],
                                        (NSString *)kABPersonAddressZIPKey : item.zip,
                                        (NSString *)kABPersonAddressCityKey : item.zip,
                                        (NSString *)kABPersonAddressCountryKey : item.country
                                        };
                MKPlacemark * pl = [[MKPlacemark alloc] initWithCoordinate:item.location.coordinate addressDictionary:dict];
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
            NSDictionary* json= (NSDictionary*)res;
            NSMutableCharacterSet * set = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
            [set addCharactersInString:@","];
            NSMutableArray * arr = [NSMutableArray array];
           
            for(NSDictionary* feature in json[@"features"]){
                KortforItem *item = [[KortforItem alloc] initWithJsonDictionary:feature];
                
                NSString *formattedAddress = [[NSString stringWithFormat:@"%@ %@, %@ %@", item.street, item.number, item.zip, item.city] stringByTrimmingCharactersInSet:set];
                item.name = formattedAddress;
                item.address = formattedAddress;
                
                NSDictionary * dict = @{
                                        (NSString *)kABPersonAddressStreetKey : item.name
                                        };
                MKPlacemark * pl = [[MKPlacemark alloc] initWithCoordinate:item.location.coordinate addressDictionary:dict];
                [arr addObject:pl];
            }
            handler(arr, nil);
        }
    }];
}

+ (void)kortAddressGeocode:(NSObject<SearchListItem> *)item completionHandler:(void (^)(NSArray* placemarks, NSError* error)) handler {
    NSString * s = @"";
    NSMutableArray * arr = [NSMutableArray array];
    if (item.street.length != 0) {
        [arr addObject:[NSString stringWithFormat:@"vejnavn=*%@*", item.street]];
    }
    if (item.number.length != 0) {
        [arr addObject:[NSString stringWithFormat:@"husnr=%@", item.number]];
    }
    if (item.city.length != 0) {
        [arr addObject:[NSString stringWithFormat:@"postdist=*%@*", item.city]];
    }
    if (item.zip.length != 0) {
        [arr addObject:[NSString stringWithFormat:@"postnr=%@", item.zip]];
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
            NSDictionary* json= (NSDictionary*)res;
            NSMutableCharacterSet * set = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
            [set addCharactersInString:@","];
            NSMutableArray * arr = [NSMutableArray array];
            
            for(NSDictionary* feature in json[@"features"]){
                KortforItem *item = [[KortforItem alloc] initWithJsonDictionary:feature];
                
                NSString *formattedAddress = [[NSString stringWithFormat:@"%@ %@, %@ %@", item.street, item.number, item.zip, item.city] stringByTrimmingCharactersInSet:set];
                item.name = formattedAddress;
                item.address = formattedAddress;
                
                NSDictionary * dict = @{
                                        (NSString *)kABPersonAddressStreetKey : [NSString stringWithFormat:@"%@ %@", item.street, item.number],
                                        (NSString *)kABPersonAddressZIPKey : item.zip,
                                        (NSString *)kABPersonAddressCityKey : item.city,
                                        (NSString *)kABPersonAddressCountryKey : @"Denmark"
                                        };
                MKPlacemark * pl = [[MKPlacemark alloc] initWithCoordinate:item.location.coordinate addressDictionary:dict];
                [arr addObject:pl];
            }
            handler(arr, nil);
        }
    }];
}


+ (void)kortGeocode:(NSString*)str completionHandler:(void (^)(NSArray* placemarks, NSError* error)) handler{
    NSObject<SearchListItem> *item = [SMAddressParser parseAddress:str];
    if (item.number.length == 0 && item.city.length == 0 && item.zip.length == 0) {
        [self kortPlaceGeocode:str completionHandler:handler];
    } else {
        [self kortAddressGeocode:item completionHandler:handler];
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
            MKPlacemark * placemark = [placemarks objectAtIndex:0];
            NSString *street = [placemark addressDictionary][@"Street"] ?: @"";
            title = street;
            NSString *zip = [placemark addressDictionary][@"ZIP"] ?: @"";
            NSString *city = [placemark addressDictionary][@"City"] ?: @"";
            subtitle = [NSString stringWithFormat:@"%@ %@", zip, city];
            for (MKPlacemark* localPlacemark in placemarks) {
                NSString *street = [localPlacemark addressDictionary][@"Street"] ?: @"";
                title = street;
                NSString *zip = [localPlacemark addressDictionary][@"ZIP"] ?: @"";
                NSString *city = [localPlacemark addressDictionary][@"City"] ?: @"";
                [arr addObject:@{
                                 @"street" : street,
                                 @"house_number" : @"",
                                 @"zip" : zip,
                                 @"city" : city
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
                    OiorestItem *item = [[OiorestItem alloc] initWithJsonDictionary:res[0]];
                    title = [NSString stringWithFormat:@"%@ %@", item.street, item.number];
                    subtitle = [NSString stringWithFormat:@"%@ %@", item.zip, item.city];
                }
                for (NSDictionary* d in res) {
                    OiorestItem *item = [[OiorestItem alloc] initWithJsonDictionary:d];
                    [arr addObject:@{
                                     @"street" : item.street,
                                     @"house_number" : item.number,
                                     @"zip" : item.zip,
                                     @"city" : item.city
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
+ (void)kortReverseGeocode:(CLLocationCoordinate2D)coord completionHandler:(void (^)(KortforItem *kortforItem, NSError* error)) handler {
    
    NSString* URLString= [[NSString stringWithFormat:@"http://kortforsyningen.kms.dk/?servicename=%@&hits=10&method=nadresse&geop=%lf,%lf&georef=EPSG:4326&georad=%d&outgeoref=EPSG:4326&login=%@&password=%@&geometry=false", KORT_SERVICE,
                           coord.longitude, coord.latitude, KORT_SEARCH_RADIUS, [SMRouteSettings sharedInstance].kort_username, [SMRouteSettings sharedInstance].kort_password] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    debugLog(@"Kort: %@", URLString);
    NSURLRequest * req = [NSURLRequest requestWithURL:[NSURL URLWithString:URLString]];
    
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            handler(nil, error);
            return;
        }
        if (!data) {
            handler(nil, [NSError errorWithDomain:NSOSStatusErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey : @"Wrong data returned from the OIOREST"}]);
        }
        
        NSString * s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        id res = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];//[[[SBJsonParser alloc] init] objectWithData:data];
        if (res == nil || [res isKindOfClass:[NSDictionary class]] == NO) {
            handler(nil, [NSError errorWithDomain:NSOSStatusErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Wrong data returned from the KORT: %@", s]}]);
            return;
        }
        NSDictionary * json = (NSDictionary*)res;
    
        NSMutableCharacterSet * set = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
        [set addCharactersInString:@","];
       
        // Kortfor
        NSMutableArray *kortforItems = [NSMutableArray new];
        for (NSDictionary *feature in json[@"features"]){
            KortforItem *item = [[KortforItem alloc] initWithJsonDictionary:feature];
            
            // TODO: Move address formatting to modelclasses
            NSString *formattedAddress = [[NSString stringWithFormat:@"%@ %@, %@ %@", item.street, item.number, item.zip, item.city] stringByTrimmingCharactersInSet:set];
            item.name = formattedAddress;
            item.address = formattedAddress;
            [kortforItems addObject:item];
        }
        // Sort
        NSArray *sortedKortforItems = [kortforItems sortedArrayUsingComparator:^NSComparisonResult(KortforItem *obj1, KortforItem *obj2){
            long first = obj1.distance;
            long second = obj2.distance;
            
            if(first<second)
                return NSOrderedAscending;
            else if(first>second)
                return NSOrderedDescending;
            else
                return NSOrderedSame;
        }];
        
        KortforItem *item = sortedKortforItems.firstObject;
        if (!item) {
            NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"No items returned from the KORT: %@", s]}];
            handler(nil, error);
            return;
        }
        handler(item, nil);
    }];
}

+ (void)reverseGeocode:(CLLocationCoordinate2D)coord completionHandler:(void (^)(KortforItem *kortforItem, NSError* error)) handler {
    [SMGeocoder kortReverseGeocode:coord completionHandler:handler];
}

@end

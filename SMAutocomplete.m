//
//  SMAutocomplete.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 30/01/2013.
//  Copyright (C) 2013 City of Copenhagen.  All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
//  If a copy of the MPL was not distributed with this file, You can obtain one at 
//  http://mozilla.org/MPL/2.0/.
//

#import "SMAutocomplete.h"
#import "SMLocationManager.h"
#import "NSString+Relevance.h"
#import "NSString+URLEncode.h"
#import "SMRouteUtils.h"
#import "SMRouteConsts.h"

typedef enum {
    autocompleteOiorest,
    autocompleteFoursquare,
    autocompleteKortforsyningen
} AutocompleteType;

@interface SMAutocomplete() {
    AutocompleteType completeType;
}
@property (nonatomic, weak) id<SMAutocompleteDelegate> delegate;
@property (nonatomic, strong) NSString * srchString;
@property (nonatomic, strong) NSMutableArray * resultsArr;
@end

@implementation SMAutocomplete

- (id)initWithDelegate:(id<SMAutocompleteDelegate>)dlg {
    self = [super init];
    if (self) {
        [self setDelegate:dlg];
    }
    return self;
}

- (void)getAutocomplete:(NSString*)str {
    self.srchString = str;
    self.resultsArr = [NSMutableArray array];
    [self getFoursquareAutocomplete];
    [self getKortforsyningenAutocomplete];
    UnknownSearchListItem * item = [SMAddressParser parseAddress:self.srchString];
    if (item.number == nil && item.city == nil && item.zip == nil) {
        [self getKortforsyningenPlacesSearch];
    }
}

// TODO: Is this code unused
- (void)getOiorestAutocomplete {
    NSURLRequest * req = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://geo.oiorest.dk/adresser.json?q=%@&maxantal=50", [self.srchString urlEncode]]]];
    debugLog(@"%@", req);
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * response, NSData * data, NSError * error) {
        if (data) {
            NSDictionary * res = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
            NSMutableArray * arr = [NSMutableArray array];
            NSMutableArray * terms = [NSMutableArray array];
            for (NSString * str in [[self.srchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsSeparatedByString:@" "]) {
                if ([terms indexOfObject:str] == NSNotFound) {
                    [terms addObject:str];
                }
            }
            for (NSDictionary *d in res) {
                OiorestItem *item = [[OiorestItem alloc] initWithJsonDictionary:d];
                if (item.zip.integerValue >= 1000 && item.zip.integerValue <= 2999) {
                    [arr addObject:item];
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                @synchronized(self.resultsArr) {
                    [self.resultsArr addObjectsFromArray:arr];
                    [self.resultsArr sortUsingComparator:^NSComparisonResult(FoursquareItem *obj1, FoursquareItem * obj2) {
                        double d1 = obj1.distance;
                        double d2 = obj2.distance;
                        if (d1 > d2) {
                            return NSOrderedDescending;
                        } else if (d1 < d2) {
                            return NSOrderedAscending;
                        } else {
                            return NSOrderedSame;
                        }
                    }];
                    
                }
                if (self.delegate) {
                    [self.delegate autocompleteEntriesFound:self.resultsArr forString:self.srchString];
                }
            });
        }
    }];
}

- (void)getFoursquareAutocomplete {
    completeType = autocompleteFoursquare;
    if ([SMLocationManager instance].hasValidLocation) {
        NSURLRequest * req = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.foursquare.com/v2/venues/suggestcompletion?ll=%f,%f&client_id=%@&client_secret=%@&query=%@&v=%@&radius=%@", [SMLocationManager instance].lastValidLocation.coordinate.latitude, [SMLocationManager instance].lastValidLocation.coordinate.longitude, FOURSQUARE_ID, FOURSQUARE_SECRET, [[self.srchString removeAccents] urlEncode], @"20130301", FOURSQUARE_SEARCH_RADIUS]]];
//        NSURLRequest * req = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.foursquare.com/v2/venues/search?ll=%f,%f&client_id=%@&client_secret=%@&query=%@&v=%@&radius=%@", [SMLocationManager instance].lastValidLocation.coordinate.latitude, [SMLocationManager instance].lastValidLocation.coordinate.longitude, FOURSQUARE_ID, FOURSQUARE_SECRET, [[self.srchString removeAccents] urlEncode], @"20130301", FOURSQUARE_SEARCH_RADIUS]]];
        debugLog(@"%@", req);
        [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * response, NSData * data, NSError * error) {
            if (data) {
                NSDictionary * res = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
                NSMutableArray * arr = [NSMutableArray array];
                
                for (NSDictionary* d in res[@"response"][@"minivenues"]) {
                    FoursquareItem *item = [[FoursquareItem alloc] initWithJsonDictionary:d];
                    item.relevance = [SMRouteUtils pointsForName:item.name andAddress:item.address andTerms:self.srchString];
                    if (item.location.coordinate.latitude != 0 &&
                        item.location.coordinate.longitude != 0) {
                        item.distance = [[SMLocationManager instance].lastValidLocation distanceFromLocation:item.location];
                        [arr addObject:item];
                    }
                    
                    [arr sortUsingComparator:^NSComparisonResult(FoursquareItem *obj1, FoursquareItem * obj2) {
                        double d1 = obj1.distance;
                        double d2 = obj2.distance;
                        if (d1 > d2) {
                            return NSOrderedDescending;
                        } else if (d1 < d2) {
                            return NSOrderedAscending;
                        } else {
                            return NSOrderedSame;
                        }
                    }];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    @synchronized(self.resultsArr) {
                        [self.resultsArr addObjectsFromArray:arr];
                        [self.resultsArr sortUsingComparator:^NSComparisonResult(FoursquareItem* obj1, FoursquareItem* obj2) {
                            double d1 = obj1.order;
                            double d2 = obj2.order;
                            if (d1 > d2) {
                                return NSOrderedDescending;
                            } else if (d1 < d2) {
                                return NSOrderedAscending;
                            } else {
                                return NSOrderedSame;
                            }
                        }];
                    }
                    if (self.delegate) {
                        [self.delegate autocompleteEntriesFound:self.resultsArr forString:self.srchString];
                    }
                });
            }
            
        }];
    } else {
        if (self.delegate) {
            [self.delegate autocompleteEntriesFound:@[] forString:self.srchString];
        }
    }
}

- (void)getKortforsyningenPlacesSearch{
    NSString* nameKey= @"navn";
    
    completeType= autocompleteKortforsyningen;
    
    if ([SMLocationManager instance].hasValidLocation) {
        NSString* URLString= [[NSString stringWithFormat:@"http://kortforsyningen.kms.dk/?servicename=%@&method=sted&stednavn=*%@*&geop=%lf,%lf&georef=EPSG:4326&outgeoref=EPSG:4326&login=%@&password=%@", KORT_SERVICE,
                               self.srchString, [SMLocationManager instance].lastValidLocation.coordinate.longitude, [SMLocationManager instance].lastValidLocation.coordinate.latitude, [SMRouteSettings sharedInstance].kort_username, [SMRouteSettings sharedInstance].kort_password] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        debugLog(@"Kort: %@", URLString);
        NSURLRequest * req = [NSURLRequest requestWithURL:[NSURL URLWithString:URLString]];
        [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse* response, NSData* data, NSError* error){
            
            NSError* jsonError;
            
            if ([data length] > 0 && error == nil){
                NSDictionary* json= [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                
                NSLog(@"Received data %@", json);
                if(!json){
                    NSLog(@"Response: %@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                }
                
                NSMutableCharacterSet * set = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
                [set addCharactersInString:@","];
                
                NSMutableArray* addressArray= [NSMutableArray new];
                for(NSDictionary* feature in json[@"features"]){
                    KortforItem *item = [[KortforItem alloc] initWithJsonDictionary:feature];
                    
                    NSInteger relevance = [SMRouteUtils pointsForName:[[NSString stringWithFormat:@"%@ , %@ %@", item.street,
                                                                        item.zip,
                                                                        item.city] stringByTrimmingCharactersInSet:set]
                                                           andAddress:[[NSString stringWithFormat:@"%@ , %@ %@", item.street,
                                                                        item.zip,
                                                                        item.city] stringByTrimmingCharactersInSet:set]
                                                             andTerms:self.srchString];
                    item.relevance = relevance;
                    
                    [addressArray addObject:item];
                }
                
                [addressArray sortUsingComparator:^NSComparisonResult(KortforItem* obj1, KortforItem* obj2){
                    long first = obj1.distance;
                    long second = obj2.distance;
                    
                    if(first<second)
                        return NSOrderedAscending;
                    else if(first>second)
                        return NSOrderedDescending;
                    else
                        return NSOrderedSame;
                }];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    @synchronized(self.resultsArr) {
                        [self.resultsArr addObjectsFromArray:addressArray];
                        [self.resultsArr sortUsingComparator:^NSComparisonResult(FoursquareItem* obj1, FoursquareItem* obj2) {
                            double d1 = obj1.order;
                            double d2 = obj2.order;
                            if (d1 > d2) {
                                return NSOrderedDescending;
                            } else if (d1 < d2) {
                                return NSOrderedAscending;
                            } else {
                                return NSOrderedSame;
                            }
                        }];
                    }
                    if (self.delegate) {
                        [self.delegate autocompleteEntriesFound:self.resultsArr forString:self.srchString];
                    }
                });
                
            }else if ([data length] == 0 && error == nil)
                NSLog(@"Empty reply");
            else if (error != nil && error.code == NSURLErrorTimedOut)
                NSLog(@"Timed out");
            else if (error != nil){
                NSLog(@"Error %@",jsonError.localizedDescription);
            }
            
        } ];
    }else{
        
    }
}

- (void)getKortforsyningenAutocomplete{
    completeType= autocompleteKortforsyningen;

    if ([SMLocationManager instance].hasValidLocation) {
        NSString* URLString= [[NSString stringWithFormat:@"http://kortforsyningen.kms.dk/?servicename=%@&method=vej&vejnavn=*%@*&geop=%lf,%lf&georef=EPSG:4326&outgeoref=EPSG:4326&login=%@&password=%@", KORT_SERVICE,
                               self.srchString, [SMLocationManager instance].lastValidLocation.coordinate.longitude, [SMLocationManager instance].lastValidLocation.coordinate.latitude, [SMRouteSettings sharedInstance].kort_username, [SMRouteSettings sharedInstance].kort_password] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

        UnknownSearchListItem *item = [SMAddressParser parseAddress:self.srchString];
        NSLog(@"Address: %@", item);
        BOOL additionalData = NO;
        if (item.number.length || item.city.length || item.zip.length) {
            additionalData = YES;
            NSString * s = @"";
            NSMutableArray * arr = [NSMutableArray array];
            if (item.street.length) {
                [arr addObject:[NSString stringWithFormat:@"vejnavn=*%@*", item.street]];
            }
            if (item.number.length) {
                [arr addObject:[NSString stringWithFormat:@"husnr=%@", item.number]];
            }
            if (item.city.length) {
                [arr addObject:[NSString stringWithFormat:@"postdist=%@", item.city]];
            }
            if (item.zip.length) {
                [arr addObject:[NSString stringWithFormat:@"postnr=%@", item.zip]];
            }
            
            s = [arr componentsJoinedByString:@"&"];
            
            URLString= [[NSString stringWithFormat:@"http://kortforsyningen.kms.dk/?servicename=%@&method=adresse&%@&geop=%lf,%lf&georef=EPSG:4326&outgeoref=EPSG:4326&login=%@&password=%@", KORT_SERVICE,
                                   s, [SMLocationManager instance].lastValidLocation.coordinate.longitude, [SMLocationManager instance].lastValidLocation.coordinate.latitude, [SMRouteSettings sharedInstance].kort_username, [SMRouteSettings sharedInstance].kort_password] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        }
        
        debugLog(@"Kort: %@", URLString);
        NSURLRequest * req = [NSURLRequest requestWithURL:[NSURL URLWithString:URLString]];
        [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse* response, NSData* data, NSError* error){

            NSError* jsonError;
                
            if ([data length] > 0 && error == nil){

                NSDictionary* json= [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];

                NSLog(@"Received data %@", json);
                if(!json){
                    NSLog(@"Response: %@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                }
                
                NSMutableCharacterSet * set = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
                [set addCharactersInString:@","];
                
                NSMutableArray* addressArray= [NSMutableArray new];
                for(NSDictionary* feature in json[@"features"]){
                    KortforItem *item = [[KortforItem alloc] initWithJsonDictionary:feature];
                    
                    NSInteger relevance = [SMRouteUtils pointsForName:[[NSString stringWithFormat:@"%@ , %@ %@", item.street,
                                                                        item.zip,
                                                                        item.city] stringByTrimmingCharactersInSet:set]
                                                           andAddress:[[NSString stringWithFormat:@"%@ , %@ %@", item.street,
                                                                        item.zip,
                                                                        item.city] stringByTrimmingCharactersInSet:set]
                                                             andTerms:self.srchString];
                    item.relevance = relevance;
                    
                    NSString *formattedAddress = [[NSString stringWithFormat:@"%@ %@, %@ %@", item.street, item.number, item.zip, item.city] stringByTrimmingCharactersInSet:set];
                    item.name = formattedAddress;
                    item.address = formattedAddress;
                    
                    [addressArray addObject:item];
                }
                
                [addressArray sortUsingComparator:^NSComparisonResult(KortforItem *obj1, KortforItem *obj2){
                    long first = obj1.distance;
                    long second = obj2.distance;
                    
                    if(first<second)
                        return NSOrderedAscending;
                    else if(first>second)
                        return NSOrderedDescending;
                    else
                        return NSOrderedSame;
                }];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    @synchronized(self.resultsArr) {
                        [self.resultsArr addObjectsFromArray:addressArray];
                        [self.resultsArr sortUsingComparator:^NSComparisonResult(KortforItem *obj1, KortforItem *obj2) {
                            double d1 = obj1.order;
                            double d2 = obj2.order;
                            if (d1 > d2) {
                                return NSOrderedDescending;
                            } else if (d1 < d2) {
                                return NSOrderedAscending;
                            } else {
                                return NSOrderedSame;
                            }
                        }];
                    }
                    if (self.delegate) {
                        [self.delegate autocompleteEntriesFound:self.resultsArr forString:self.srchString];
                    }
                });

            }else if ([data length] == 0 && error == nil)
                NSLog(@"Empty reply");
            else if (error != nil && error.code == NSURLErrorTimedOut)
                NSLog(@"Timed out");
            else if (error != nil){
                NSLog(@"Error %@",jsonError.localizedDescription);
            }

        } ];
    }else{
        
    }
}


@end

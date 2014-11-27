//
//  SMFoursquareOperation.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 17/11/2013.
//  Copyright (C) 2013 City of Copenhagen.  All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
//  If a copy of the MPL was not distributed with this file, You can obtain one at
//  http://mozilla.org/MPL/2.0/.
//

#import "SMFoursquareOperation.h"
#import "SMLocationManager.h"

@implementation SMFoursquareOperation

- (void)startOperation {
    self.searchString = self.startItem.street;
    
    NSString * near = nil;
    if (self.startItem.zip.length != 0) {
        if (self.startItem.city.length != 0) {
            near = [NSString stringWithFormat:@"%@ %@", self.startItem.zip, self.startItem.city];
        } else {
            near = [NSString stringWithFormat:@"%@, Denmark", self.startItem.zip];
        }
    } else {
        if (self.startItem.city.length != 0) {
            near = self.startItem.city;
        }
    }
    
    NSString * URLString = nil;
    if (near) {
        URLString = [NSString stringWithFormat:@"https://api.foursquare.com/v2/venues/search?intent=browse&near=%@&client_id=%@&client_secret=%@&query=%@&v=%@&radius=%@&limit=%@&categoryId=%@", [[near removeAccents] urlEncode], FOURSQUARE_ID, FOURSQUARE_SECRET, [[self.searchString removeAccents] urlEncode], @"20130301", FOURSQUARE_SEARCH_RADIUS, [SMRouteSettings sharedInstance].foursquare_limit, [SMRouteSettings sharedInstance].foursquare_categories];
    } else {
        URLString = [NSString stringWithFormat:@"https://api.foursquare.com/v2/venues/search?intent=browse&ll=%f,%f&client_id=%@&client_secret=%@&query=%@&v=%@&radius=%@&limit=%@&categoryId=%@", [SMLocationManager instance].lastValidLocation.coordinate.latitude, [SMLocationManager instance].lastValidLocation.coordinate.longitude, FOURSQUARE_ID, FOURSQUARE_SECRET, [[self.searchString removeAccents] urlEncode], @"20130301", FOURSQUARE_SEARCH_RADIUS, [SMRouteSettings sharedInstance].foursquare_limit, [SMRouteSettings sharedInstance].foursquare_categories];
    }

    
    debugLog(@"*** URL: %@", URLString);
    
    NSMutableURLRequest * req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:URLString]];
    
    self.conn = [[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:NO];
    [self.conn scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [self.conn start];
    self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:URL_CONNECTION_TIMEOUT target:self selector:@selector(timeoutCancel:) userInfo:nil repeats:NO];
    
}

- (void)processResult:(id)result {
    NSDictionary * res = (NSDictionary*)result;
    NSMutableArray * arr = [NSMutableArray array];
    
    for (NSDictionary* d in res[@"response"][@"venues"]) {
        FoursquareItem *item = [[FoursquareItem alloc] initWithJsonDictionary:d];
        item.relevance = [SMRouteUtils pointsForName:item.name andAddress:item.address andTerms:self.searchString];
        if (item.location.coordinate.latitude != 0 &&
            item.location.coordinate.longitude != 0) {
            item.distance = [[SMLocationManager instance].lastValidLocation distanceFromLocation:item.location];
            [arr addObject:item];
        }
        
        if (item.location.coordinate.latitude != 0 && item.location.coordinate.longitude != 0) {
            NSMutableDictionary * dict = [NSMutableDictionary new];
            
            // TODO: Handle icon
            if (d[@"categories"] && [d[@"categories"] count] > 0) {
                NSDictionary * d2 = d[@"categories"][0];
                if (d2[@"icon"]) {
                    NSString * s1 = [NSString stringWithFormat:@"%@%@", [d2[@"icon"][@"prefix"] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"_"]], d2[@"icon"][@"suffix"]];
                    dict[@"icon"] = s1;
                }
            }
        }
    }
    
    [arr sortUsingComparator:^NSComparisonResult(FoursquareItem *obj1, FoursquareItem *obj2) {
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
    
    self.results = arr;
}


@end

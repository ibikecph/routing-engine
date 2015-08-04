//
//  SMNerbyPlaces.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 06/02/2013.
//  Copyright (C) 2013 City of Copenhagen.  All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
//  If a copy of the MPL was not distributed with this file, You can obtain one at 
//  http://mozilla.org/MPL/2.0/.
//

#import "SMNearbyPlaces.h"

@interface SMNearbyPlaces()
@property (nonatomic, strong) NSURLConnection * conn;
@property (nonatomic, strong) NSMutableData * responseData;
@end

@implementation SMNearbyPlaces

- (id)initWithDelegate:(id<SMNearbyPlacesDelegate>)dlg {
    self = [super init];
    if (self) {
        [self setDelegate:dlg];
        self.title = @"";
        self.subtitle = @"";
        self.coord = nil;
    }
    return self;
}

- (void)findPlacesForLocation:(CLLocation*) loc {
    self.coord = loc;
    NSString* s = [NSString stringWithFormat:@"https://geo.oiorest.dk/adresser/%f,%f,%@.json", loc.coordinate.latitude, loc.coordinate.longitude, OIOREST_SEARCH_RADIUS];
    NSURLRequest * req = [NSURLRequest requestWithURL:[NSURL URLWithString:s]];
    if (self.conn) {
        [self.conn cancel];
        self.conn = nil;
    }
    NSURLConnection * c = [[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:NO];
    self.conn = c;
    self.responseData = [NSMutableData data];
    [self.conn start];
}

#pragma mark - url connection delegate

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if ([self.responseData length] > 0) {
//        NSString * str = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
        id res = [NSJSONSerialization JSONObjectWithData:self.responseData options:NSJSONReadingAllowFragments error:nil];//[[[SBJsonParser alloc] init] objectWithData:self.responseData];
        
        if (res == nil) {
            return;
        }
        
        if ([res isKindOfClass:[NSArray class]] == NO) {
            res = @[res];
        }
        
        NSMutableArray * arr = [NSMutableArray array];
        
        if ([(NSArray*)res count] > 0) {
            OiorestItem *item = [[OiorestItem alloc] initWithJsonDictionary:res[0]];
            self.title = [NSString stringWithFormat:@"%@ %@", item.street, item.number];
            self.subtitle = [NSString stringWithFormat:@"%@ %@", item.zip, item.city];
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
        
        if ([self.delegate conformsToProtocol:@protocol(SMNearbyPlacesDelegate)]) {
            [self.delegate nearbyPlaces:self foundLocations:arr];
        }
    }
}

@end

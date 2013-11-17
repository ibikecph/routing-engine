//
//  SMFoursquareOperation.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 17/11/2013.
//  Copyright (C) 2013 City of Copenhagen.
//
//  This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
//  If a copy of the MPL was not distributed with this file, You can obtain one at
//  http://mozilla.org/MPL/2.0/.
//

#import "SMFoursquareOperation.h"
#import "SMLocationManager.h"

@implementation SMFoursquareOperation

- (void)startOperation {
    self.searchString = [self.startParams objectForKey:@"text"];
    
    NSString * URLString = [NSString stringWithFormat:@"https://api.foursquare.com/v2/venues/suggestcompletion?ll=%f,%f&client_id=%@&client_secret=%@&query=%@&v=%@&radius=%@", [SMLocationManager instance].lastValidLocation.coordinate.latitude, [SMLocationManager instance].lastValidLocation.coordinate.longitude, FOURSQUARE_ID, FOURSQUARE_SECRET, [[self.searchString removeAccents] urlEncode], @"20130301", FOURSQUARE_SEARCH_RADIUS];
    
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
    
    for (NSDictionary* d in [[res objectForKey:@"response"] objectForKey:@"minivenues"]) {
        if ([[d objectForKey:@"location"] objectForKey:@"lat"] && [[d objectForKey:@"location"] objectForKey:@"lng"]
            && (([[[d objectForKey:@"location"] objectForKey:@"lat"] doubleValue] != 0) || ([[[d objectForKey:@"location"] objectForKey:@"lng"] doubleValue] != 0))) {
            NSMutableArray * ar = [NSMutableArray array];
            NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                         @"name" : [d objectForKey:@"name"],
                                                                                         @"zip" : @"",
                                                                                         @"lat" : [[d objectForKey:@"location"] objectForKey:@"lat"],
                                                                                         @"long" : [[d objectForKey:@"location"] objectForKey:@"lng"],
                                                                                         @"source" : @"autocomplete",
                                                                                         @"subsource" : @"foursquare",
                                                                                         @"order" : @3
                                                                                         }];
            if ([d objectForKey:@"name"]) {
                [dict setValue:[d objectForKey:@"name"] forKey:@"name"];
            } else {
                [dict setValue:@"" forKey:@"name"];
            }
            
            if ([[d objectForKey:@"location"] objectForKey:@"address"]) {
                [dict setValue:[[d objectForKey:@"location"] objectForKey:@"address"] forKey:@"street"];
                if ([[[[d objectForKey:@"location"] objectForKey:@"address"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""] == NO) {
                    [ar addObject:[[[d objectForKey:@"location"] objectForKey:@"address"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
                }
            } else {
                [dict setValue:@"" forKey:@"street"];
            }
            if ([[d objectForKey:@"location"] objectForKey:@"city"]) {
                [dict setValue:[[d objectForKey:@"location"] objectForKey:@"city"] forKey:@"city"];
                if ([[[[d objectForKey:@"location"] objectForKey:@"city"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""] == NO) {
                    [ar addObject:[[[d objectForKey:@"location"] objectForKey:@"city"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
                }
            } else {
                [dict setValue:@"" forKey:@"city"];
            }
            if ([[d objectForKey:@"location"] objectForKey:@"country"]) {
                [dict setValue:[[d objectForKey:@"location"] objectForKey:@"country"] forKey:@"country"];
                if ([[[[d objectForKey:@"location"] objectForKey:@"country"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""] == NO) {
                    [ar addObject:[[[d objectForKey:@"location"] objectForKey:@"country"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
                }
            } else {
                [dict setValue:@"" forKey:@"country"];
            }
            
            if ([d objectForKey:@"categories"] && [[d objectForKey:@"categories"] count] > 0) {
                NSDictionary * d2 = [[d objectForKey:@"categories"] objectAtIndex:0];
                if ([d2 objectForKey:@"icon"]) {
                    NSString * s1 = [NSString stringWithFormat:@"%@%@", [[[d2 objectForKey:@"icon"] objectForKey:@"prefix"] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"_"]], [[d2 objectForKey:@"icon"] objectForKey:@"suffix"]];
                    [dict setObject:s1 forKey:@"icon"];
                }
                
            }
            
            
            [dict setObject:[ar componentsJoinedByString:@", "] forKey:@"address"];
            
            [dict setObject:[NSNumber numberWithInteger:[SMRouteUtils pointsForName:[dict objectForKey:@"name"] andAddress:[dict objectForKey:@"address"] andTerms:self.searchString]] forKey:@"relevance"];
            
            if ([[dict objectForKey:@"address"] rangeOfString:@"København"].location != NSNotFound
                || [[dict objectForKey:@"address"] rangeOfString:@"Koebenhavn"].location != NSNotFound
                || [[dict objectForKey:@"address"] rangeOfString:@"Kobenhavn"].location != NSNotFound
                || [[dict objectForKey:@"address"] rangeOfString:@"Copenhagen"].location != NSNotFound
                || [[dict objectForKey:@"address"] rangeOfString:@"Frederiksberg"].location != NSNotFound
                || [[dict objectForKey:@"address"] rangeOfString:@"Valby"].location != NSNotFound
                ) {
                [arr addObject:dict];
            }
            
            
            [arr sortUsingComparator:^NSComparisonResult(NSDictionary * obj1, NSDictionary * obj2) {
                double d1 = [[SMLocationManager instance].lastValidLocation distanceFromLocation:[[CLLocation alloc] initWithLatitude:[[obj1 objectForKey:@"lat"] doubleValue] longitude:[[obj1 objectForKey:@"lat"] doubleValue]]];
                double d2 = [[SMLocationManager instance].lastValidLocation distanceFromLocation:[[CLLocation alloc] initWithLatitude:[[obj2 objectForKey:@"lat"] doubleValue] longitude:[[obj2 objectForKey:@"lat"] doubleValue]]];
                if (d1 > d2) {
                    return NSOrderedDescending;
                } else if (d1 < d2) {
                    return NSOrderedAscending;
                } else {
                    return NSOrderedSame;
                }
            }];
        }
    }
    
    self.results = arr;
}


@end

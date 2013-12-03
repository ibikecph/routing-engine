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
    self.searchString = [self.startParams objectForKey:@"street"];
    
    NSString * near = nil;
    if ([self.startParams objectForKey:@"zip"]) {
        if ([self.startParams objectForKey:@"city"]) {
            near = [NSString stringWithFormat:@"%@ %@", [self.startParams objectForKey:@"zip"], [self.startParams objectForKey:@"city"]];
        } else {
            near = [NSString stringWithFormat:@"%@, Denmark", [self.startParams objectForKey:@"zip"]];
        }
    } else {
        if ([self.startParams objectForKey:@"city"]) {
            near = [self.startParams objectForKey:@"city"];
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
    
    for (NSDictionary* d in [[res objectForKey:@"response"] objectForKey:@"venues"]) {
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
                NSDictionary * de = [SMAddressParser parseAddress:[[d objectForKey:@"location"] objectForKey:@"address"]];
                if ([de objectForKey:@"street"]) {
                    [dict setValue:[de objectForKey:@"street"] forKey:@"street"];
                    if ([[[de objectForKey:@"street"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""] == NO) {
                        [ar addObject:[[de objectForKey:@"street"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
                    }
                }
                if ([de objectForKey:@"number"]) {
                    [dict setValue:[de objectForKey:@"number"] forKey:@"number"];
                    if ([[[de objectForKey:@"number"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""] == NO) {
                        [ar addObject:[[de objectForKey:@"number"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
                    }
                } else {
                    [dict setValue:@"" forKey:@"number"];
                }
            } else {
                [dict setValue:@"" forKey:@"street"];
            }
            
            if ([[d objectForKey:@"location"] objectForKey:@"postalCode"]) {
                [dict setValue:[[d objectForKey:@"location"] objectForKey:@"postalCode"] forKey:@"zip"];
                if ([[[[d objectForKey:@"location"] objectForKey:@"postalCode"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""] == NO) {
                    [ar addObject:[[[d objectForKey:@"location"] objectForKey:@"postalCode"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
                }
            } else {
                [dict setValue:@"" forKey:@"zip"];
            }

            if ([[d objectForKey:@"location"] objectForKey:@"city"]) {
                [dict setValue:[[d objectForKey:@"location"] objectForKey:@"city"] forKey:@"city"];
                if ([[[[d objectForKey:@"location"] objectForKey:@"city"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""] == NO) {
                    [ar addObject:[[[d objectForKey:@"location"] objectForKey:@"city"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
                }
            } else {
                [dict setValue:@"" forKey:@"city"];
            }
//            if ([[d objectForKey:@"location"] objectForKey:@"country"]) {
//                [dict setValue:[[d objectForKey:@"location"] objectForKey:@"country"] forKey:@"country"];
//                if ([[[[d objectForKey:@"location"] objectForKey:@"country"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""] == NO) {
//                    [ar addObject:[[[d objectForKey:@"location"] objectForKey:@"country"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
//                }
//            } else {
//                [dict setValue:@"" forKey:@"country"];
//            }
            
            if ([d objectForKey:@"categories"] && [[d objectForKey:@"categories"] count] > 0) {
                NSDictionary * d2 = [[d objectForKey:@"categories"] objectAtIndex:0];
                if ([d2 objectForKey:@"icon"]) {
                    NSString * s1 = [NSString stringWithFormat:@"%@%@", [[[d2 objectForKey:@"icon"] objectForKey:@"prefix"] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"_"]], [[d2 objectForKey:@"icon"] objectForKey:@"suffix"]];
                    [dict setObject:s1 forKey:@"icon"];
                }
                
            }

            NSString * x = @"";
            NSMutableArray * ax = [NSMutableArray array];
            if ([[d objectForKey:@"location"] objectForKey:@"address"]) {
                NSMutableCharacterSet * set = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
                [set addCharactersInString:@","];
                NSString * streetStr = [[[d objectForKey:@"location"] objectForKey:@"address"] stringByTrimmingCharactersInSet:set];
                if ([streetStr isEqualToString:@""] == NO) {
                    NSArray * arr = [streetStr componentsSeparatedByString:@","];
                    if (arr.count > 0) {
                        streetStr = [[arr objectAtIndex:0] stringByTrimmingCharactersInSet:set];
                        x = [x stringByAppendingString:streetStr];
                        [ax addObject:x];
                    }
                }
            }
            
            if ([[dict objectForKey:@"zip"] isEqualToString:@""] == NO) {
                if ([[dict objectForKey:@"city"] isEqualToString:@""] == NO) {
                    [ax addObject:[NSString stringWithFormat:@"%@ %@", [dict objectForKey:@"zip"], [dict objectForKey:@"city"]]];
                } else {
                    [ax addObject:[dict objectForKey:@"zip"]];
                }
            } else {
                if ([[dict objectForKey:@"city"] isEqualToString:@""] == NO) {
                    [ax addObject:[dict objectForKey:@"city"]];
                }
            }
            x = [ax componentsJoinedByString:@", "];
            [dict setObject:[x stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:@"address"];
            
            
//            if ([[d objectForKey:@"location"] objectForKey:@"address"]) {
//                [dict setObject:[[d objectForKey:@"location"] objectForKey:@"address"] forKey:@"address"];
//            } else {
//                NSString * x = @"";
//                if ([dict objectForKey:@"street"]) {
//                    x = [x stringByAppendingString:[dict objectForKey:@"street"]];
//                }
//                if ([dict objectForKey:@"number"]) {
//                    x = [x stringByAppendingString:[NSString stringWithFormat:@" %@", [dict objectForKey:@"number"]]];
//                }
//                if ([[dict objectForKey:@"zip"] isEqualToString:@""] == NO) {
//                    if ([[dict objectForKey:@"city"] isEqualToString:@""] == NO) {
//                        x = [x stringByAppendingString:[NSString stringWithFormat:@", %@ %@", [dict objectForKey:@"zip"], [dict objectForKey:@"city"]]];
//                    } else {
//                        x = [x stringByAppendingString:[NSString stringWithFormat:@", %@", [dict objectForKey:@"zip"]]];
//                    }
//                } else {
//                    if ([[dict objectForKey:@"city"] isEqualToString:@""] == NO) {
//                        x = [x stringByAppendingString:[NSString stringWithFormat:@", %@", [dict objectForKey:@"city"]]];
//                    }
//                }
//                [dict setObject:x forKey:@"address"];
//            }
            
            [dict setObject:[NSNumber numberWithInteger:[SMRouteUtils pointsForName:[dict objectForKey:@"name"] andAddress:[dict objectForKey:@"address"] andTerms:self.searchString]] forKey:@"relevance"];
            
            [dict setObject:[dict objectForKey:@"name"] forKey:@"line1"];
            if ([dict objectForKey:@"address"] && [[dict objectForKey:@"address"] isEqualToString:@""] == NO) {
                [dict setObject:[dict objectForKey:@"address"] forKey:@"line2"];                
            }

            
            [dict setObject:[NSNumber numberWithDouble:[[SMLocationManager instance].lastValidLocation distanceFromLocation:[[CLLocation alloc] initWithLatitude:[[dict objectForKey:@"lat"] doubleValue] longitude:[[dict objectForKey:@"long"] doubleValue]]]] forKey:@"distance"];
            
//            if ([[dict objectForKey:@"address"] rangeOfString:@"København"].location != NSNotFound
//                || [[dict objectForKey:@"address"] rangeOfString:@"Koebenhavn"].location != NSNotFound
//                || [[dict objectForKey:@"address"] rangeOfString:@"Kobenhavn"].location != NSNotFound
//                || [[dict objectForKey:@"address"] rangeOfString:@"Copenhagen"].location != NSNotFound
//                || [[dict objectForKey:@"address"] rangeOfString:@"Frederiksberg"].location != NSNotFound
//                || [[dict objectForKey:@"address"] rangeOfString:@"Valby"].location != NSNotFound
//                ) {
                [arr addObject:dict];
//            }
        
            
            
        }
        
    }
    
    [arr sortUsingComparator:^NSComparisonResult(NSDictionary * obj1, NSDictionary * obj2) {
        double d1 = [[SMLocationManager instance].lastValidLocation distanceFromLocation:[[CLLocation alloc] initWithLatitude:[[obj1 objectForKey:@"lat"] doubleValue] longitude:[[obj1 objectForKey:@"long"] doubleValue]]];
        double d2 = [[SMLocationManager instance].lastValidLocation distanceFromLocation:[[CLLocation alloc] initWithLatitude:[[obj2 objectForKey:@"lat"] doubleValue] longitude:[[obj2 objectForKey:@"long"] doubleValue]]];
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

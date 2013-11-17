//
//  SMKMSPlacesOperation.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 17/11/2013.
//  Copyright (C) 2013 City of Copenhagen.
//
//  This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
//  If a copy of the MPL was not distributed with this file, You can obtain one at
//  http://mozilla.org/MPL/2.0/.
//

#import "SMKMSPlacesOperation.h"
#import "SMLocationManager.h"

@implementation SMKMSPlacesOperation

- (void)startOperation {
    self.searchString = [self.startParams objectForKey:@"street"];
    
    NSString* URLString= [[NSString stringWithFormat:@"http://kortforsyningen.kms.dk/?servicename=%@&method=sted&stednavn=*%@*&geop=%lf,%lf&georef=EPSG:4326&outgeoref=EPSG:4326&login=%@&password=%@&hits=%@", KORT_SERVICE,
                           self.searchString, [SMLocationManager instance].lastValidLocation.coordinate.longitude, [SMLocationManager instance].lastValidLocation.coordinate.latitude, [SMRouteSettings sharedInstance].kort_username, [SMRouteSettings sharedInstance].kort_password, [SMRouteSettings sharedInstance].kort_max_results] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    
    debugLog(@"*** URL: %@", URLString);
    
    NSMutableURLRequest * req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:URLString]];
    
    self.conn = [[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:NO];
    [self.conn scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [self.conn start];
    self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:URL_CONNECTION_TIMEOUT target:self selector:@selector(timeoutCancel:) userInfo:nil repeats:NO];
    
}

- (void)processResult:(id)result {
    NSString* nameKey= @"navn";
    
    NSDictionary* json= (NSDictionary*)result;
    
    NSMutableArray* addressArray= [NSMutableArray new];
    for (NSString* key in json.allKeys) {
        if ([key isEqualToString:@"features"]) {
            NSArray* features= [json objectForKey:key]; // array of features (dictionaries)
            for(NSDictionary* feature in features){
                NSMutableDictionary * val = [NSMutableDictionary dictionaryWithDictionary: @{@"source" : @"autocomplete",
                                                                                             @"subsource" : @"oiorest",
                                                                                             @"order" : @2
                                                                                             }];
                
                
                NSDictionary* attributes=[feature objectForKey:@"properties"];
                NSArray* geometryInfo= [feature objectForKey:@"bbox"];
                
                NSString* streetName= [attributes objectForKey:nameKey];
                if(!streetName) {
                    continue;
                }
                
                [val setObject:streetName forKey:@"name"];
                [val setObject:streetName forKey:@"address"];
                [val setObject:streetName forKey:@"street"];
                
                double distance = 0;
                if ([[SMLocationManager instance] hasValidLocation]) {
                    CLLocation * c = [[CLLocation alloc] initWithLatitude:[[geometryInfo objectAtIndex:1] doubleValue] longitude:[[geometryInfo objectAtIndex:0] doubleValue]];
                    distance = [[SMLocationManager instance].lastValidLocation distanceFromLocation:c];
                    
                }
                
                [val setObject:[NSNumber numberWithDouble:[[geometryInfo objectAtIndex:1] doubleValue]] forKey:@"lat"];
                [val setObject:[NSNumber numberWithDouble:[[geometryInfo objectAtIndex:0] doubleValue]] forKey:@"long"];
                
                [val setObject:[NSNumber numberWithDouble:[[attributes objectForKey:@"afstand_afstand"] doubleValue]] forKey:@"distance"];
                [val setObject:[NSNumber numberWithInteger:[SMRouteUtils pointsForName:streetName andAddress:streetName andTerms:self.searchString]] forKey:@"relevance"];
                
                [addressArray addObject:val];
            }
            
        }
    }
    
    [addressArray sortUsingComparator:^NSComparisonResult(NSDictionary* obj1, NSDictionary* obj2){
        long first= ((NSNumber*)[obj1 objectForKey:@"distance"]).longValue;
        long second= ((NSNumber*)[obj2 objectForKey:@"distance"]).longValue;
        
        if(first<second)
            return NSOrderedAscending;
        else if(first>second)
            return NSOrderedDescending;
        else
            return NSOrderedSame;
    }];
    
    self.results = addressArray;
    
}


@end

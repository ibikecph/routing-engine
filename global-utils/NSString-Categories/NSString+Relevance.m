//
//  NSString+Relevance.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 19/03/2013.
//  Copyright (C) 2013 City of Copenhagen.
//
//  This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
//  If a copy of the MPL was not distributed with this file, You can obtain one at 
//  http://mozilla.org/MPL/2.0/.
//

#import "NSString+Relevance.h"

@implementation NSString (Relevance)

- (NSInteger)numberOfOccurenciesOfString:(NSString*)str {
    NSInteger total = 0;
    
    NSRange rng = [self rangeOfString:str options:NSCaseInsensitiveSearch];
    
    while (rng.location != NSNotFound && rng.location < self.length) {
        total += 1;
        if ((rng.location + rng.length + 1) >= self.length) {
            return total;
        }
        rng = [self rangeOfString:str options:NSCaseInsensitiveSearch range:NSMakeRange(rng.location + rng.length + 1, self.length - rng.location - rng.length - 1)];
    }
    return total;
}

@end

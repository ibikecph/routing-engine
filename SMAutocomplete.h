//
//  SMAutocomplete.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 30/01/2013.
//  Copyright (C) 2013 City of Copenhagen.
//
//  This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
//  If a copy of the MPL was not distributed with this file, You can obtain one at 
//  http://mozilla.org/MPL/2.0/.
//

#import <Foundation/Foundation.h>

@protocol SMAutocompleteDelegate <NSObject>
- (void)autocompleteEntriesFound:(NSArray*)arr forString:(NSString*) str;
@end

@interface SMAutocomplete : NSObject

- (id)initWithDelegate:(id<SMAutocompleteDelegate>)dlg;

- (void)getAutocomplete:(NSString*)str;
- (void)getOiorestAutocomplete;
- (void)getFoursquareAutocomplete;
- (void)getKortforsyningenAutocomplete;
@end

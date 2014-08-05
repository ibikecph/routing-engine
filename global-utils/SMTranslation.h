//
//  SMTranslation.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 31/01/2013.
//  Copyright (C) 2013 City of Copenhagen.  All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
//  If a copy of the MPL was not distributed with this file, You can obtain one at 
//  http://mozilla.org/MPL/2.0/.
//

#import <Foundation/Foundation.h>

@interface SMTranslation : NSObject

+ (SMTranslation *)instance;
+(NSString*)decodeString:(NSString*) txt;

+ (void) translateView:(id) view;

@end

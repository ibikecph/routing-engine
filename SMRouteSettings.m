//
//  SMRouteSettings.m
//  testRouteMe
//
//  Created by Rasko Gojkovic on 6/12/13.
//  Copyright (C) 2013 City of Copenhagen.
//
//  This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
//  If a copy of the MPL was not distributed with this file, You can obtain one at 
//  http://mozilla.org/MPL/2.0/.
//

#import "SMRouteSettings.h"

static NSLock * _sharingLock;

@implementation SMRouteSettings

- (void)loadFromDefaultPlist{
    [self loadSettingsFromBundlePlist:DEFAULT_ROUTESETTINGS_FILENAME];
    [self loadSettingsFromBundlePlist:[DEFAULT_ROUTESETTINGS_FILENAME stringByAppendingString:DEFAULT_PRIVATE_SUFFIX]];
    [self loadSettingsFromBundlePlist:[DEFAULT_ROUTESETTINGS_FILENAME stringByAppendingString:DEFAULT_PRIVATE_APP_SUFFIX]];
}

- (BOOL)loadSettingsFromBundlePlist:(NSString*)fileName{
    NSString * filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"plist"];
    if(!filePath) return NO;
    
    NSDictionary * dict = [NSDictionary dictionaryWithContentsOfFile:filePath];
    
    NSString * lwKey;
    for(NSString * keyStr in dict.allKeys){
        lwKey = [keyStr lowercaseString];
        //check if getter exist (that should be sufficient for this class)
        if([self respondsToSelector:NSSelectorFromString(lwKey)]){
            [self setValue:[dict valueForKey:keyStr] forKey:lwKey];
        }
    }
    
    return YES;
}

+ (void)initialize{
    _sharingLock = [NSLock new];
}

+ (SMRouteSettings*)sharedInstance{
    static SMRouteSettings * _shared_instance = nil;
    
    [_sharingLock lock];
    if(!_shared_instance){
        _shared_instance = [SMRouteSettings new];
        [_shared_instance loadFromDefaultPlist];
    }
    [_sharingLock unlock];
    
    return _shared_instance;
}
@end

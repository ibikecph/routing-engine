//
//  SMTranslation.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 31/01/2013.
//  Copyright (C) 2013 City of Copenhagen.  All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
//  If a copy of the MPL was not distributed with this file, You can obtain one at 
//  http://mozilla.org/MPL/2.0/.
//

#import "SMTranslation.h"

@interface UIView(SMViewForTranslation)
-(void) viewTranslated;
@end

@implementation UIView(SMViewForTranslation)
-(void) viewTranslated{}
@end

@interface SMTranslation()
@end

@implementation SMTranslation

#pragma mark - localization / string decoding

+(NSString*)decodeString:(NSString*) txt {
    if (txt.length == 0) {
        return txt;
    }
    NSString *localized = NSLocalizedString(txt, NULL);
    if ([localized isEqualToString:txt]) {
        localized = NSLocalizedStringFromTable(txt, @"Localizable_IBC", NULL);
    }
    if ([localized isEqualToString:txt]) {
        localized = NSLocalizedStringFromTable(txt, @"Localizable_CP", NULL);
    }
    return localized;
}

+ (void) translateView:(id) view {
    if ([view isKindOfClass:[UILabel class]]) {
        NSString * response = [self decodeString:((UILabel*)view).text];
        [(UILabel*)view setText:response];
    } else if ([view isKindOfClass:[UITextView class]]) {
        NSString * response = [self decodeString:((UITextView*)view).text];
        [(UITextView*)view setText:response];
    } else if ([view isKindOfClass:[UISearchBar class]]) {
        NSString * response = [self decodeString:((UISearchBar*)view).placeholder];
        [(UISearchBar*)view setPlaceholder:response];
    } else if ([view isKindOfClass:[UITextField class]]) {
        NSString * response = [self decodeString:((UITextField*)view).placeholder];
        [(UITextField*)view setPlaceholder:response];
        response = [self decodeString:((UITextField*)view).text];
        [(UITextField*)view setText:response];
    } else if ([view isKindOfClass:[UIButton class]]) {
        NSString * response = [self decodeString:((UIButton*)view).titleLabel.text];
        [((UIButton*)view) setTitle:response forState:UIControlStateNormal];
        [((UIButton*)view) setTitle:response forState:UIControlStateHighlighted];
    } else if ([view isKindOfClass:[UISegmentedControl class]]) {
        UISegmentedControl * c = (UISegmentedControl*)view;
        for (int i = 0; i < c.numberOfSegments; i++) {
            [c setTitle:[self decodeString:[c titleForSegmentAtIndex:i]] forSegmentAtIndex:i];
        }
    } else if ([view isKindOfClass:[UIBarButtonItem class]]) {
        UIBarButtonItem * c = (UIBarButtonItem *)view;
        c.title = [self decodeString:c.title];
    }
    
    if([view respondsToSelector:@selector(viewTranslated)]){
        [view viewTranslated];
    }
    
    if ([view respondsToSelector:@selector(subviews)]) {
        for (UIView *v in ((UIView*)view).subviews) {
            [SMTranslation translateView:v];
        }
    }
}


@end

//
//  ModelTypes.h
//  I Bike CPH
//
//  Created by Tobias Due Munk on 23/11/14.
//  Copyright (c) 2014 I Bike CPH. All rights reserved.
//

#ifndef I_Bike_CPH_ModelTypes_h
#define I_Bike_CPH_ModelTypes_h

@import Foundation;

typedef NS_ENUM(NSInteger, SearchListItemType) {
    SearchListItemTypeCurrentLocation,
    SearchListItemTypeFavorite,
    SearchListItemTypeHistory,
    SearchListItemTypeKortfor,
    SearchListItemTypeFoursquare,
    SearchListItemTypeOiorest,
    SearchListItemTypeCalendar,
    SearchListItemTypeContact,
    SearchListItemTypeUnknown,
};

typedef NS_ENUM(NSInteger, FavoriteItemType) {
    FavoriteItemTypeHome,
    FavoriteItemTypeWork,
    FavoriteItemTypeSchool,
    FavoriteItemTypeUnknown
};

#endif

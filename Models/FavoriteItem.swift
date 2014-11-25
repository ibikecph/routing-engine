//
//  FavoriteItem.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 20/11/14.
//  Copyright (c) 2014 I Bike CPH. All rights reserved.
//

import UIKit
import CoreLocation

@objc class FavoriteItem: NSObject, SearchListItem {
    
    var type: SearchListItemType = .Favorite
    var name: String
    var address: String
    var street: String
    var order: Int = 0
    var zip: String
    var city: String
    var country: String
    var location: CLLocation = CLLocation()
    var relevance: Int = 0
    
    var startDate: NSDate?
    var endDate: NSDate?
    var origin: FavoriteItemType
    
    init(name: String, address: String? = nil, street: String, zip: String, city: String = "", country: String = "", location: CLLocation, startDate: NSDate? = nil, endDate: NSDate? = nil, origin: FavoriteItemType) {
        self.name = name
        self.address = address ?? name
        self.street = street
        self.zip = zip
        self.city = city
        self.country = country
        self.location = location
        self.startDate = startDate
        self.endDate = endDate
        self.origin = origin
    }
}

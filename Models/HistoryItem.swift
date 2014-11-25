//
//  HistoryItem.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 20/11/14.
//  Copyright (c) 2014 I Bike CPH. All rights reserved.
//

import UIKit
import CoreLocation

// https://github.com/ibikecph/ibikecph-lib-android/blob/master/IBikeCPHLib/src/com/spoiledmilk/ibikecph/search/HistoryData.java
@objc class HistoryItem: NSObject, SearchListItem {
   
    var type: SearchListItemType = .History
    var name: String
    var address: String
    var street: String
    var order: Int = 1
    var zip: String
    var city: String
    var country: String
    var location: CLLocation = CLLocation()
    var relevance: Int = 0
    
    var startDate: NSDate?
    var endDate: NSDate?
    
    init(name: String, address: String? = nil, street: String, zip: String, city: String = "", country: String = "", location: CLLocation, startDate: NSDate? = nil, endDate: NSDate? = nil) {
        self.name = name
        self.address = address ?? name
        self.street = street
        self.zip = zip
        self.city = city
        self.country = country
        self.location = location
        self.startDate = startDate
        self.endDate = endDate
    }
    
    init(other: SearchListItem, startDate: NSDate? = nil, endDate: NSDate? = nil) {
        self.name = other.name
        self.address = other.address
        self.street = other.street
        self.zip = other.zip
        self.city = other.city
        self.country = other.country
        self.location = other.location
        self.startDate = startDate
        self.endDate = endDate
    }
}

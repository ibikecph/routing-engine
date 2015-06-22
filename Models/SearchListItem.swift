//
//  SearchListItem.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 20/11/14.
//  Copyright (c) 2014 I Bike CPH. All rights reserved.
//

import Foundation
import CoreLocation

// https://github.com/ibikecph/ibikecph-lib-android/blob/master/IBikeCPHLib/src/com/spoiledmilk/ibikecph/search/SearchListItem.java

@objc protocol SearchListItem {
    
    var type: SearchListItemType { get }
    
    var name: String { get set }
    var address: String { get set }
    var street: String { get set }
    var number: String { get set }
    var order: Int { get set }
    var zip: String { get set }
    var city: String { get set }
    var country: String { get set }
    var location: CLLocation? { get set } // long, lat
    // getIconResourceId
    var relevance: Int { get set }
}

@objc class UnknownSearchListItem: NSObject, SearchListItem {
    
    var type: SearchListItemType = .Unknown
    var name: String = ""
    var address: String = ""
    var street: String = ""
    var number: String = ""
    var order: Int = 0
    var zip: String = ""
    var city: String = ""
    var country: String = ""
    var location: CLLocation? = CLLocation()
    var relevance: Int = 0
    
    init(name: String = "", address: String? = nil, street: String = "", number: String = "", zip: String = "", city: String = "", country: String = "", location: CLLocation) {
        self.name = name
        self.address = address ?? name
        self.street = street
        self.number = number
        self.zip = zip
        self.city = city
        self.country = country
        self.location = location
    }
    
    init(other: SearchListItem) {
        self.name = other.name
        self.address = other.address
        self.street = other.street
        self.number = other.number
        self.zip = other.zip
        self.city = other.city
        self.country = other.country
        self.location = other.location
    }
    
    override init() {
        super.init()
    }
    
    override var description: String {
        return "Name: \(name), Address: \(address), Street: \(street), Number: \(number), Zip: \(zip), City: \(city), Country: \(country), Location: (\(location?.coordinate.latitude), \(location?.coordinate.longitude)), Order: \(order), Relevance: \(relevance)"
    }
}




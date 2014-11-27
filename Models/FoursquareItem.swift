//
//  FoursquareItem.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 20/11/14.
//  Copyright (c) 2014 I Bike CPH. All rights reserved.
//

import Foundation
import CoreLocation


@objc class FoursquareItem: NSObject, SearchListItem {
    
    var type: SearchListItemType = .Foursquare
    var name: String
    var address: String
    var street: String
    var number: String = ""
    var order: Int = 2
    var zip: String
    var city: String
    var country: String
    var location: CLLocation = CLLocation()
    var relevance: Int = 0
    
    var distance: Double = 0
    
    init(jsonDictionary: AnyObject) {
        let json = JSON(jsonDictionary)
        
        name = json["name"].stringValue
        let jsonLocation = json["location"]
        address = jsonLocation["address"].stringValue
        street = address
        zip = jsonLocation["postalCode"].stringValue
        city = jsonLocation["city"].stringValue
        country = jsonLocation["country"].stringValue
        let latitude = jsonLocation["lat"].doubleValue
        let longitude = jsonLocation["lng"].doubleValue
        location = CLLocation(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
        
        let extraItem = SMAddressParser.parseAddress(address)
        
        number = extraItem.number
        if extraItem.street != "" {
            street = extraItem.street
        }
    }
    
    override var description: String {
        return "Name: \(name), Address: \(address), Street: \(street), Number: \(number), Zip: \(zip), City: \(city), Country: \(country), Location: (\(location.coordinate.latitude), \(location.coordinate.longitude)), Order: \(order), Relevance: \(relevance), Distance: \(distance)"
    }
}

//
//  OiorestItem.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 27/11/14.
//  Copyright (c) 2014 I Bike CPH. All rights reserved.
//

import UIKit

@objc class OiorestItem: NSObject, SearchListItem {
    
    var type: SearchListItemType = .Oiorest
    var name: String
    var address: String = ""
    var street: String
    var number: String
    var order: Int = 2
    var zip: String
    var city: String
    var country: String = "Denmark"
    var location: CLLocation? = CLLocation()
    var relevance: Int = 0
    
    init(jsonDictionary: AnyObject) {
        let json = JSON(jsonDictionary)
        
        // Street, name, address, city, zip
        street = json["vej_navn"]["navn"].stringValue
        number = json["husnr"].stringValue
        city = json["kommune"]["navn"].stringValue
        zip = json["postnummer"]["nr"].stringValue
        
        name = "\(street) \(number), \(zip) \(city)"
        address = name
        
        // Location
        let latitude = json["wgs84koordinat"]["bredde"].doubleValue
        let longitude = json["wgs84koordinat"]["længde"].doubleValue
        location = CLLocation(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
    }
    
    override var description: String {
        return "Name: \(name), Address: \(address), Street: \(street), Number: \(number), Zip: \(zip), City: \(city), Country: \(country), Location: (\(location?.coordinate.latitude), \(location?.coordinate.longitude)), Order: \(order), Relevance: \(relevance)"
    }
}
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
    var street: String = ""
    var number: String = ""
    var order: Int = 0
    var zip: String = ""
    var city: String = ""
    var country: String = ""
    var location: CLLocation = CLLocation()
    var relevance: Int = 0
    
    var startDate: NSDate?
    var endDate: NSDate?
    var origin: FavoriteItemType
    var identifier: String = ""
    
    init(name: String, address: String? = nil, street: String = "", number: String = "", zip: String = "", city: String = "", country: String = "", location: CLLocation, startDate: NSDate? = nil, endDate: NSDate? = nil, origin: FavoriteItemType) {
        self.name = name
        self.address = address ?? name
        self.street = street
        self.number = number
        self.zip = zip
        self.city = city
        self.country = country
        self.location = location
        self.startDate = startDate
        self.endDate = endDate
        self.origin = origin
    }
    
    init(name: String, address: String? = nil, location: CLLocation, startDate: NSDate? = nil, endDate: NSDate? = nil, origin: FavoriteItemType) {
        self.name = name
        self.address = address ?? name
        self.location = location
        self.startDate = startDate
        self.endDate = endDate
        self.origin = origin
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
        self.origin = .Unknown
    }
    
    init(jsonDictionary: AnyObject) {
        let json = JSON(jsonDictionary)
        
        number = ""
        name = json["name"].stringValue
        address = json["address"].stringValue
        startDate = NSDate()
        endDate = NSDate()
        
        // Location
        let latitude = json["lattitude"].doubleValue
        let longitude = json["longitude"].doubleValue
        location = CLLocation(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
        
        self.origin = .Unknown;
        
        self.identifier = json["id"].stringValue
    }
    
    init(plistDictionary: NSDictionary) {
        let json = JSON(plistDictionary)
        
        // Street, name, address, city, zip
        number = json["husnr"].stringValue
        city = json["kommune"]["navn"].stringValue
        zip = json["postnummer"]["nr"].stringValue
        
        name = json["name"].stringValue
        address = json["address"].stringValue
        startDate = NSKeyedUnarchiver.unarchiveObjectWithData(plistDictionary["startDate"] as NSData) as? NSDate
        endDate = NSKeyedUnarchiver.unarchiveObjectWithData(plistDictionary["endDate"] as NSData) as? NSDate
        
        // Location
        let latitude = json["lat"].doubleValue
        let longitude = json["long"].doubleValue
        location = CLLocation(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
        
        let origin = json["origin"].intValue
        self.origin = FavoriteItemType(rawValue: origin) ?? .Unknown;
        
        self.identifier = json["identifier"].stringValue
    }
    
    func plistRepresentation() -> [String : AnyObject] {
        return [
            "identifier" : self.identifier,
            "name" :  self.name,
            "address" : self.address,
            "startDate" : NSKeyedArchiver.archivedDataWithRootObject(self.startDate!),
            "endDate" : NSKeyedArchiver.archivedDataWithRootObject(self.endDate!),
            "origin" : self.origin.rawValue,
            "lat" : self.location.coordinate.latitude,
            "long" : self.location.coordinate.longitude
        ]
    }
    
    
    override var description: String {
        return "Name: \(name), Address: \(address), Street: \(street), Number: \(number), Zip: \(zip), City: \(city), Country: \(country), Location: (\(location.coordinate.latitude), \(location.coordinate.longitude)), Order: \(order), Relevance: \(relevance), Date: \(startDate) -> \(endDate), Origin: \(origin), Id: \(identifier)"
    }
}

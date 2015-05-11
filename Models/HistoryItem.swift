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
    var street: String = ""
    var number: String = ""
    var order: Int = 1
    var zip: String = ""
    var city: String = ""
    var country: String = ""
    var location: CLLocation? = CLLocation()
    var relevance: Int = 0
    
    var startDate: NSDate?
    var endDate: NSDate?
    
    init(name: String, address: String? = nil, location: CLLocation, startDate: NSDate? = nil, endDate: NSDate? = nil) {
        self.name = name
        self.address = address ?? name
        self.location = location
        self.startDate = startDate
        self.endDate = endDate
    }
    
    init(other: SearchListItem, startDate: NSDate? = nil, endDate: NSDate? = nil) {
        self.name = other.name
        self.address = other.address
        self.street = other.street
        self.number = other.number
        self.zip = other.zip
        self.city = other.city
        self.country = other.country
        self.location = other.location
        self.startDate = startDate
        self.endDate = endDate
    }
    
    init(plistDictionary: NSDictionary) {
        let json = JSON(plistDictionary)
        
        name = json["name"].stringValue
        address = json["address"].stringValue
        if let startDateData = plistDictionary["startDate"] as? NSData {
            startDate = NSKeyedUnarchiver.unarchiveObjectWithData(startDateData) as? NSDate
        }
        if let endDateData = plistDictionary["endDate"] as? NSData {
            endDate = NSKeyedUnarchiver.unarchiveObjectWithData(endDateData) as? NSDate
        }
        
        // Location
        let latitude = json["lat"].doubleValue
        let longitude = json["long"].doubleValue
        location = CLLocation(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
    }
    
    func plistRepresentation() -> [String : AnyObject] {
        return [
            "name" :  self.name,
            "address" : self.address,
            "startDate" : NSKeyedArchiver.archivedDataWithRootObject(self.startDate!),
            "endDate" : NSKeyedArchiver.archivedDataWithRootObject(self.endDate!),
            "lat" : self.location?.coordinate.latitude ?? 0,
            "long" : self.location?.coordinate.longitude ?? 0
        ]
    }
    
    override var description: String {
        return "Name: \(name), Address: \(address), Street: \(street), Number: \(number), Zip: \(zip), City: \(city), Country: \(country), Location: (\(location?.coordinate.latitude), \(location?.coordinate.longitude)), Order: \(order), Relevance: \(relevance), Date: \(startDate) -> \(endDate)"
    }
}

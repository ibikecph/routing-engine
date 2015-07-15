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
    var location: CLLocation? = CLLocation()
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
        self.relevance = other.relevance
        if let favorite = other as? FavoriteItem {
            self.startDate = favorite.startDate
            self.endDate = favorite.endDate
            self.origin = favorite.origin
            self.identifier = favorite.identifier
        }
    }
    
    init(jsonDictionary: AnyObject) {
        let json = JSON(jsonDictionary)
        
        // Name and address
        name = json["name"].stringValue
        address = json["address"].stringValue
        
        // Dates
        startDate = NSDate()
        endDate = NSDate()
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'ZZZ" // Format 2015-06-10T13:45:31ZUTC
        if let
            dateString = json["startDate"].string,
            date = formatter.dateFromString(dateString)
        {
            startDate = date
        }
        if let
            dateString = json["endDate"].string,
            date = formatter.dateFromString(dateString)
        {
            endDate = date
        }
        
        // Parse address string to make details
        let parsedAddressItem = SMAddressParser.parseAddress(address)
        number = parsedAddressItem.number
        city = parsedAddressItem.city
        zip = parsedAddressItem.zip
        street = parsedAddressItem.street
        
        // Location
        let latitude = json["lattitude"].doubleValue
        let longitude = json["longitude"].doubleValue
        location = CLLocation(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
        
        self.origin = {
            switch json["source"].stringValue {
                case "home": return .Home
                case "work": return .Work
                case "school": return .School
                case "favourites": fallthrough
                default: return .Unknown
            }
        }()
        
        self.identifier = json["id"].stringValue
    }
    
    init(plistDictionary: NSDictionary) {
        let json = JSON(plistDictionary)
        
        // Name and address
        name = json["name"].stringValue
        address = json["address"].stringValue
        
        // Street, name, address, city, zip. Fallback to full address string
        let parsedAddressItem = SMAddressParser.parseAddress(address)
        number = json["husnr"].string ?? parsedAddressItem.number
        city = json["by"].string ?? parsedAddressItem.city
        zip = json["postnummer"].string ?? parsedAddressItem.zip
        street = json["vej"].string ?? parsedAddressItem.street
        
        if let data = plistDictionary["startDate"] as? NSData {
            startDate = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? NSDate
        }
        if let data = plistDictionary["endDate"] as? NSData {
            endDate = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? NSDate
        }
        
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
            "identifier" : identifier,
            "name" :  name,
            "address" : address,
            "husnr" : number,
            "by" : city,
            "postnummer" : zip,
            "vej" : street,
            "startDate" : NSKeyedArchiver.archivedDataWithRootObject(startDate ?? NSDate()),
            "endDate" : NSKeyedArchiver.archivedDataWithRootObject(endDate ?? NSDate()),
            "origin" : origin.rawValue,
            "lat" : location?.coordinate.latitude ?? 0,
            "long" : location?.coordinate.longitude ?? 0
        ]
    }
    
    override var description: String {
        return "Name: \(name), Address: \(address), Street: \(street), Number: \(number), Zip: \(zip), City: \(city), Country: \(country), Location: (\(location?.coordinate.latitude), \(location?.coordinate.longitude)), Order: \(order), Relevance: \(relevance), Date: \(startDate) -> \(endDate), Origin: \(origin), Id: \(identifier)"
    }
}

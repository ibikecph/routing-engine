//
//  CurrentLocationItem.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 20/11/14.
//  Copyright (c) 2014 I Bike CPH. All rights reserved.
//

import UIKit
import CoreLocation

// https://github.com/ibikecph/ibikecph-lib-android/blob/master/IBikeCPHLib/src/com/spoiledmilk/ibikecph/search/CurrentLocation.java#L43
@objc class CurrentLocationItem: NSObject, SearchListItem {
    
    var type: SearchListItemType = .CurrentLocation
    var name: String = SMTranslation.decodeString("current_position")
    var address: String = "" // TODO: Check if it should can be calculated somehow https://github.com/ibikecph/ibikecph-lib-android/blob/master/IBikeCPHLib/src/com/spoiledmilk/ibikecph/search/CurrentLocation.java#L43
    var street: String = ""
    var number: String = ""
    var order: Int = -1
    var zip: String = ""
    var city: String = ""
    var country: String = ""
    var location: CLLocation? {
        get {
            return SMLocationManager.instance().lastValidLocation
        }
        set {
            println("Can't set location on CurrentLocationItem")
        }
    }
    var relevance: Int = 0
    
    override init() {
        super.init()
    }
}

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
    var order: Int { get set }
    var zip: String { get set }
    var city: String { get set }
    var country: String { get set }
    var location: CLLocation { get } // long, lat
    // getIconResourceId
    var relevance: Int { get set }
}

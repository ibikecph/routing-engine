//
//  UserData.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 20/11/14.
//  Copyright (c) 2014 I Bike CPH. All rights reserved.
//

import UIKit

// https://github.com/ibikecph/ibikecph-lib-android/blob/master/IBikeCPHLib/src/com/spoiledmilk/ibikecph/login/UserData.java
@objc class User: NSObject {
    
    let name: String
    let email: String
//    let password: String TODO: Decide whether passwords this belongs in model
//    let passwordConfirmed: String
    let authToken: String
    let id: Int
    let base64Image: String
    let imageName: String
    
    init(name: String, email: String, authToken: String, id: Int, base64Image: String, imageName: String) {
        self.name = name
        self.email = email
        self.authToken = authToken
        self.id = id
        self.base64Image = base64Image
        self.imageName = imageName
    }
}

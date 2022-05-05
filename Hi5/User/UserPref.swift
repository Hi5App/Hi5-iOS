//
//  UserPref.swift
//  Hi5
//
//  Created by 李凯翔 on 2022/5/4.
//

import Foundation

struct UserPreferences:Codable{
    var username:String
    var password:String
    var autoLogin:Bool
    var ImageShapening:Bool
}

//
//  UserPref.swift
//  Hi5
//
//  Created by 李凯翔 on 2022/5/4.
//

import Foundation

struct UserPreferences:Codable{
    let username:String
    let password:String
    let autoLogin:Bool
    let ImageShapening:Bool
}

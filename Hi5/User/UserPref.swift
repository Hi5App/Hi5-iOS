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
    
    var genderPicture:Bool
    var dailySomaGoal:Int = 0
    var dailyCheckGoal:Int = 0
    var totalSoma:Int = 0
    var totalCheck:Int = 0
    
    var dailySoma:Int = 0
    var dailyCheck:Int = 0
    
    var achievements:AchievementRecord
}

//
//  AchievementChecker.swift
//  Hi5
//
//  Created by 李凯翔 on 2022/6/16.
//

import Foundation

struct AchievementRecord:Codable{
    var dailySomaReached:Bool
    var dailyCheckReached:Bool
    
    var somaBronzeMedal:Bool
    var checkBronzeMedal:Bool
    
    var somaSliverMedal:Bool
    var checkSlivereMedal:Bool
    
    var somaGoldMedal:Bool
    var checkGoldMedal:Bool
    
    var dailyGoalTimeStamp:Date
    
    mutating func refreshDailyGoal(){
        let currentDate = Date()
        if Calendar.current.isDate(dailyGoalTimeStamp, inSameDayAs: currentDate){
            dailySomaReached = false
            dailyCheckReached = false
        }
    }
}

struct AchievementChecker{
    let bronzeMedal = 500
    let sliverMedal = 1000
    let goldMedal = 2000
    
    let dailySomaGoal:Int
    let dailyCheckGoal:Int
    
    var pastAchievement:AchievementRecord
  
    mutating func check(dailySoma:Int,dailyCheck:Int,totalSoma:Int,totalCheck:Int)->AchievementType?{
        // check daily goal
        if pastAchievement.dailySomaReached == false && dailySomaGoal != 0{
            if dailySoma >= dailySomaGoal{
                pastAchievement.dailySomaReached = true
                return .dailySomaGoal
            }
        }
        
        if pastAchievement.dailyCheckReached == false &&  dailyCheckGoal != 0{
            if dailyCheck >= dailyCheckGoal{
                pastAchievement.dailyCheckReached = true
                return .dailyCheckGoal
            }
        }
        // check total goal
        if totalSoma >= 2000 && pastAchievement.somaGoldMedal == false{
            pastAchievement.somaGoldMedal = true
            return .total2000Soma
        }else if totalCheck >= 2000 && pastAchievement.checkGoldMedal == false{
            pastAchievement.checkGoldMedal = true
            return .total2000Check
        }else if totalSoma >= 1000 && pastAchievement.somaSliverMedal == false{
            pastAchievement.somaSliverMedal = true
            return .total2000Soma
        }else if totalCheck >= 1000 && pastAchievement.checkSlivereMedal == false{
            pastAchievement.checkSlivereMedal = true
            return .total2000Check
        }else if totalSoma >= 500 && pastAchievement.somaBronzeMedal == false{
            pastAchievement.somaBronzeMedal = true
            return .total2000Soma
        }else if totalCheck >= 500 && pastAchievement.checkBronzeMedal == false{
            pastAchievement.checkBronzeMedal = true
            return .total2000Check
        }
        
        // no achievements
        print("no achievements")
        return nil
    }
}

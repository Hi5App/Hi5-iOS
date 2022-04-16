//
//  HTTPModel.swift
//  Hi5
//
//  Created by PengLab on 2022/4/16.
//

import Foundation

// MARK: - login Data Structure
struct UserInfo:Codable{
    let name:String
    let passwd:String
}

struct LoginUser:Codable{ //wrap user class for specific json format
    let user:UserInfo
}

struct RegisterUser:Codable {
    let email:String
    let name:String
    let passwd:String
    let nickname:String
}

struct LoginFeedback:Codable{
    let id:Int
    let name:String
    let email:String
    let nickname:String
    let score:Int
    let appkey:String
    let passwd:String
}

struct RegisterFeedback:Codable {
    let code:String
}

// MARK: - Image Data Structure
struct QueryCondition:Codable{
    let off:Int
    let limit:Int
}

struct QueryBrainList:Codable{
    let user:UserInfo
    let condition:QueryCondition
}

struct getBBSwcStruct:Codable{
    let name:String
    let passwd:String
    let swc:String
    let x:Int
    let y:Int
    let z:Int
    let len:Int
    let res:Int
}

struct parameter:Codable{
    let x:Int
    let y:Int
    let z:Int
}

struct boundingBox:Codable{
    let pa1:parameter
    let pa2:parameter
    let res:String
    let brainId:String
}

struct downloadImage:Codable{
    let bBox:boundingBox
    let user:UserInfo
}

struct BrainInfo:Codable{
    let name:String
    let detail:String
}

struct BrainListFeedBack:Codable{
    let barinList:[BrainInfo]
}

// MARK: - Image Data Structure
struct getPotentialLoactionStruct:Codable{
    let user:UserInfo
}

struct getSomaListStruct:Codable{
    let bBox:boundingBox
    let user:UserInfo
}

struct markerInfo:Codable{
    let x:Double
    let y:Double
    let z:Double // 保留三位小数
}

struct updateSomaInfo:Codable {
    let locationId:Int
    let locationType:Int
    let username:String
    let image:String
    let insertsomaList:[markerInfo]
    let deletesomalist:[String]
}

struct updateSomaListStruct:Codable{
    let pa:updateSomaInfo
    let user:UserInfo
}

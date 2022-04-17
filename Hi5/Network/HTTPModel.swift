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

struct QueryBrainListStruct:Codable{
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

struct Parameter:Codable{
    let x:Int
    let y:Int
    let z:Int
}

struct BoundingBox:Codable{
    let pa1:Parameter
    let pa2:Parameter
    let res:String
    let obj:String
}

struct DownloadImageStruct:Codable{
    let bb:BoundingBox
    let user:UserInfo
}

struct BrainInfo:Codable{
    let name:String
    let detail:String
}

struct BrainListFeedBack:Codable{
    let barinList:[BrainInfo]
}

// MARK: - Soma Data Structure
struct QueryPotentialLoactionStruct:Codable{
    let user:UserInfo
}

struct PotentialLocationFeedBack:Codable{
    let id:Int
    let image:String
    let loc:PositionInt
    let owner:String
}

struct QuerySomaListStruct:Codable{
    let bBox:BoundingBox
    let user:UserInfo
}

struct PositionInt:Codable{
    let x:Int
    let y:Int
    let z:Int 
}

struct UpdateSomaInfo:Codable {
    let locationId:Int
    let locationtype:Int
    let owner:String
    let image:String
    let insertsomalist:[PositionInt]
    let deletesomalist:[String]
}

struct UpdateSomaListStruct:Codable{
    let pa:UpdateSomaInfo
    let user:UserInfo
}

struct SomaInfo:Codable{
    let name:String
    let loc:PositionInt
}

struct SomaListFeedBack:Codable{
    let somaList:[SomaInfo]
}

struct UpdateSomaListFeedback:Codable{
    let code:String
}

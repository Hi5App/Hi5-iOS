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

struct performanceFeedback:Codable{
    let totalsoma:Int
    let dailysoma:Int
    let totalCheck:Int
    let dailyCheck:Int
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

struct ParameterFloat:Codable{
    let x:Float
    let y:Float
    let z:Float
}

struct BoundingBox:Codable{
    let pa1:Parameter
    let pa2:Parameter
    let res:String
    let obj:String
}

struct BoundingBoxFloat:Codable{
    let pa1:ParameterFloat
    let pa2:ParameterFloat
    let res:String
    let obj:String
}

struct DownloadImageStruct:Codable{
    let bb:BoundingBox
    let user:UserInfo
}

struct GetSwcStruct:Codable{
    let bb:BoundingBoxFloat
    let user:UserInfo
}

struct BrainInfo:Codable{
    let name:String
    let detail:String
}

struct BrainListFeedBack:Codable{
    let brainList:[BrainInfo]
}

// MARK: - Soma Data Structure
struct QueryPotentialLoactionStruct:Codable{
    let user:UserInfo
}

struct getArborStruct:Codable{
    let MaxId:Int
    let user:UserInfo
}

struct PotentialLocationFeedBack:Codable{
    let id:Int
    let image:String
    let loc:PositionInt
    let owner:String
}

struct QuerySomaListStruct:Codable{
    let bb:BoundingBox
    let user:UserInfo
}

struct PositionInt:Codable{
    let x:Int
    let y:Int
    let z:Int 
}

struct PositionFloat:Codable,Equatable{
    let x:Float
    let y:Float
    let z:Float
}

struct UpdateSomaInfo:Codable {
    let locationId:Int
    let locationtype:Int
    let owner:String
    let image:String
    let insertsomalist:[PositionFloat]
    let deletesomalist:[Int]
}

struct UpdateSomaListStruct:Codable{
    let pa:UpdateSomaInfo
    let user:UserInfo
}

struct SomaInfo:Codable{
    let id:Int
    let loc:PositionFloat
}

struct SomaListFeedBack:Codable{
    let somaList:[SomaInfo]
}

struct UpdateSomaListFeedback:Codable{
    let code:String
}

struct ArborInfo:Codable,Equatable{
    static func == (lhs: ArborInfo, rhs: ArborInfo) -> Bool {
        return (lhs.id == rhs.id &&
                lhs.name == rhs.name &&
                lhs.somaId == rhs.somaId &&
                lhs.image == rhs.image &&
                lhs.loc == rhs.loc &&
                lhs.status == rhs.status)
    }
    
    let id:Int
    let name:String
    let somaId:String
    let image:String
    let loc:PositionFloat
    let status:Int
}

struct QueryArborFeedBack:Codable{
    let arbors:[ArborInfo]
}

struct ArborResult:Codable {
    var arborid:Int = 0
    var result:Int = 0
    var form:Int = 0
    var owner:String = ""
}

struct ArborDetail:Codable {
    var id:Int = 0
    var arborId:Int = 0
    var loc:PositionFloat = PositionFloat(x: 0.0, y: 0.0, z: 0.0)
    var type:Int = 0
    var owner:String = ""
    
    init(arborId:Int,loc:PositionFloat,type:Int){
        self.arborId = arborId
        self.loc = loc
        self.type = type
    }
    
    init(arborId:Int){
        self.arborId = arborId
    }
}

struct UpdateArborResultParam:Codable {
    let insertlist:[ArborResult]
}

struct UpdateArborResultStruct:Codable {
    let user:UserInfo
    let pa:UpdateArborResultParam
}

struct QueryArborResultStruct:Codable {
    let user:UserInfo
    let arborId:Int
}

struct QueryArborFormerResult:Codable{
    let ArborId:Int
    let Result:Int
    let Form:Int
    let Owner:String
}

struct QueryArborFormerResults{
    let formerResults:[QueryArborFormerResult]
}

struct QueryMarkerListStruct:Codable {
    let user:UserInfo
    let pa:ArborDetail
}

struct QueryMarkerListFeedBack:Codable {
    let markerList:[ArborDetail]
}

struct InsertMarkerListStruct:Codable {
    let user:UserInfo
    let pa:[ArborDetail]
}

struct DeleteMarkerListStruct:Codable {
    let user:UserInfo
    let pa:[Int]
}

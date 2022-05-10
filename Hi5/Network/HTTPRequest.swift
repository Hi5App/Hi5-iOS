//
//  Request.swift
//  Hi5
//
//  Created by 李凯翔 on 2022/4/13.
//

import Foundation

struct HTTPRequest{
    // Basic function
    static func uploadTask(url:String, uploadData:Data, completionHandler:@escaping (Data?,Error?, Int)->Void){
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.uploadTask(with: request, from: uploadData) { data, response, error in
            if let error = error {
                print ("error: \(error)")
                completionHandler(nil, error, -1)
            }
            if let responseHTTP = response as? HTTPURLResponse,
               responseHTTP.statusCode != 200 {
                print ("server error")
                completionHandler(data, nil, responseHTTP.statusCode)
                return
            }
            else if let data = data {
                print(String(decoding: data, as: UTF8.self))
                OperationQueue.main.addOperation {  //excute on the main thread,only main thread can update UI
                    completionHandler(data, nil, 200)
                }
            }
        }
        task.resume()
    }
    
    struct UserPart {
        static func login(name:String, passwd:String, completionHandler:@escaping(LoginFeedback?)->Void, errorHandler:@escaping(String)->Void) {
            let loginUser = LoginUser(user:UserInfo(name:name, passwd:passwd))
            let jsonData = Hi5API.generateJSON(loginUser)
            guard jsonData != nil else {return}
            
            uploadTask(url:Hi5API.loginURL, uploadData: jsonData!) {
                data, error, statusCode in
                if let data = data, statusCode == 200 {
                    let loginFeedBack = Hi5API.parseLoginJSON(jsonData: data)
                    completionHandler(loginFeedBack)
                }
                if error != nil || statusCode != 200{
                    OperationQueue.main.addOperation {
                        errorHandler("error in login")
                    }
                }
            }
        }
        
        static func register(email:String, name:String, passwd:String, nickname:String, completionHandler:@escaping()->Void, errorHandler:@escaping(String)->Void) {
            let registerUser = RegisterUser(email: email, name: name, passwd: passwd, nickname: nickname)
            let jsonData = Hi5API.generateJSON(registerUser)
            guard jsonData != nil else {return}
            
            uploadTask(url:Hi5API.registerURL, uploadData: jsonData!) {
                data, error, statusCode in
                if statusCode == 200 {
                    completionHandler()
                }
                if error != nil || statusCode != 200{
                    OperationQueue.main.addOperation {
                        errorHandler("error in register")
                    }
                }
            }
        }
    }
    
    struct ImagePart {
        static func getBrainList(name:String, passwd:String, completionHandler:@escaping(BrainListFeedBack?)->Void, errorHandler:@escaping(String)->Void) {
            let queryBrainListStruct = QueryBrainListStruct(
                user: UserInfo(name: name, passwd: passwd),
                condition: QueryCondition(off: 0, limit: 2000))
            let jsonData = Hi5API.generateJSON(queryBrainListStruct)
            guard jsonData != nil else {return}
            
            uploadTask(url:Hi5API.getBrainListURL, uploadData: jsonData!) {
                data, error, statusCode in
                if let data = data, statusCode == 200 {
                    let brainListFeedBack = Hi5API.parseBrainListJSON(jsonData: data)
                    completionHandler(brainListFeedBack)
                }
                if error != nil || statusCode != 200 {
                    errorHandler("error in get brain list")
                    print("error in get brain list")
                }
            }
        }
        
        static func downloadImage(centerX:Int, centerY:Int, centerZ:Int, size:Int, res:String, brainId:String, name:String, passwd:String, completionHandler:@escaping(URL?)->Void, errorHandler:@escaping(String)->Void) {
            let pa1 = Parameter(x: centerX - size / 2, y: centerY - size / 2, z: centerZ - size / 2)
            let pa2 = Parameter(x: centerX + size / 2, y: centerY + size / 2, z: centerZ + size / 2)
            let bBox = BoundingBox(pa1: pa1, pa2: pa2, res: res, obj: brainId)
            let user = UserInfo(name: name, passwd: passwd)
            let downloadImageStruct = DownloadImageStruct(bb: bBox, user: user)
            
            let jsonData = Hi5API.generateJSON(downloadImageStruct)
            guard jsonData != nil else {return}
            
            uploadTask(url: Hi5API.downloadImageURL, uploadData: jsonData!) {
                data, error, statusCode in
                if let data = data, statusCode == 200 {
                    let url = Hi5API.saveImage(jsonData: data, brainId: brainId, res: res, centerX: centerX, centerY: centerY, centerZ: centerZ)
                    completionHandler(url)
                } else {
                    errorHandler("error in download image")
                }
            }
        }
    }
    
    struct SomaPart {
        static func getPotentialLocation(name:String,  passwd:String, completionHandler:@escaping(PotentialLocationFeedBack?)->Void, errorHandler:@escaping(String)->Void) {
            let queryPotentialLocationStruct = QueryPotentialLoactionStruct(user: UserInfo(name: name, passwd: passwd))
            let jsonData = Hi5API.generateJSON(queryPotentialLocationStruct)
            guard jsonData != nil else {return}
            
            uploadTask(url: Hi5API.getPotentialLocationURL, uploadData: jsonData!) {
                data, error, statusCode in
                if let data = data, statusCode == 200 {
                    let potentialLocationFeedBack = Hi5API.parsePotentialLocationJSON(jsonData: data)
                    completionHandler(potentialLocationFeedBack)
                    return
                }
                if let data = data, statusCode == 502 {
                    let responseStr = String(data: data, encoding: String.Encoding.utf8)
                    if let responseStr = responseStr {
                        let trimedStr = responseStr.trimmingCharacters(in: .whitespacesAndNewlines)
                        errorHandler(trimedStr)
                    }
                    errorHandler("Fail to get potential location info")
                    return
                }
                if error != nil {
                    errorHandler("error in get potential location")
                    print("error in get potential location")
                }
            }
        }
        
        static func getSomaList(centerX:Int, centerY:Int, centerZ:Int, size:Int, res:String, brainId:String, name:String, passwd:String, completionHandler:@escaping(SomaListFeedBack?)->Void, errorHandler:@escaping(String)->Void) {
            let pa1 = Parameter(x: centerX - size / 2, y: centerY - size / 2, z: centerZ - size / 2)
            let pa2 = Parameter(x: centerX + size / 2, y: centerY + size / 2, z: centerZ + size / 2)
            let bBox = BoundingBox(pa1: pa1, pa2: pa2, res: res, obj: brainId)
            let user = UserInfo(name: name, passwd: passwd)
            let querySomaListStruct = QuerySomaListStruct(bb: bBox, user: user)
            
            let jsonData = Hi5API.generateJSON(querySomaListStruct)
            guard jsonData != nil else {return}
            
            uploadTask(url: Hi5API.getSomaListURL, uploadData: jsonData!) {
                data, error, statusCode in
                if let data = data, statusCode == 200 {
                    let somaListFeedBack = Hi5API.parseSomaListJSON(jsonData: data)
                    completionHandler(somaListFeedBack)
                }
                if error != nil && statusCode != 200{
                    print("error in get soma list")
                }
            }
        }
        
        static func updateSomaList(imageId:String, locationId:Int, locationType:Int, username:String, passwd:String, insertSomaList:[PositionFloat], deleteSomaList:[String], completionHandler:@escaping()->Void, errorHandler:@escaping(String)->Void) {
            let user = UserInfo(name: username, passwd: passwd)
            let updateSomaInfo = UpdateSomaInfo(locationId: locationId, locationtype: locationType, owner: username, image: imageId, insertsomalist: insertSomaList, deletesomalist: deleteSomaList)
            let updateSomaListStruct = UpdateSomaListStruct(pa: updateSomaInfo, user: user)
            
            let jsonData = Hi5API.generateJSON(updateSomaListStruct)
            guard jsonData != nil else {return}
            
            uploadTask(url: Hi5API.updateSomaListURL, uploadData: jsonData!) {
                data, error, statusCode in
                if statusCode == 200 {
                    completionHandler()
                }
                if error != nil && statusCode != 200{
                    errorHandler("error in update soma list")
                }
            }
        }
    }
    
    struct QualityInspectionPart {
        static func getArbor(name:String, passwd:String, completionHandler:@escaping(QueryArborFeedBack?)->Void, errorHandler:@escaping(String)->Void) {
            let queryPotentialLocationStruct = QueryPotentialLoactionStruct(user: UserInfo(name: name, passwd: passwd))
            let jsonData = Hi5API.generateJSON(queryPotentialLocationStruct)
            guard jsonData != nil else {return}
            
            uploadTask(url: Hi5API.getArborURL, uploadData: jsonData!) { data, error, statusCode in
                if let data = data, statusCode == 200 {
                    let queryArborFeedback = Hi5API.parseArborJSON(jsonData: data)
                    completionHandler(queryArborFeedback)
                }
                if error != nil && statusCode != 200 {
                    errorHandler("error in get arbor")
                }
            }
        }
        
        static func getSwc(centerX:Float, centerY:Float, centerZ:Float, size:Int, imageId:String, somaId:String, arborName:String, name:String, passwd:String, completionHandler:@escaping(URL?)->Void, errorHandler:@escaping(String)->Void) {
            let pa1 = ParameterFloat(x: centerX - Float(size / 2), y: centerY - Float(size / 2), z: centerZ - Float(size / 2))
            let pa2 = ParameterFloat(x: centerX + Float(size / 2), y: centerY + Float(size / 2), z: centerZ + Float(size / 2))
            let res = "/" + imageId + "/" + somaId
            let bBox = BoundingBoxFloat(pa1: pa1, pa2: pa2, res: res, obj: arborName)
            let userInfo = UserInfo(name: name, passwd: passwd)
            let getSwcStruct = GetSwcStruct(bb: bBox, user: userInfo)
            
            let jsonData = Hi5API.generateJSON(getSwcStruct)
            guard jsonData != nil else {return}
            
            uploadTask(url: Hi5API.getSwcURL, uploadData: jsonData!) { data, error, statusCode in
                if let data = data, statusCode == 200 {
                    let url = Hi5API.saveSwc(jsonData: data, arborName: arborName, res: res, centerX: Int(centerX), centerY: Int(centerY), centerZ: Int(centerZ))
                    completionHandler(url)
                }
                if error != nil && statusCode != 200 {
                    errorHandler("error in get swc")
                }
            }
        }
    }
}

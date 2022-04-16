//
//  Hi5API.swift
//  Hi5
//
//  Created by 李凯翔 on 2022/4/13.
//

import Foundation

let serverIP = "http://139.155.28.154:26000"

struct Hi5API{
    static let loginURL = serverIP + "/dynamic/user/login"
    static let registerURL = serverIP + "/dynamic/user/register"
    static let updatePassURL = serverIP + "/dynamic/user/updatepassword"
    static let findPasswordURL = serverIP + "/dynamic/user/findpassword"
    
    static let getBrainListURL = serverIP + "/dynamic/image/getimagelist"
    static let downloadImageURL = serverIP + "/dynamic/image/cropimage"
    static let getBBSwcURL = serverIP + "/dynamic/coll/getswcbb"
    
    static func parseLoginJSON(jsonData:Data)->LoginFeedback?{
        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(LoginFeedback.self, from: jsonData)
            return response
        }catch{
            print("decode login json error")
            return nil
        }
    }
    
    static func parseRegisterJSON(jsonData:Data)->RegisterFeedback?{
//        do {
            let response = RegisterFeedback(code: "200")
            return response
//        }catch{
//            print("decode register json error")
//            return nil
//        }
    }
    
    static func parseBrainListJSON(jsonData:Data)->BrainListFeedBack?{
        do {
            print(String(decoding: jsonData, as: UTF8.self))
            let result = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? [[String:String]]
            guard result != nil else {return nil}
            
            var brainList = [BrainInfo]()
            for item in result! {
                let data = try! JSONSerialization.data(withJSONObject: item, options: [])
                let brainItem = try! JSONDecoder().decode(BrainInfo.self, from: data)
                brainList.append(brainItem)
            }
            
            return BrainListFeedBack(barinList: brainList)
        }catch {
            print("decode brain list json error")
            return nil
        }
    }
    
    static func generateJSON<T>(_ value:T)->Data? where T : Encodable {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let result = try encoder.encode(value)
            return result
        } catch {
            print("JSON creation failed")
            return nil
        }
    }
}

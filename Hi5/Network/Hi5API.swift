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
    
    static let getPotentialLocationURL = serverIP + "/dynamic/soma/getpotentiallocation"
    static let getSomaListURL = serverIP + "/dynamic/soma/getsomalist"
    static let updateSomaListURL = serverIP + "/dynamic/soma/updatesomalist"
    
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
    
    static func parsePotentialLocationJSON(jsonData:Data)->PotentialLocationFeedBack?{
        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(PotentialLocationFeedBack.self, from: jsonData)
            return response
        }catch{
            print("decode potential location json error")
            return nil
        }
    }
    
    static func parseSomaListJSON(jsonData:Data)->SomaListFeedBack?{
        do {
            let result = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? [[String:String]]
            guard result != nil else {return nil}
            
            var somaList = [SomaInfo]()
            for item in result! {
                let data = try! JSONSerialization.data(withJSONObject: item, options: [])
                let somaItem = try! JSONDecoder().decode(SomaInfo.self, from: data)
                somaList.append(somaItem)
            }
            
            return SomaListFeedBack(somaList: somaList)
        } catch {
            print("decode soma list json error")
            return nil
        }
    }
    
    static func saveImage(jsonData:Data, brainId:String, res:String, centerX:Int, centerY:Int, centerZ:Int)->URL?{
        do {
            let fileName = brainId + "_" + res + "_" + "\(centerX)" + "_" + "\(centerY)" + "_" + "\(centerZ)" + ".v3dpbd"
            let url = FileManager.default.urls(for: .documentDirectory,
                                                    in: .userDomainMask)[0].appendingPathComponent(fileName)
            try jsonData.write(to: url)
            return url
        } catch {
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

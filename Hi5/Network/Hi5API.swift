//
//  Hi5API.swift
//  Hi5
//
//  Created by 李凯翔 on 2022/4/13.
//

import Foundation
import Metal

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
    
    static let getArborURL = serverIP + "/dynamic/arbor/getarbor"
    static let getSwcURL = serverIP + "/dynamic/swc/cropswc"
    static let queryArborResult = serverIP + "/dynamic/arbor/queryarborresult"
    static let updateArborResult = serverIP + "/dynamic/arbor/updatearborresult"
    static let queryMarkerListURL = serverIP + "/dynamic/arbordetail/query"
    static let insertMarkerListURL = serverIP + "/dynamic/arbordetail/insert"
    static let deleteMarkerListURL = serverIP + "/dynamic/arbordetail/delete"
    
    static let queryCheckAndSomaCounts = serverIP + "/dynamic/user/getuserperformance"
    
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
            
            return BrainListFeedBack(brainList: brainList)
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
            let result = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? [[String:Any]]
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
    
    static func parseArborJSON(jsonData:Data) -> QueryArborFeedBack? {
        do {
            let result = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? [[String:Any]]
            guard result != nil else {return nil}
            
            var arborList = [ArborInfo]()
            for item in result! {
                let data = try! JSONSerialization.data(withJSONObject: item, options: [])
                let brainItem = try! JSONDecoder().decode(ArborInfo.self, from: data)
                arborList.append(brainItem)
            }
            return QueryArborFeedBack(arbors: arborList)
        } catch {
            print("decode arbor json error")
            return nil
        }
    }
    
    static func parseMarkerList(jsonData:Data) -> QueryMarkerListFeedBack? {
        do {
            let result = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? [[String:Any]]
            guard result != nil else {return nil}
            
            var markerList = [ArborDetail]()
            for item in result! {
                let data = try! JSONSerialization.data(withJSONObject: item, options: [])
                let markerItem = try! JSONDecoder().decode(ArborDetail.self, from: data)
                markerList.append(markerItem)
            }
            return QueryMarkerListFeedBack(markerList: markerList)
        } catch {
            print("decode marker list error")
            return nil
        }
    }
    
    static func parseArborFormerResult(jsonData:Data) -> QueryArborFormerResults? {
        do {
            let formerFeedbacks:[QueryArborFormerResult] = try JSONDecoder().decode([QueryArborFormerResult].self,from: jsonData)
            let feedback = QueryArborFormerResults(formerResults: formerFeedbacks)
            return feedback
        } catch {
            print("decode arbor former results error")
            return nil
        }
    }
    
    static func parsePerformanceResult(jsonData:Data) -> performanceFeedback? {
        do {
            let feedback = try JSONDecoder().decode(performanceFeedback.self,from: jsonData)
            return feedback
        } catch {
            print("decode performance results error")
            return nil
        }
    }
    
    static func generateJSON<T>(_ value:T) -> Data? where T : Encodable {
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
    
    static func saveSwc(jsonData:Data, arborName:String, centerX:Int, centerY:Int, centerZ:Int) -> URL? {
        do {
            let fileName = arborName + "_" + "\(centerX)" + "_" + "\(centerY)" + "_" + "\(centerZ)" + ".swc"
            let url = FileManager.default.urls(for: .documentDirectory,
                                                    in: .userDomainMask)[0].appendingPathComponent(fileName)
            try jsonData.write(to: url)
            return url
        } catch {
            print(error)
            return nil
        }
    }
}

//
//  Hi5API.swift
//  Hi5
//
//  Created by 李凯翔 on 2022/4/13.
//

import Foundation

let serverIP = "http://139.155.28.154:26000"

enum Hi5Urls:String {
    case loginURL = "/dynamic/user/login"
    case registerURL = "/dynamic/user/register"
    case updatePasswordURL = "/dynamic/user/updatepassword"
    case findPasswordURL = "/dynamic/user/findpassword"
}

struct loginUser:Codable{
    var name:String
    var passwd:String
}

struct Hi5API{
    static let loginURL = serverIP + Hi5Urls.loginURL.rawValue
    static let registerURL = serverIP + Hi5Urls.registerURL.rawValue
    static let updatePassURL = serverIP + Hi5Urls.updatePasswordURL.rawValue
    static let findPasswordURL = serverIP + Hi5Urls.findPasswordURL.rawValue
    
    static func generateLoginJSON(loginUser:loginUser)->String?{
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let result = try encoder.encode(loginUser)
            if let jsonString = String(data: result, encoding: .utf8){
                return jsonString
            }else{
                return nil
            }
        } catch {
            print("loginJSON creation failed\n name is \(loginUser.name) and password is \(loginUser.passwd)")
            return nil
        }
    }
}
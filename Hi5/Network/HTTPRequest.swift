//
//  Request.swift
//  Hi5
//
//  Created by 李凯翔 on 2022/4/13.
//

import Foundation

struct HTTPRequest{
    // Basic function
    static func uploadTask(url:String, uploadData:Data, completionHandler:@escaping (Data?,Error?)->Void){
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.uploadTask(with: request, from: uploadData) { data, response, error in
            if let error = error {
                print ("error: \(error)")
                completionHandler(nil, error)
            }
            guard let response = response as? HTTPURLResponse,
                (200...299).contains(response.statusCode) else {
                print ("server error")
                return
            }
            if let data = data {
                print(data)
                OperationQueue.main.addOperation {  //excute on the main thread,only main thread can update UI
                    completionHandler(data, nil)
                }
            }
        }
        task.resume()
    }
    
    struct UserPart {
        static func login(name:String, passwd:String, completionHandler:@escaping(LoginFeedback?)->Void) {
            let loginUser = LoginUser(user:UserInfo(name:name, passwd:passwd))
            let jsonData = Hi5API.generateJSON(loginUser)
            guard jsonData != nil else {return}
            
            uploadTask(url:Hi5API.loginURL, uploadData: jsonData!) {
                data, error in
                if let data = data {
                    let loginFeedBack = Hi5API.parseLoginJSON(jsonData: data)
                    completionHandler(loginFeedBack)
                }
                if error != nil {
                    print("error in login")
                }
            }
        }
        
        static func register(email:String, name:String, passwd:String, nickname:String, completionHandler:@escaping(RegisterFeedback?)->Void) {
            let registerUser = RegisterUser(email: email, name: name, passwd: passwd, nickname: nickname)
            let jsonData = Hi5API.generateJSON(registerUser)
            guard jsonData != nil else {return}
            
            uploadTask(url:Hi5API.registerURL, uploadData: jsonData!) {
                data, error in
                if let data = data {
                    let registerFeedBack = Hi5API.parseRegisterJSON(jsonData: data)
                    completionHandler(registerFeedBack)
                }
                if error != nil {
                    print("error in register")
                }
            }
        }
    }
    
    struct ImagePart {
        static func getBrainList(name:String, passwd:String, completionHandler:@escaping(BrainListFeedBack?)->Void) {
            let queryBrainList = QueryBrainList(
                user: UserInfo(name: name, passwd: passwd),
                condition: QueryCondition(off: 0, limit: 2000))
            let jsonData = Hi5API.generateJSON(queryBrainList)
            guard jsonData != nil else {return}
            
            uploadTask(url:Hi5API.getBrainListURL, uploadData: jsonData!) {
                data, error in
                if let data = data {
                    let brainListFeedBack = Hi5API.parseBrainListJSON(jsonData: data)
                    completionHandler(brainListFeedBack)
                }
                if error != nil {
                    print("error in register")
                }
            }
        }
    }
}

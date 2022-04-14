//
//  Request.swift
//  Hi5
//
//  Created by 李凯翔 on 2022/4/13.
//

import Foundation

struct HTTPRequest{
    func authLogin(url:String,data:String){
        
        let parameters: [String: String] = ["name": "kx1126", "passwd": "123456"]
        
        let url = URL(string: url)
        guard url != nil else{ return }
        print(url!)
        let session = URLSession.shared
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) // pass dictionary to nsdata object and set it as request body
            print(try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted))
        } catch let error {
            print(error.localizedDescription)
        }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = session.dataTask(with: request) { data, response, error in
            guard error == nil else {return}
            
            if let response = response as? HTTPURLResponse
//               (200...299).contains(response.statusCode)
            {
                print(response.statusCode)
            } else {
                print ("server error")
                return
            }
            
            if let data = data{
                do {
                    if let str = String(data: data, encoding: .utf8){
                        print(str)
                    }
//                    if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
//                        print(json)
//                        // handle json...
//                    }
                }catch{
                    print("receive json failed")
                }
               
            }
        }
        task.resume()
    }
    
    func verifyLogin(url:String,uploadData:Data?){
        struct user:Codable{
            let name:String
            let passwd:String
        }
        
        let u = user(name: "kx1126", passwd: "123456")
        guard let uploadData = try? JSONEncoder().encode(u) else {return}
        print(String(data: uploadData, encoding: .utf8)!)
        print(url)
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.uploadTask(with: request, from: uploadData) { data, response, error in
            if let error = error {
                print ("error: \(error)")
                return
            }
            guard let response = response as? HTTPURLResponse,
                (200...299).contains(response.statusCode) else {
                print ("server error")
                return
            }
            if let mimeType = response.mimeType,
                mimeType == "application/json",
                let data = data,
                let dataString = String(data: data, encoding: .utf8) {
                print ("got data: \(dataString)")
            }
        }
        task.resume()
    }
}

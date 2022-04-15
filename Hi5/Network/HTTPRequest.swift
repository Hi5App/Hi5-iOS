//
//  Request.swift
//  Hi5
//
//  Created by 李凯翔 on 2022/4/13.
//

import Foundation

struct HTTPRequest{
    func verifyLogin(url:String,uploadData:Data,CompletionHandler:@escaping (Data?,Error?)->Void){
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.uploadTask(with: request, from: uploadData) { data, response, error in
            if let error = error {
                print ("error: \(error)")
                CompletionHandler(nil,error)
            }
            guard let response = response as? HTTPURLResponse,
                (200...299).contains(response.statusCode) else {
                print ("server error")
                return
            }
            if let data = data
            {
                OperationQueue.main.addOperation {  //excute on the main thread,only main thread can update UI
                    CompletionHandler(data,nil)
                }
            }
        }
        task.resume()
    }
}

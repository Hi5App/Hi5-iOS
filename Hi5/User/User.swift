//
//  User.swift
//  Hi5
//
//  Created by 李凯翔 on 2022/4/13.
//

import Foundation

class User:NSObject{
    let userName:String
    let nickName:String
    let email:String
    let password:String
    let inviterCode:String?
    let score:Int?
    
    init(userName:String,nickName:String,email:String,password:String,inviterCode:String,score:Int){
        self.userName = userName
        self.nickName = nickName
        self.email = email
        self.password = password
        if inviterCode == ""{
            self.inviterCode = "none"
        }else{
            self.inviterCode = inviterCode
        }
        self.score = score
    }
    
    static func guestUser()->User{
        return User(userName: "Guest", nickName: "Guest", email: "Guest@Guest.com", password: "Guest", inviterCode: "none", score: 0)
    }
    
}

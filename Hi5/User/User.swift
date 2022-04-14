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
    let inviterCode:String
    
    init(userName:String,nickName:String,email:String,password:String,inviterCode:String){
        self.userName = userName
        self.nickName = nickName
        self.email = email
        self.password = password
        self.inviterCode = inviterCode
    }
    
    class func GuestUser() -> User{
        return User(userName: "Guest", nickName: "Guest", email: "Guest@mode.com", password: "123456", inviterCode: "0")
    }
}

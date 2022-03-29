//
//  image4DSimple.swift
//  Hi5
//
//  Created by 李凯翔 on 2022/2/24.
//

import Foundation

class image4DSimple{
    let name:String
    let endianness:Character
    let dataType:UInt8
    let sizeX:Int //3D Edges
    let sizeY:Int
    let sizeZ:Int
    let channelNumber:Int
    let imageData:[[[UInt8]]]
    
    init(name:String,endiannessType e:Character,dataType dt:UInt8,_ sX:Int,_ sY:Int,_ sZ:Int,_ channel:Int,_ data:[[[UInt8]]]){
        self.name = name
        endianness = e
        dataType = dt
        sizeX = sX
        sizeY = sY
        sizeZ = sZ
        channelNumber = channel
        imageData = data
    }
}

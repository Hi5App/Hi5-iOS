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
    let imageArray:[UInt8]
    
    init(name:String,endiannessType e:Character,dataType dt:UInt8,_ sX:Int,_ sY:Int,_ sZ:Int,_ channel:Int,_ data:[[[UInt8]]],array:[UInt8]){
        self.name = name
        endianness = e
        dataType = dt
        sizeX = sX
        sizeY = sY
        sizeZ = sZ
        channelNumber = channel
        imageData = data
        imageArray = array
    }
    
    func sample3Ddata(x:Float,y:Float,z:Float)->Float{
        let positionIn3dArray = access3DfromCenter(x: x, y: y, z: z )
        let lowX = Int(positionIn3dArray.0)
        let lowY = Int(positionIn3dArray.1)
        let lowZ = Int(positionIn3dArray.2)
        let highX = lowX+1
        let highY = lowY+1
        let highZ = lowZ+1
        var Intensities = Array(repeating: Array(repeating: Array(repeating: 0, count: 2), count: 2), count: 2)
        // fill Intensities
        Intensities[0][0][0] = Int(imageData[lowX][lowY][lowZ])
        Intensities[1][0][0] = Int(imageData[highX][lowY][lowZ])
        Intensities[0][1][0] = Int(imageData[lowX][highY][lowZ])
        Intensities[0][0][1] = Int(imageData[highX][lowY][highZ])
        Intensities[1][1][0] = Int(imageData[highX][highY][lowZ])
        Intensities[0][1][1] = Int(imageData[lowX][highY][highZ])
        Intensities[1][0][1] = Int(imageData[highX][lowY][highZ])
        Intensities[1][1][1] = Int(imageData[highX][highY][highZ])
//        print(Intensities)
        
        // fraction
        let xf = positionIn3dArray.0 - Float(lowX)
        let yf = positionIn3dArray.1 - Float(lowY)
        let zf = positionIn3dArray.2 - Float(lowZ)
        var fractions = Array(repeating: Array(repeating: Array(repeating: Float(0), count: 2), count: 2), count: 2)
        fractions[0][0][0] = (1.0-xf)*(1.0-yf)*(1.0-zf)
        fractions[0][0][1] = (1.0-xf)*(1.0-yf)*(    zf)
        fractions[0][1][0] = (1.0-xf)*(    yf)*(1.0-zf)
        fractions[0][1][1] = (1.0-xf)*(    yf)*(    zf)
        fractions[1][0][0] = (    xf)*(1.0-yf)*(1.0-zf)
        fractions[1][0][1] = (    xf)*(1.0-yf)*(    zf)
        fractions[1][1][0] = (    xf)*(    yf)*(1.0-zf)
        fractions[1][1][1] = (    xf)*(    yf)*(    zf)
//        print(fractions)
        
        var results:Float = 0
        for i in 0..<2{
            for j in 0..<2{
                for k in 0..<2{
                    results += Float(Intensities[i][j][k]) * fractions[i][j][k]
                }
            }
        }
        
        return results
    }
    
    func access3DfromCenter(x:Float,y:Float,z:Float)->(Float,Float,Float){
        // input model space coordinates, output 3d array index
        // 62.5 = 127/2,center index of the array
        // rotate 90 degree and invert y axis
        let temp = x
        let x = z
        let y = -y
        let z = -temp
        // position in 3dArray
        let arrayX = x*62.5+62.5
        let arrayY = -y*62.5+62.5
        let arrayZ = -(z*62.5-62.5)
        return (arrayX,arrayY,arrayZ)
    }
}

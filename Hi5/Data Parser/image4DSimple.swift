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
    var imageData:[[[UInt8]]]
    let imageArray:[UInt8]
    
    var maxIntensity:UInt8
    var minIntensity:UInt8
    
    init(name:String,endiannessType e:Character,dataType dt:UInt8,_ sX:Int,_ sY:Int,_ sZ:Int,_ channel:Int,_ data:[[[UInt8]]],array:[UInt8],maxIntensity:UInt8,minIntensity:UInt8){
        self.name = name
        endianness = e
        dataType = dt
        sizeX = sX
        sizeY = sY
        sizeZ = sZ
        channelNumber = channel
        imageData = data
        imageArray = array
        self.maxIntensity = maxIntensity
        self.minIntensity = minIntensity
    }
    
    func make3DArrayFrom1DArray(){
        var start = 0
        var array3D = Array(repeating: Array(repeating: Array(repeating: UInt8(0), count: sizeZ), count: sizeY), count: sizeX)
        for i in 0...sizeX-1{
            for j in 0...sizeY-1{
                for k in 0...sizeZ-1{
                    let element = imageArray[start]
                    array3D[i][j][k] = imageArray[start]
                    maxIntensity = max(maxIntensity, element)
                    minIntensity = min(minIntensity, element)
                    start += 1
                }
            }
        }
        imageData = array3D
    }
    
    func sample3Ddata(x:Float,y:Float,z:Float)->Float{
        let lowX = Int(x)
        let lowY = Int(y)
        let lowZ = Int(z)
        let highX = min(lowX+1,127)
        let highY = min(lowY+1,127)
        let highZ = min(lowZ+1,127)
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
        let xf = x - Float(lowX)
        let yf = y - Float(lowY)
        let zf = z - Float(lowZ)
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
        //  model space coordinates -> 3d array index
        // rotate 90 degree and invert y axis
        let temp = x
        let x = z
        let y = -y
        let z = -temp
        // position in 3dArray
        let arrayX = x*Float(sizeX-1)/2+Float(sizeX-1)/2
        let arrayY = -y*Float(sizeY-1)/2+Float(sizeY-1)/2
        let arrayZ = -(z*Float(sizeZ-1)/2-Float(sizeZ-1)/2)
        return (arrayX,arrayY,arrayZ)
    }
    
    func from3DToDisplay(position:(Int,Int,Int))->(Float,Float,Float){
        var x = (Float(position.0) - Float(sizeX-1)/2)/(Float(sizeX-1)/2)
        print(Float(sizeX-1)/2)
        var y = -(Float(position.1) - Float(sizeY-1)/2)/(Float(sizeY-1)/2)
        var z = (-Float(position.2) + Float(sizeZ-1)/2)/(Float(sizeZ-1)/2)
        
        (x,z) = (-z,x)
        y = -y
        
        return (x,y,z)
    }
    
    
}

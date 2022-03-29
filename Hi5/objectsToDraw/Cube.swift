//
//  Cube.swift
//  metalLearning
//
//  Created by 李凯翔 on 2022/3/6.
//

import Foundation
import Metal
import QuartzCore

class Cube:Node{
    init(device: MTLDevice, commandQ: MTLCommandQueue,viewWidth:Int,viewHeight:Int,image4DSimple:image4DSimple){

        let A = Vertex(x: -1.0, y:   1.0, z:   1.0, r:  0.0, g:  1.0, b:  1.0, a:  1.0,s: 0.0,t: 0.3)
        let B = Vertex(x: -1.0, y:  -1.0, z:   1.0, r:  0.0, g:  0.0, b:  1.0, a:  1.0,s: 0.0,t: 0.7)
        let C = Vertex(x:  1.0, y:  -1.0, z:   1.0, r:  1.0, g:  0.0, b:  1.0, a:  1.0,s: 1.0,t: 0.7)
        let D = Vertex(x:  1.0, y:   1.0, z:   1.0, r:  1.0, g:  1.0, b:  1.0, a:  1.0,s: 1.0,t: 0.3)
        
        let Q = Vertex(x: -1.0, y:   1.0, z:  -1.0, r:  0.0, g:  1.0, b:  0.0, a:  1.0,s: 0.0,t: 0.0)
        let R = Vertex(x:  1.0, y:   1.0, z:  -1.0, r:  1.0, g:  1.0, b:  0.0, a:  1.0,s: 0.0,t: 0.0)
        let S = Vertex(x: -1.0, y:  -1.0, z:  -1.0, r:  0.0, g:  0.0, b:  0.0, a:  1.0,s: 0.0,t: 0.0)
        let T = Vertex(x:  1.0, y:  -1.0, z:  -1.0, r:  1.0, g:  0.0, b:  0.0, a:  1.0,s: 0.0,t: 0.0)
        
        let verticesArray:Array<Vertex> = [
            
            A,B,C ,A,C,D,   //Front
            R,T,S ,Q,R,S,   //Back
            
            Q,S,B ,Q,B,A,   //Left
            D,C,T ,D,T,R,   //Right
            
            Q,A,D ,Q,D,R,   //Top
            B,S,T ,B,T,C    //Bot
        ]
        
        //set up 3d texture
//        var image3dToArray = Array(repeating: UInt8(0), count:128*128*128 )
//        var position = 0
//        for i in 0...127{
//            for j in 0...127{
//                for k in 0...127{
//                    image3dToArray[position] = image4DSimple.imageData[i][j][k]
//                    position += 1
//                }
//            }
//        }
        
//        let values:UnsafeMutablePointer = UnsafeMutablePointer(mutating: image3dToArray)
        
        let texDescriptor = MTLTextureDescriptor()
        texDescriptor.textureType = .type3D
        texDescriptor.pixelFormat = .r8Uint // red 8 bit
        texDescriptor.width = image4DSimple.sizeX
        texDescriptor.height = image4DSimple.sizeY
        texDescriptor.depth = image4DSimple.sizeZ
        texDescriptor.usage = .shaderRead
        
        let texture = device.makeTexture(descriptor: texDescriptor)!
        
//        texture.replace(region: MTLRegionMake3D(0, 0, 0, image4DSimple.sizeX, image4DSimple.sizeY, image4DSimple.sizeZ),
//                         mipmapLevel: 0,
//                         slice: 0,
//                         withBytes: values,
//                         bytesPerRow: image4DSimple.sizeX * MemoryLayout<UInt8>.size,
//                         bytesPerImage: image4DSimple.sizeX * image4DSimple.sizeY * MemoryLayout<UInt8>.size)
        
        super.init(name: "Cube", vertices: verticesArray, device: device, texture: texture,viewWidth: viewWidth,viewHeight: viewHeight)
        }
    
   
}

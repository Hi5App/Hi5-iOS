//
//  Quad.swift
//  Hi5
//
//  Created by 李凯翔 on 2022/3/14.
//

import Foundation
import Metal
import QuartzCore

class Quad:Node{
    init(device: MTLDevice, commandQ: MTLCommandQueue,viewWidth:Int,viewHeight:Int,image4DSimple:image4DSimple){

        let A = Vertex(x: -1.0, y:  1.0, z:   1.0, r:  0.0, g:  1.0, b:  1.0, a:  1.0,s: 0.0,t: 0.0)
        let B = Vertex(x: -1.0, y:  -1.0, z:   1.0, r:  0.0, g:  0.0, b:  1.0, a:  1.0,s: 0.0,t: 1.0)
        let C = Vertex(x:  1.0, y:  -1.0, z:   1.0, r:  1.0, g:  0.0, b:  1.0, a:  1.0,s: 1.0,t: 1.0)
        let D = Vertex(x:  1.0, y:  1.0, z:   1.0, r:  1.0, g:  1.0, b:  1.0, a:  1.0,s: 1.0,t: 0.0)
        
        let verticesArray:Array<Vertex> = [
            A,B,C ,A,C,D,   //Front
        ]
        
        //set up 3d texture
        var image3dToArray = Array(repeating: UInt8(0), count:128*128*128 )
        var position = 0
        for i in 0...127{
            for j in 0...127{
                for k in 0...127{
                    image3dToArray[position] = image4DSimple.imageData[i][j][k]
//                    if k<10 && i==101 && j==0{
//                        print(image4DSimple.imageData[i][j][k])
//                    }
                    position += 1
                }
            }
        }
        
        let values:UnsafeMutablePointer = UnsafeMutablePointer(mutating: image3dToArray)
        
        let texDescriptor = MTLTextureDescriptor()
        texDescriptor.textureType = .type3D
        texDescriptor.pixelFormat = .r8Uint // red 8 bit
        texDescriptor.width = image4DSimple.sizeX
        texDescriptor.height = image4DSimple.sizeY
        texDescriptor.depth = image4DSimple.sizeZ
        texDescriptor.usage = .shaderRead
        
        let texture = device.makeTexture(descriptor: texDescriptor)!
        
        texture.replace(region: MTLRegionMake3D(0, 0, 0, image4DSimple.sizeX, image4DSimple.sizeY, image4DSimple.sizeZ),
                         mipmapLevel: 0,
                         slice: 0,
                         withBytes: values,
                         bytesPerRow: image4DSimple.sizeX * MemoryLayout<UInt8>.size,
                         bytesPerImage: image4DSimple.sizeX * image4DSimple.sizeY * MemoryLayout<UInt8>.size)
        
        super.init(name: "Quad", vertices: verticesArray, device: device, texture: texture,viewWidth: viewWidth,viewHeight: viewHeight)
        }
    
   
    
}
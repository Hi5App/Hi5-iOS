//
//  Vertex.swift
//  metalLearning
//
//  Created by 李凯翔 on 2022/3/6.
//

import Foundation

struct Vertex{
    var x,y,z:Float
    var r,g,b,a:Float
    var s,t:Float // add coordinates to match texture
    
    func floatBuffer() -> [Float]{
        return [x,y,z,r,g,b,a,s,t]
    }
}

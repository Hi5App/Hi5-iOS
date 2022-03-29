//
//  Matrix4.swift
//  metalLearning
//
//  Created by 李凯翔 on 2022/3/6.
//

import UIKit
import GLKit

extension Float {
    var radians: Float {
        return GLKMathDegreesToRadians(self)
    }
}

class Matrix4 {
    
    var glkMatrix: GLKMatrix4
    
    static func makePerspectiveView(angle: Float, aspectRatio: Float, nearZ: Float, farZ: Float) -> Matrix4 {
        let matrix = Matrix4()
        let angleRad = angle.radians
        matrix.glkMatrix = GLKMatrix4MakePerspective(angleRad, aspectRatio, nearZ, farZ)
        return matrix
    }
    
    static func numberOfElements() -> Int{
        return 16
    }
    
    init() {
        glkMatrix = GLKMatrix4Identity
    }
    
    func copy() -> Matrix4 {
        let newMatrix = Matrix4()
        newMatrix.glkMatrix = self.glkMatrix
        return newMatrix
    }
    
    func scale(x: Float, y: Float, z: Float) {
        glkMatrix = GLKMatrix4Scale(glkMatrix, x, y, z)
    }
    
    func rotateAround(x: Float, y: Float, z: Float) {
        glkMatrix = GLKMatrix4Rotate(glkMatrix, x.radians, 1, 0, 0)
        glkMatrix = GLKMatrix4Rotate(glkMatrix, y.radians, 0, 1, 0)
        glkMatrix = GLKMatrix4Rotate(glkMatrix, z.radians, 0, 0, 1)
    }
    
    func translate(x: Float, y: Float, z: Float) {
        glkMatrix = GLKMatrix4Translate(glkMatrix, x, y, z)
    }
    
    func multiply(left: Matrix4) {
        glkMatrix = GLKMatrix4Multiply(left.glkMatrix, glkMatrix)
    }
    
    var raw: [Float] {
        let value = glkMatrix.m
        //I cannot think of a better way of doing this
        return [value.0, value.1, value.2, value.3, value.4, value.5, value.6, value.7, value.8, value.9, value.10, value.11, value.12, value.13, value.14, value.15]
    }
    
    func transpose() {
        glkMatrix = GLKMatrix4Transpose(glkMatrix)
    }
    
}

//
//  BufferProvider.swift
//  metalLearning
//
//  Created by 李凯翔 on 2022/3/9.
//

import Metal
import simd

class BufferProvider:NSObject{
    let inflightBuffersCount:Int
    private var uniformBuffers:[MTLBuffer]
    private var avaliableBufferIndex:Int = 0
    var availableResourcesSemaphore:DispatchSemaphore
    
    init(device:MTLDevice,inflightBuffersCount:Int,sizeOfUniformsBuffer:Int){
        availableResourcesSemaphore = DispatchSemaphore(value: inflightBuffersCount)
        self.inflightBuffersCount = inflightBuffersCount
        uniformBuffers = [MTLBuffer]()
        
        for _ in 0...inflightBuffersCount-1{
            let uniformBuffer = device.makeBuffer(length: sizeOfUniformsBuffer, options: [])!
            uniformBuffers.append(uniformBuffer)
        }
    }
    
    func nextUniformsBuffer(projectionMatrix:float4x4,modelViewMatrix:float4x4) ->MTLBuffer{
        let buffer = uniformBuffers[avaliableBufferIndex]
        let bufferPointer = buffer.contents()
        
        var projectionMatrix = projectionMatrix
        var modelViewMatrix = modelViewMatrix
        
        memcpy(bufferPointer, &modelViewMatrix, MemoryLayout<Float>.size*float4x4.numberOfElements())
        memcpy(bufferPointer + MemoryLayout<Float>.size*float4x4.numberOfElements(), &projectionMatrix, MemoryLayout<Float>.size*float4x4.numberOfElements())
        
        avaliableBufferIndex += 1
        if avaliableBufferIndex == inflightBuffersCount{
            avaliableBufferIndex = 0
        }
        
        return buffer
    }
    
    deinit{
        for _ in 0...self.inflightBuffersCount{
            self.availableResourcesSemaphore.signal()
        }
    }
    
}

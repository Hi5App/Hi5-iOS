//
//  BufferProvider.swift
//  metalLearning
//
//  Created by 李凯翔 on 2022/3/9.
//

import Metal

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
    
    func nextUniformsBuffer(projectionMatrix:Matrix4,modelViewMatrix:Matrix4) ->MTLBuffer{
        let buffer = uniformBuffers[avaliableBufferIndex]
        let bufferPointer = buffer.contents()
        
        memcpy(bufferPointer, modelViewMatrix.raw, MemoryLayout<Float>.size*Matrix4.numberOfElements())
        memcpy(bufferPointer + MemoryLayout<Float>.size*Matrix4.numberOfElements(), projectionMatrix.raw, MemoryLayout<Float>.size*Matrix4.numberOfElements())
        
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

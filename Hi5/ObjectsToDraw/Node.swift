//
//  Node.swift
//  metalLearning
//
//  Created by 李凯翔 on 2022/3/6.
//

import Foundation
import Metal
import QuartzCore
import simd
import UIKit

class Node{
    let device:MTLDevice
    let name:String
    let vertexCount:Int
    let vertexBuffer:MTLBuffer!
   
    var positionX: Float = 0.0
    var positionY: Float = 0.0
    var positionZ: Float = 0.0

    var rotationX: Float = 0.0
    var rotationY: Float = 0.0
    var rotationZ: Float = 0.0
    var scale: Float = 1.0
    
    var time:CFTimeInterval = 0.0
    
    var bufferProvider:BufferProvider
    
    var texture:MTLTexture
    lazy var samplerState:MTLSamplerState? = Node.defaultSampler(device:self.device)
    
    var frontFaceTexture:MTLTexture
    var frontFaceTexRenderPassDescriptor:MTLRenderPassDescriptor
    var frontFacePipelineState:MTLRenderPipelineState
    
    var backFaceTexture:MTLTexture
    var backFaceTexRenderPassDescriptor:MTLRenderPassDescriptor
    var backFacePipelineState:MTLRenderPipelineState
    
    func updateWithDelta(delta:CFTimeInterval){
        time += delta
    }

    func modelMatrix() -> float4x4 {
        var matrix = float4x4()
        matrix.translate(positionX, y: positionY, z: positionZ)
        matrix.rotateAroundX(rotationX, y: rotationY, z: rotationZ)
        matrix.scale(scale, y: scale, z: scale)
        return matrix
    }

    // call once per draw
    init(name:String,vertices:Array<Vertex>,device:MTLDevice,texture:MTLTexture,viewWidth:Int,viewHeight:Int){
        var vertexData = Array<Float>()
        for vertex in vertices {
            vertexData += vertex.floatBuffer()
        }
        
        let dataSize = vertexData.count * MemoryLayout.size(ofValue: vertexData[0])
        vertexBuffer = device.makeBuffer(bytes: vertexData, length: dataSize, options: [])
        
        self.name = name
        self.device = device
        vertexCount = vertices.count
        self.texture = texture
        
        self.bufferProvider = BufferProvider(device: device, inflightBuffersCount: 3, sizeOfUniformsBuffer: MemoryLayout<Float>.size*float4x4.numberOfElements()*2)
        
        //set up for rendering the front face to frontFaceTextureDescriptor
        
        //set up the front face texture
        let frontFaceTexDescriptor = MTLTextureDescriptor()
        frontFaceTexDescriptor.textureType = MTLTextureType.type2D
        frontFaceTexDescriptor.width = viewWidth
        frontFaceTexDescriptor.height = viewHeight
        frontFaceTexDescriptor.pixelFormat = .rgba8Unorm
        frontFaceTexDescriptor.usage = .unknown
        frontFaceTexture = device.makeTexture(descriptor: frontFaceTexDescriptor)!
        // set up front face render pass descriptor
        frontFaceTexRenderPassDescriptor = MTLRenderPassDescriptor()
        frontFaceTexRenderPassDescriptor.colorAttachments[0].texture = frontFaceTexture
        frontFaceTexRenderPassDescriptor.colorAttachments[0].loadAction = .clear
        frontFaceTexRenderPassDescriptor.colorAttachments[0].storeAction = .store
        frontFaceTexRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 0, 1)
        
        // set up front face pipeline
        let defaultLibrary = device.makeDefaultLibrary()!
        let fragmentProgram = defaultLibrary.makeFunction(name: "texture_fragment")
        let vertexProgram = defaultLibrary.makeFunction(name: "texture_vertex")
        
        let frontFacePipelineStateDescriptor = MTLRenderPipelineDescriptor()
        frontFacePipelineStateDescriptor.label = "Offscreen Render front face"
        frontFacePipelineStateDescriptor.vertexFunction = vertexProgram
        frontFacePipelineStateDescriptor.fragmentFunction = fragmentProgram
        frontFacePipelineStateDescriptor.colorAttachments[0].pixelFormat = .rgba8Unorm
        
        frontFacePipelineState = try! device.makeRenderPipelineState(descriptor: frontFacePipelineStateDescriptor)
        
        //set up the back face texture
        let backFaceTexDescriptor = MTLTextureDescriptor()
        backFaceTexDescriptor.textureType = MTLTextureType.type2D
        backFaceTexDescriptor.width = viewWidth
        backFaceTexDescriptor.height = viewHeight
        backFaceTexDescriptor.pixelFormat = .rgba8Unorm
        backFaceTexDescriptor.usage = .unknown
        backFaceTexture = device.makeTexture(descriptor: backFaceTexDescriptor)!
        // set up back back render pass descriptor
        backFaceTexRenderPassDescriptor = MTLRenderPassDescriptor()
        backFaceTexRenderPassDescriptor.colorAttachments[0].texture = backFaceTexture
        backFaceTexRenderPassDescriptor.colorAttachments[0].loadAction = .clear
        backFaceTexRenderPassDescriptor.colorAttachments[0].storeAction = .store
        backFaceTexRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 0, 1)
        
        // set up back face pipeline
        let backFacePipelineStateDescriptor = MTLRenderPipelineDescriptor()
        backFacePipelineStateDescriptor.label = "Offscreen Render back face"
        backFacePipelineStateDescriptor.vertexFunction = vertexProgram
        backFacePipelineStateDescriptor.fragmentFunction = fragmentProgram
        backFacePipelineStateDescriptor.colorAttachments[0].pixelFormat = .rgba8Unorm
        backFacePipelineState = try! device.makeRenderPipelineState(descriptor: backFacePipelineStateDescriptor)
        
        
    }
    
    // call 60 times a second
    func render(commandQueue:MTLCommandQueue,pipelineState:MTLRenderPipelineState,drawable:CAMetalDrawable,parentModelViewMatrix:float4x4, projectionMatrix:float4x4,clearColor:MTLClearColor?,markerArray:[Marker],Tree:neuronTree?){
        _ = bufferProvider.availableResourcesSemaphore.wait(timeout: DispatchTime.distantFuture)
        
        // set up for cube texture
        let A = Vertex(x: -1.0, y:   1.0, z:   1.0, r:  0.0, g:  1.0, b:  1.0, a:  1.0,s: 0.0,t: 0.3)
        let B = Vertex(x: -1.0, y:  -1.0, z:   1.0, r:  0.0, g:  0.0, b:  1.0, a:  1.0,s: 0.0,t: 0.7)
        let C = Vertex(x:  1.0, y:  -1.0, z:   1.0, r:  1.0, g:  0.0, b:  1.0, a:  1.0,s: 1.0,t: 0.7)
        let D = Vertex(x:  1.0, y:   1.0, z:   1.0, r:  1.0, g:  1.0, b:  1.0, a:  1.0,s: 1.0,t: 0.3)
        
        let Q = Vertex(x: -1.0, y:   1.0, z:  -1.0, r:  0.0, g:  1.0, b:  0.0, a:  1.0,s: 0.0,t: 0.0)
        let R = Vertex(x:  1.0, y:   1.0, z:  -1.0, r:  1.0, g:  1.0, b:  0.0, a:  1.0,s: 0.0,t: 0.0)
        let S = Vertex(x: -1.0, y:  -1.0, z:  -1.0, r:  0.0, g:  0.0, b:  0.0, a:  1.0,s: 0.0,t: 0.0)
        let T = Vertex(x:  1.0, y:  -1.0, z:  -1.0, r:  1.0, g:  0.0, b:  0.0, a:  1.0,s: 0.0,t: 0.0)
        
        let cubeVerticesArray:Array<Vertex> = [
            
            A,B,C ,A,C,D,   //Front
            R,T,S ,Q,R,S,   //Back
            
            Q,S,B ,Q,B,A,   //Left
            D,C,T ,D,T,R,   //Right
            
            Q,A,D ,Q,D,R,   //Top
            B,S,T ,B,T,C    //Bot
        ]
        
        let dataSize = cubeVerticesArray.count * MemoryLayout.size(ofValue: cubeVerticesArray[0])
        let cubeVertexBuffer = device.makeBuffer(bytes: cubeVerticesArray, length: dataSize, options: [])
        
        // start render
        
        var nodeModelMatrix = self.modelMatrix()
        nodeModelMatrix.multiplyLeft(parentModelViewMatrix)
        let uniformBuffer = bufferProvider.nextUniformsBuffer(projectionMatrix: projectionMatrix, modelViewMatrix: nodeModelMatrix)
        
        let commanBuffer = commandQueue.makeCommandBuffer()!
        commanBuffer.addCompletedHandler({
            (_) in
            self.bufferProvider.availableResourcesSemaphore.signal() //when GPU is done with the buffer and release it
        })
        // render the front face to the texture
        if let renderEncoder = commanBuffer.makeRenderCommandEncoder(descriptor: frontFaceTexRenderPassDescriptor){
            renderEncoder.label = "offscreen render front face"
            renderEncoder.setRenderPipelineState(frontFacePipelineState)
            renderEncoder.setCullMode(.front)
            renderEncoder.setVertexBuffer(cubeVertexBuffer, offset: 0, index: 0)
            renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: cubeVerticesArray.count)
            
            renderEncoder.endEncoding()
        }else{
            print("renderEncoder for front face rendering failed")
        }
        // render the back face to the texture
        if let renderEncoder = commanBuffer.makeRenderCommandEncoder(descriptor: backFaceTexRenderPassDescriptor){
            renderEncoder.label = "offscreen render back face"
            renderEncoder.setRenderPipelineState(backFacePipelineState)
            renderEncoder.setCullMode(.back)
            renderEncoder.setVertexBuffer(cubeVertexBuffer, offset: 0, index: 0)
            renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: cubeVerticesArray.count)
            
            renderEncoder.endEncoding()
        }else{
            print("renderEncoder for back face rendering failed")
        }
        
        
        
        // share the renderEncoder
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 123.0/255.0, green: 133.0/255.0, blue: 199.0/255.0, alpha: 1.0)
        let renderEncoder = commanBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        
        // draw the final Quad
//        renderEncoder.setCullMode(MTLCullMode.front) //切面
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentTexture(frontFaceTexture, index: 0)
        renderEncoder.setFragmentTexture(backFaceTexture, index: 1)
        renderEncoder.setFragmentTexture(texture, index: 2)
        if let samplerState = samplerState{
            renderEncoder.setFragmentSamplerState(samplerState, index: 0)
        }
        
        // draw extra triangle
        
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount,instanceCount: 1)
        
        // draw soma if exits
        if !markerArray.isEmpty {
            //generate vertices
            for marker in markerArray{
                // cube vertices
                let center = marker.displayPosition
                let color = marker.color
                let size = marker.size
                let A = Vertex(x: -size+center.x, y:  size+center.y, z:   size+center.z, r:  Float(color.redValue), g:  Float(color.greenValue), b:  Float(color.blueValue), a:  1.0,s: 0.0,t: 0.3)
                let B = Vertex(x: -size+center.x, y:  -size+center.y, z:   size+center.z, r:  Float(color.redValue), g:  Float(color.greenValue), b:  Float(color.blueValue), a:  1.0,s: 0.0,t: 0.7)
                let C = Vertex(x:  size+center.x, y:  -size+center.y, z:   size+center.z, r:  Float(color.redValue), g:  Float(color.greenValue), b:  Float(color.blueValue), a:  1.0,s: 1.0,t: 0.7)
                let D = Vertex(x:  size+center.x, y:   size+center.y, z:   size+center.z, r:  Float(color.redValue), g:  Float(color.greenValue), b:  Float(color.blueValue), a:  1.0,s: 1.0,t: 0.3)
                
                let Q = Vertex(x: -size+center.x, y:   size+center.y, z:  -size+center.z, r:  Float(color.redValue), g:  Float(color.greenValue), b:  Float(color.blueValue), a:  1.0,s: 0.0,t: 0.0)
                let R = Vertex(x:  size+center.x, y:   size+center.y, z:  -size+center.z, r:  Float(color.redValue), g:  Float(color.greenValue), b:  Float(color.blueValue), a:  1.0,s: 0.0,t: 0.0)
                let S = Vertex(x: -size+center.x, y:  -size+center.y, z:  -size+center.z, r:  Float(color.redValue), g:  Float(color.greenValue), b:  Float(color.blueValue), a:  1.0,s: 0.0,t: 0.0)
                let T = Vertex(x:  size+center.x, y:  -size+center.y, z:  -size+center.z, r:  Float(color.redValue), g:  Float(color.greenValue), b:  Float(color.blueValue), a:  1.0,s: 0.0,t: 0.0)
                
                let cubeVerticesArray:Array<Vertex> = [
                    
                    A,B,C ,A,C,D,   //Front
                    R,T,S ,Q,R,S,   //Back
                    
                    Q,S,B ,Q,B,A,   //Left
                    D,C,T ,D,T,R,   //Right
                    
                    Q,A,D ,Q,D,R,   //Top
                    B,S,T ,B,T,C    //Bot
                ]
                
                let dataSize = cubeVerticesArray.count * MemoryLayout.size(ofValue: cubeVerticesArray[0])
                let cubeVertexBuffer = device.makeBuffer(bytes: cubeVerticesArray, length: dataSize, options: [])
                
                //draw triangles
                let defaultLibrary = device.makeDefaultLibrary()!
                let fragmentProgram = defaultLibrary.makeFunction(name: "texture_fragment")
                let vertexProgram = defaultLibrary.makeFunction(name: "texture_vertex")
                
                let trianglePipelineStateDescriptor = MTLRenderPipelineDescriptor()
                trianglePipelineStateDescriptor.label = "draw cube marker"
                trianglePipelineStateDescriptor.vertexFunction = vertexProgram
                trianglePipelineStateDescriptor.fragmentFunction = fragmentProgram
                trianglePipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
                
                let trianglePipelineState = try! device.makeRenderPipelineState(descriptor: trianglePipelineStateDescriptor)
                
    //            let renderEncoder = commanBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
                renderEncoder.setRenderPipelineState(trianglePipelineState)
                renderEncoder.setVertexBuffer(cubeVertexBuffer, offset: 0, index: 0)
                renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
                renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: cubeVerticesArray.count)
            }
        }
        
        // draw swc if it's not empty
        if let tree = Tree {
            var head = 0
            var tail = 1
            let swcArray = tree.nodes.map { node in
                return CoordHelper.swcPointsLocation2DisplayLineLocation(from: node.position, swcCenter: tree.centerPosition)
            }
            while(tail < swcArray.count-1){
                let pointALoc = swcArray[head]
                let pointBLoc = swcArray[tail]
                let lineColor = UIColor.systemRed
                let pointA = Vertex(x: pointALoc.x, y: pointALoc.y, z: pointALoc.z, r: Float(lineColor.redValue), g: Float(lineColor.greenValue), b: Float(lineColor.blueValue), a: 1.0, s: 1.0, t: 1.0)
                let pointB = Vertex(x: pointBLoc.x, y: pointBLoc.y, z: pointBLoc.z, r: Float(lineColor.redValue), g: Float(lineColor.greenValue), b: Float(lineColor.blueValue), a: 1.0, s: 1.0, t: 1.0)
                let pointArray = [pointA,pointB]
                let dataSize = pointArray.count * MemoryLayout.size(ofValue: pointArray[0])
                let pointBuffer = device.makeBuffer(bytes: pointArray, length: dataSize, options: [])
                
                //draw triangles
                let defaultLibrary = device.makeDefaultLibrary()!
                let fragmentProgram = defaultLibrary.makeFunction(name: "texture_fragment")
                let vertexProgram = defaultLibrary.makeFunction(name: "texture_vertex")
                
                let trianglePipelineStateDescriptor = MTLRenderPipelineDescriptor()
                trianglePipelineStateDescriptor.label = "draw swc lines"
                trianglePipelineStateDescriptor.vertexFunction = vertexProgram
                trianglePipelineStateDescriptor.fragmentFunction = fragmentProgram
                trianglePipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
                
                let trianglePipelineState = try! device.makeRenderPipelineState(descriptor: trianglePipelineStateDescriptor)
                
    //            let renderEncoder = commanBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
                renderEncoder.setRenderPipelineState(trianglePipelineState)
                renderEncoder.setVertexBuffer(pointBuffer, offset: 0, index: 0)
                renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
                renderEncoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: pointArray.count)
                
                if tree.nodes[tail].parentId == -1{
                    head += 2
                    tail += 2
                }else{
                    head += 1
                    tail += 1
                }
            }
        }
        
        renderEncoder.endEncoding()
       
        commanBuffer.present(drawable)
        commanBuffer.commit()
    }
    
    class func defaultSampler(device:MTLDevice) ->MTLSamplerState{
        let sampler = MTLSamplerDescriptor()
        sampler.minFilter = MTLSamplerMinMagFilter.nearest
        sampler.magFilter = MTLSamplerMinMagFilter.nearest
        sampler.mipFilter = MTLSamplerMipFilter.nearest
        sampler.maxAnisotropy = 1
        sampler.sAddressMode = .clampToEdge
        sampler.tAddressMode = .clampToEdge
        sampler.rAddressMode = .clampToEdge
        sampler.normalizedCoordinates = true
        sampler.lodMinClamp = 0
        sampler.lodMaxClamp = .greatestFiniteMagnitude
        return device.makeSamplerState(descriptor: sampler)!
    }
}



//
//  AnnotationHelper.swift
//  Hi5
//
//  Created by 李凯翔 on 2022/8/9.
//

import Foundation
import simd

struct IntPoint3D{
    let x:Int
    let y:Int
    let z:Int
    
    func inBounds(minBound:IntPoint3D,maxBound:IntPoint3D)->Bool{
        return self.x >= minBound.x && self.y >= minBound.y && self.z >= minBound.z
        && self.x <= maxBound.x && self.y <= maxBound.y && self.z <= maxBound.z
    }
    
    var tupleValue:(Int,Int,Int){
        return (x,y,z)
    }
    
}

struct neuronTracing{
    
    // useful constants
    let sqrt2 = 1.41421356237
    let sqrt3 = 1.73205080757
    
    func app2(seed:simd_float3,image:image4DSimple)
//    -> neuronTree
    {
        let time1 = Date()
        // step one: create a over-complete tree
        let seedPosition = image.access3DfromCenter(x: seed.x, y: seed.y, z:seed.z)
        let seedIntPosition = IntPoint3D(x: Int(seedPosition.0), y: Int(seedPosition.1), z: Int(seedPosition.2))
        // prepare data structure
        let arraysize = image.sizeX*image.sizeY*image.sizeZ
        let imageSize = (image.sizeX,image.sizeY,image.sizeZ)
        // array stores distance parent status
        var distance = Array(repeating: Float.greatestFiniteMagnitude, count: arraysize)
        var parent = Array(repeating: -2, count: arraysize)
        for i in 0...parent.count-1{
            parent[i] = image.imageArray[i] > image.avgIntensity ? 0 : -1
        }
        var status = Array(repeating: spacePointsStatus.FAR, count: arraysize)
        // init for seed position
        let index = CoordHelper.coord2Index(coord: seedIntPosition, size: imageSize)
        distance[index] = 0
        parent[index] = index
        status[index] = .ALIVE
        let element = heapElement(index: index, distance: 0)
        // fast marching
        var minHeap = heap(sort: compareHeapElement)
        minHeap.insert(element)
        outerLoop: while !minHeap.isEmpty {
            let minElement = minHeap.remove()!
            let minPosition:IntPoint3D = CoordHelper.index2Coord(index: minElement.index, size: imageSize)
            let nearPoints = nearElements(seed:minPosition , numberOfElements: 6, minBound: IntPoint3D(x: 0, y: 0, z: 0), maxBound: IntPoint3D(x: 127, y: 127, z: 127))
            for point in nearPoints{
                let nearIndex = CoordHelper.coord2Index(coord: point, size: imageSize)
                if parent[nearIndex] == -1 {continue}
                if status[nearIndex] != .ALIVE{
                    let startPosition:(Int,Int,Int) = CoordHelper.index2Coord(index: minElement.index, size: imageSize)
                    let newDistance = minElement.distance + graphDistance(from: startPosition, to: point.tupleValue,image: image)
                    let newElement = heapElement(index: nearIndex, distance: newDistance)
                    if status[nearIndex] == .FAR{
                        //update info
                        parent[nearIndex] = minElement.index
                        distance[nearIndex] = newDistance
                        status[nearIndex] = .TRIAL
                        // insert to heap
                        minHeap.insert(newElement)
                    }else if status[nearIndex] == .TRIAL{
                       // update info when newDistance is shorter
                        if newDistance < distance[nearIndex]{
                            // update info
                            distance[nearIndex] = newDistance
                            parent[nearIndex] = minElement.index
                            // update element in heap (remove and reinsert)
                            guard let index = minHeap.nodes.firstIndex(where: {$0.index == nearIndex}) else {
                                print("TRIAL objects can't be found in heap")
                                break outerLoop
                            }
                            minHeap.remove(at: index)
                            minHeap.insert(newElement)
                        }
                    }
                }
            }
            
        }
        let time2 = Date()
        print("init tree computation used \(time2.timeIntervalSince(time1))")
    }
    
    func graphDistance(from A:(Int,Int,Int),to B:(Int,Int,Int),image:image4DSimple)->Float{
//        let euclideanDistance = sqrt(pow(Double(abs(A.0-B.0)), 2) + pow(Double(abs(A.1-B.1)), 2) + pow(Double(abs(A.2-B.2)), 2))
        let gap = abs(A.0 - B.0) + abs(A.1 - B.1) + abs(A.2 - B.2)
        var euclideanDistance:Double = 0.0
        switch gap{
        case 1:
            euclideanDistance = 1.0
        case 2:
            euclideanDistance = sqrt2
        case 3:
            euclideanDistance = sqrt3
        default:
            fatalError("error when calculating enclideanDistance in app2 graphDistanceFunction")
        }
        let intensityParameter = (intensity(for: A, lambda: 10,image: image) + intensity(for: B, lambda: 10,image: image))/2.0
        return Float(euclideanDistance) * intensityParameter
    }
    
    func intensity(for point:(Int,Int,Int), lambda:Float,image:image4DSimple)->Float{
//        let intensity = image.sample3Ddata(x: Float(point.0), y: Float(point.1), z: Float(point.2))
        let intensity = image.imageArray[CoordHelper.coord2Index(coord: point, size: (image.sizeX,image.sizeY,image.sizeZ))]
        let ratio = pow((1-(Float(intensity) - Float(image.minIntensity))/(Float(image.maxIntensity) - Float(image.minIntensity))),2)
        return Float(exp(ratio*lambda))
    }
    
    func nearElements(seed:IntPoint3D,numberOfElements:Int,minBound:IntPoint3D,maxBound:IntPoint3D)->[IntPoint3D]{
        if numberOfElements == 6{
            let array = [(-1,0,0),(0,-1,0),(0,0,-1),(1,0,0),(0,1,0),(0,0,1)]
            var pointArray = array.map({IntPoint3D(x: $0.0+seed.x, y: $0.1+seed.y, z: $0.2+seed.z)})
            pointArray = pointArray.filter({ point in
                return point.inBounds(minBound: minBound, maxBound: maxBound)
            })
            return pointArray
        }else{
            print("unsupported elements number")
            return [IntPoint3D]()
        }
    }
    
    func compareHeapElement(_ point1:heapElement,_ point2:heapElement)->Bool{
        return point1.distance < point2.distance
    }
    
}

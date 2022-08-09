//
//  CoordHelper.swift
//  Hi5
//
//  Created by 李凯翔 on 2022/4/23.
//

import Foundation
import simd

extension PositionFloat{
    func PositionFloat2PositionInt() -> PositionInt{
        return PositionInt(x: Int(self.x), y: Int(self.y), z: Int(self.z))
    }
}

struct CoordHelper{
    
    // these two following function should be used when the image is in secondary resolution
    static func DisplaySomaLocation2UploadSomaLocation(displayLoc:simd_float3,center:PositionInt)->SomaInfo{
        let x = ((displayLoc.x*64)+Float(center.x))*2
        let y = ((displayLoc.y*64)+Float(center.y))*2
        let z = ((displayLoc.z*64)+Float(center.z))*2
        return SomaInfo(id: -1, loc: PositionFloat(x: x, y: y, z: z))
    }
    
    static func UploadSomaLocation2DisplaySomaLocation(uploadLoc:SomaInfo,center:PositionInt)->simd_float3{
        return simd_float3(x:Float((uploadLoc.loc.x/2-Float(center.x)))/64.0,
                           y:Float((uploadLoc.loc.y/2-Float(center.y)))/64.0,
                           z:Float((uploadLoc.loc.z/2-Float(center.z)))/64.0)
    }
    
    // global coord to display coord
    static func swcPointsLocation2DisplayLineLocation(from swcPoints:PositionFloat,swcCenter:PositionFloat)->simd_float3{
        return simd_float3(x: (swcPoints.x - swcCenter.x)/128,
                           y: (swcPoints.y - swcCenter.y)/128,
                           z: (swcPoints.z - swcCenter.z)/128)
    }
    
    static func DisplayMarkerLocation2GlobalLocation(from displayLoc:simd_float3,center:PositionFloat)->PositionFloat{
        return PositionFloat(x: Float(displayLoc.x)*128+center.x,
                             y: Float(displayLoc.y)*128+center.y,
                             z: Float(displayLoc.z)*128+center.z)
    }
    
    static func coord2Index(coord:(Int,Int,Int),size:(Int,Int,Int))->Int{
        return coord.0*size.0*size.1 + coord.1*size.2 + coord.2
    }
    
    static func coord2Index(coord:IntPoint3D,size:(Int,Int,Int))->Int{
        return coord.x*size.0*size.1 + coord.y*size.2 + coord.z
    }
    
    static func index2Coord(index:Int,size:(Int,Int,Int))->(Int,Int,Int){
        let x = index/(size.0*size.1)
        let y = (index - (size.0*size.1*x))/128
        let z = index - (size.0*size.1*x) - (size.2*y)
        return (x,y,z)
    }
    
    static func index2Coord(index:Int,size:(Int,Int,Int))->IntPoint3D{
        let x = index/(size.0*size.1)
        let y = (index - (size.0*size.1*x))/128
        let z = index - (size.0*size.1*x) - (size.2*y)
        return IntPoint3D(x: x, y: y, z: z)
    }
}

//
//  CoordHelper.swift
//  Hi5
//
//  Created by 李凯翔 on 2022/4/23.
//

import Foundation
import simd

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
}

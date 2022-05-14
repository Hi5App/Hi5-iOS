//
//  Marker.swift
//  Hi5
//
//  Created by 李凯翔 on 2022/5/14.
//

import Foundation
import simd
import UIKit

enum MarkerType{
    case MarkerFactory
    case MissingMarker
    case WrongMarker
    case BreakingPointMarker
}

struct Marker:Equatable{
    let type:MarkerType
    let displayPosition:simd_float3
    let color:UIColor
    let size:Float = 0.03
}

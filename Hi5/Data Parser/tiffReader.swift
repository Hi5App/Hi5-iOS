//
//  tiffReader.swift
//  Hi5
//
//  Created by 李凯翔 on 2022/8/18.
//

import Foundation
import ImageIO
import UIKit



struct tiffReader{
    static func read(from url:URL) -> image4DSimple? {
        let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil)
        guard let source = imageSource else {return nil}
        let numberOfImages = CGImageSourceGetCount(source)
        let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        guard let image = image else {return nil}
        let height = image.height
        let width = image.width
        var data1D = [UInt8]()
        for i in 0...numberOfImages-1{
            let image = CGImageSourceCreateImageAtIndex(source, i, nil)
            guard let image = image else {return nil}
            guard image.height == height && image.width == width else {return nil}
            print(image)
            let pixels = pixelValues(fromCGImage: image).pixelValues
            if let pixels = pixels {
                data1D.append(contentsOf: pixels)
            }
        }
        
        let name = url.lastPathComponent
        let endiannessType = Character("L")
        let dataType = UInt8(1)
        let sX = width
        let sY = height
        let sZ = numberOfImages
        let channel = 3
        let data3D = [[[UInt8(0)]]]
        let min = UInt8(255)
        let max = UInt8(0)
        let avg = UInt8(0)
        let image4D = image4DSimple(name: name, endiannessType: endiannessType, dataType: dataType, sX, sY, sZ, channel, data3D, array: data1D, maxIntensity: max, minIntensity: min, avgIntensity: avg)
        return image4D
    }
    
    static func pixelValues(fromCGImage imageRef: CGImage?) -> (pixelValues: [UInt8]?, width: Int, height: Int)
    {
        var width = 0
        var height = 0
        var pixelValues: [UInt8]?
        if let imageRef = imageRef {
            width = imageRef.width
            height = imageRef.height
            let bitsPerComponent = imageRef.bitsPerComponent
            let bytesPerRow = imageRef.bytesPerRow
            let totalBytes = height * bytesPerRow

            let colorSpace = CGColorSpaceCreateDeviceGray()
            var intensities = [UInt8](repeating: 0, count: totalBytes)

            let contextRef = CGContext(data: &intensities, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: 0)
            contextRef?.draw(imageRef, in: CGRect(x: 0.0, y: 0.0, width: CGFloat(width), height: CGFloat(height)))

            pixelValues = intensities
        }

        return (pixelValues, width, height)
    }
}

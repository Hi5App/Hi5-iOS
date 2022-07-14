//
//  PBDImage.swift
//  Hi5
//
//  Created by 李凯翔 on 2022/4/18.
//

import Foundation

struct PBDImage{
    
    var PBDimageURL:URL
    
    init(imageLocation url:URL){
        PBDimageURL = url
    }
    
    let formatKey:String = "v3d_volume_pkbitdf_encod"
    
    var decompressionByteBuffer:[UInt8]!
    var compressionByteBuffer = [UInt8]()
    
    mutating func decompressToV3draw()->image4DSimple?{
        // read into bytes array
        do{
            let data = try Data(contentsOf: PBDimageURL)
            compressionByteBuffer = [UInt8](data)
        }catch{
            print(error)
        }
        
        // check formatKey
        var readedFormatKey = ""
        for i in 0...23{
            let myUnicodeScalar = UnicodeScalar(compressionByteBuffer[i])
            let myCharacter = Character(myUnicodeScalar)
            readedFormatKey.append(myCharacter)
        }
        guard readedFormatKey == formatKey else{
            print("FormatKey didn't match")
            return nil
        }
        
        // check endianness
        let endianness = Character(UnicodeScalar(compressionByteBuffer[24]))
        guard endianness == "B" || endianness == "L" else{
            print("Unsupported endianness")
            return nil
        }
        let isBig = endianness == "B"
//        if endianness == "B"{
//            print("it's big endian")
//        }else if endianness == "L"{
//            print("it's little endian")
//        }
        
        // check datatype
        let datatype = UInt8(bytes2Int(bytes: [UInt8](compressionByteBuffer[25...26]), isBig: isBig))
        //skip bytes[26]
//        switch datatype{
//        case 33:
//            print("datatype is 33")
//        case 1:
//            print("datatype is UInt8")
//        case 2:
//            print("datatype is UInt16")
//        case 4:
//            print("datatype is Float32")
//        default:
//            print("unsupported datatype")
//        }
        
        // check size. size is a array with 4 elements. each element is 4 bytes long
        var size:[UInt32] = []
        let dataTypeStart = 27
        for i in 0...3{
            let start = dataTypeStart+i*4
            let fourBytes = compressionByteBuffer[start...start+3]
            let u32 = fourBytes.reversed().reduce(0){
                soFar,byte in
                return soFar << 8 | UInt32(byte)
            }
            size.append(u32)
        }
//        print("its 3d size is \(size[0])*\(size[1])*\(size[2]) with \(size[3]) color channel(s)")
        decompressionByteBuffer = Array(repeating: UInt8(0), count: Int(size[0]*size[1]*size[2]))
        // decompress image data
        decompressPBDImageData(compressionBufferPointer: 43, decompressionBufferPointer: 0, decompressionSize: Int(size[0]*size[1]*size[2]))
//        var imageDataStart = 0
        let array128x128x128 = [[[UInt8(0)]]]
//        Array(repeating: Array(repeating: Array(repeating: UInt8(0), count: 128), count: 128), count: 128)
//        for i in 0...127{
//            for j in 0...127{
//                for k in 0...127{
//                    array128x128x128[i][j][k] = decompressionByteBuffer[imageDataStart]
//                    imageDataStart += 1
//                }
//            }
//        }
//        if imageDataStart == decompressionByteBuffer.count {
//            print("Image \(PBDimageURL.lastPathComponent) read finished")
//        }
        print("Image \(PBDimageURL.lastPathComponent) read finished")
        // init a image4DSimple
        let image4DSimple = image4DSimple(name: PBDimageURL.lastPathComponent, endiannessType: endianness, dataType: datatype, Int(size[0]), Int(size[1]), Int(size[2]), Int(size[3]), array128x128x128 ,array: decompressionByteBuffer,maxIntensity: 255,minIntensity: 0)
//        print("initialized a image4DSimple obejct from pbd file")
        return image4DSimple
    }
    
    func handleDifference(difference:UInt8, value:UInt8)->UInt8{
        if difference == 3{
            if value == 0{
//                return UInt8(255)
                return UInt8(0)
            }else{
                return value-1
            }
        }else{
            if Int(difference)+Int(value) > 255{
                return 0
            }else{
                return difference + value
            }
        }
    }
    
    mutating func decompressPBDImageData(compressionBufferPointer:Int,decompressionBufferPointer:Int,decompressionSize:Int){
        
        var cp = 0 //compressionBuffer pointer
        var dp = 0 //decompressionBuffer pointer
        let mask:UInt8 = 0x03 // mask used to cut a byte
        var p0,p1,p2,p3:UInt8 // byte cuts into four parts:p0,p1,p2,p3
        var value:UInt8 //decompression mode indicator value
        var pva,pvb:UInt8 //difference with last decompression data
        var sourceChar:UInt8 // used for cut byte
        
        var decompressionPointerValue:UInt8 = 0
        
        while(cp < compressionByteBuffer.count - 43){
            
            value = compressionByteBuffer[compressionBufferPointer + cp]
            
            if (value<33){ // copy mode
                let count = Int(value+1)
                for j in cp+1...cp+count{
                    decompressionByteBuffer[decompressionBufferPointer+dp] = compressionByteBuffer[j + compressionBufferPointer]
                    dp += 1
                }
                cp += count+1
                decompressionPointerValue = decompressionByteBuffer[dp-1 + decompressionBufferPointer]
            }else if(value<128){ // difference mode
                var leftToFill = value-32
                while(leftToFill > 0){
                    let fillNumber = min(leftToFill, 4)
                    cp += 1
                    sourceChar = compressionByteBuffer[cp + compressionBufferPointer]
                    var toFill = decompressionBufferPointer + dp
                    p0 = (sourceChar & mask)
                    sourceChar = sourceChar >> 2
                    p1 = (sourceChar & mask)
                    sourceChar = sourceChar >> 2
                    p2 = (sourceChar & mask)
                    sourceChar = sourceChar >> 2
                    p3 = (sourceChar & mask)
                    pva = handleDifference(difference: p0, value: decompressionPointerValue)
                    
                    decompressionByteBuffer[toFill] = pva
                    if (fillNumber > 1){
                         toFill += 1
                        pvb = handleDifference(difference: p1, value: pva)
                        decompressionByteBuffer[toFill] = pvb
                        if (fillNumber > 2){
                            toFill += 1
                            pva = handleDifference(difference: p2, value: pvb)
                            decompressionByteBuffer[toFill] = pva
                            if (fillNumber > 3){
                                toFill += 1
                                decompressionByteBuffer[toFill] = handleDifference(difference: p3, value: pva)
                            }
                        }
                    }
                    
                    decompressionPointerValue = decompressionByteBuffer[toFill]
                    dp += Int(fillNumber)
                    leftToFill -= fillNumber
                }
                cp += 1
            }else{ // repeat mode
                let repeatCount = value-127
                cp += 1
                let repeatValue = compressionByteBuffer[cp+compressionBufferPointer]
                
                for _ in 0..<repeatCount{
                    decompressionByteBuffer[decompressionBufferPointer + dp] = repeatValue
                    dp += 1
                }
                decompressionPointerValue = repeatValue
                cp += 1
            }
        }
        
//        print(dp)
    }
    
    func bytes2Int(bytes:[UInt8], isBig:Bool)->UInt{
        var value = UInt(0)
        if !isBig {
            for byte in bytes.reversed() {
                value = (value << 8) + (UInt)(byte & 0xff)
            }
        } else {
            for byte in bytes {
                value = (value << 8) + (UInt)(byte & 0xff)
            }
        }
        return (UInt)(value & 0xff)
    }
}

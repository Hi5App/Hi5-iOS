//
//  v3drawReader.swift
//  Hi5
//
//  Created by 李凯翔 on 2022/2/24.
//

import Foundation

struct v3drawReader{
    let formatKey = "raw_image_stack_by_hpeng"
    
    func read(from path:URL) -> image4DSimple?{
        // only read specific simle format!
       
        var bytes = [UInt8]()
        // read bytes from url
        do{
            let data = try Data(contentsOf: path)
            bytes = [UInt8](data)
//            print("image is \(bytes.count) byte long")
        }catch{
            print(error)
        }
        // check formatkey
        var readedFormatKey = ""
        for i in 0...23{
            let myUnicodeScalar = UnicodeScalar(bytes[i])
            let myCharacter = Character(myUnicodeScalar)
            readedFormatKey.append(myCharacter)
        }
        guard readedFormatKey == formatKey else{
            print("unsupported format key")
            return nil
        }
//        print("formatKey is \(readedFormatKey) and it's correct!")
        
        // check endianness
        let endianness = Character(UnicodeScalar(bytes[24]))
        guard endianness == "B" || endianness == "L" else{
            print("Unsupported endianness")
            return nil
        }
        if endianness == "B"{
            print("it's big endian")
        }else if endianness == "L"{
            print("it's little endian")
        }
        
        // check datatype
        let datatype = bytes[25]
        //skip bytes[26]
        switch datatype{
        case 1:
            print("datatype is UInt8")
        case 2:
            print("datatype is UInt16")
        case 4:
            print("datatype is Float32")
        default:
            print("unsupported datatype")
        }
            
        // check size. size is a array with 4 elements. each element is 4 bytes long
        var size:[UInt32] = []
        let dataTypeStart = 27
        for i in 0...3{
            let start = dataTypeStart+i*4
            let fourBytes = bytes[start...start+3]
            let u32 = fourBytes.reversed().reduce(0){
                soFar,byte in
                return soFar << 8 | UInt32(byte)
            }
            size.append(u32)
        }
        print("its 3d size is \(size[0])*\(size[1])*\(size[2]) with \(size[3]) color channel(s)")
        
        //save image data into a 3d array
        guard datatype == 1 else{
            print("this app only applys to UInt8 datatype for now")
            return nil
        }
        guard size[3] == 1 else{
            print("more than 1 color channel")
            return nil
        }
        var imageDataStart = 43
        var maxIntensity = UInt8(0)
        var minIntensity = UInt8(255)
        var array128x128x128 = Array(repeating: Array(repeating: Array(repeating: UInt8(0), count: 128), count: 128), count: 128)
        let oneDemenArray = Array(bytes[43...])
        for i in 0...127{
            for j in 0...127{
                for k in 0...127{
                    let intensity = bytes[imageDataStart]
                    array128x128x128[i][j][k] = intensity
                    maxIntensity = max(maxIntensity, intensity)
                    minIntensity = min(minIntensity, intensity)
                    imageDataStart += 1
                }
            }
        }
        if imageDataStart == bytes.count {
            print("Image \(path.lastPathComponent) read in")
        }
        
        
        let image4DSimple = image4DSimple(name: path.lastPathComponent, endiannessType: endianness, dataType: datatype, Int(size[0]), Int(size[1]), Int(size[2]), Int(size[3]), array128x128x128,array: oneDemenArray,maxIntensity: maxIntensity,minIntensity: minIntensity)
        print("initialized a image4DSimple obejct")
        return image4DSimple
    }
}

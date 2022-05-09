//
//  NeuronTree.swift
//  Hi5
//
//  Created by 李凯翔 on 2022/5/9.
//

import Foundation

struct ReconstructionParameter{
    let parameters:[String] // temp definition,not sure its meaning
}

struct neuronNode{
    let id:Int
    let type:String
    let position:PositionFloat
    let radius:Float
    let parentId:Int
    let seg_id:Int
    let level:Int
}

struct neuronTree:CustomStringConvertible{
    var description: String{
        return String("init a neruonTree with brainID:" + brainID + ", center position in \(centerPosition)" + "with \(nodes.count) neuronNodes")
    }
    
    let brainID:String
    let centerPosition:PositionFloat
    let parameter:ReconstructionParameter
    let somaID:String
    
    var nodes:[neuronNode] = []

    init(from url:URL){
        let fileName = url.deletingPathExtension().lastPathComponent
        let fileNameArray = fileName.components(separatedBy: "_")
        let count = fileNameArray.count
        brainID = fileNameArray[0]
        somaID = fileNameArray[1]
        centerPosition = PositionFloat(x: Float(fileNameArray[count-3])!, y: Float(fileNameArray[count-2])!, z: Float(fileNameArray[count-1])!)
        parameter = ReconstructionParameter(parameters: Array(fileNameArray[3...count-4]))
        do {
            let fileString = try String(contentsOf: url)
            var stringArray = fileString.components(separatedBy: "\n")
            stringArray.removeLast(1)
            for string in stringArray{
                let line = string.components(separatedBy: " ")
                if line[0].starts(with: "#"){
                    continue
                }
                let node = neuronNode(id: Int(line[0])!, type: line[1], position: PositionFloat(x: Float(line[2])!, y: Float(line[3])!, z: Float(line[4])!), radius: Float(line[5])!, parentId: Int(line[6])!, seg_id: Int(line[7])!, level: Int(line[8])!)
                nodes.append(node)
            }
            print(self)
        }catch{
            print("read string file from \(url) failed")
        }
    }
}

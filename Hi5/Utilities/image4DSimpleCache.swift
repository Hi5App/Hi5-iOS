//
//  image4DSimpleCache.swift
//  Hi5
//
//  Created by 李凯翔 on 2022/4/21.
//

import Foundation

struct imageMarkerBundle{
    let image:image4DSimple
    let somaList:SomaListFeedBack
}

struct image4DSimpleCache{
   
    
    var imageCache:[imageMarkerBundle]!
    let size = 5
    var index = -1
    
    mutating func addImage(image:image4DSimple,list:SomaListFeedBack){
        if imageCache.count == size{
            imageCache.remove(at: 0)
            imageCache.append(imageMarkerBundle(image: image, somaList: list))
        }else{
            imageCache.append(imageMarkerBundle(image: image, somaList: list))
            index += 1
        }
    }
    
    mutating func previousImage()->imageMarkerBundle?{
        index -= 1
        if index < 0{
            index = 0
            print("no previous image in cache")
            return nil
        }else{
            return imageCache[index]
        }
    }
    
    mutating func nextImage()->imageMarkerBundle?{
        index += 1
        if index < 5{
            return imageCache[index]
        }else{
            index = 4
            print("no next image in cache")
            return nil
        }
    }
}

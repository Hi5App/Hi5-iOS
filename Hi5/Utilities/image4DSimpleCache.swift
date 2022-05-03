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
   
    // MARK: - cache soma potential location
    var somaPoLocations:[PotentialLocationFeedBack] = []
    var index = -1{
        didSet{
//            print("index now is \(index)")
        }
    }
    
    mutating func addLocation(location:PotentialLocationFeedBack){
        somaPoLocations.append(location)
//        print("add a location,total\(somaPoLocations.count)")
        index += 1
    }
    
    mutating func previousLocation()->PotentialLocationFeedBack?{
        if index <= 0{
            print("no previous image location in cache")
            return nil
        }else if index >= somaPoLocations.count{
            print("cache index out of range")
            return nil
        }else{
            index -= 1
            return somaPoLocations[index]
        }
    }
    
    mutating func nextLocation()->PotentialLocationFeedBack?{
        if index >= somaPoLocations.count - 1{
            print("no next image location in cache")
            return nil
        }else{
            index += 1
            return somaPoLocations[index]
        }
    }
    
    
    // MARK: - cache imageBuddle
    
    var imageCache:[imageMarkerBundle] = []
    let size = 5
    
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
        if index == 0{
            print("no previous image in cache")
            return nil
        }else{
            index -= 1
            return imageCache[index]
        }
    }
    
    mutating func nextImage()->imageMarkerBundle?{
        if index == imageCache.count-1{
            print("no next image in cache")
            return nil
        }else{
            index += 1
            return imageCache[index]
        }
    }
}

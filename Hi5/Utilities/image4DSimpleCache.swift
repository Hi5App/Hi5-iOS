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

struct PotentialLocation{
    let potentialLocationFeedBack:PotentialLocationFeedBack
    var isBoring:Bool
    var isFresh:Bool
    var alreadyUpload:Bool
    let createdTime:Double
    
    init(potentialLocationFeedBack:PotentialLocationFeedBack) {
        self.potentialLocationFeedBack = potentialLocationFeedBack
        self.isBoring = false
        self.isFresh = true
        self.alreadyUpload = false
        self.createdTime = Date().timeIntervalSince1970
    }
}

struct image4DSimpleCache{
   
    // MARK: - cache soma potential location
    var somaPoLocations:[PotentialLocation] = []
    var urls:[URL] = []
    var index = -1{
        didSet{
//            print("index now is \(index)")
        }
    }
    
    mutating func addLocation(location:PotentialLocationFeedBack){
        somaPoLocations.append(PotentialLocation(potentialLocationFeedBack: location))
//        print("add a location,total\(somaPoLocations.count)")
        index += 1
    }
    
    mutating func addLocation(location:PotentialLocationFeedBack, url:URL) {
        somaPoLocations.append(PotentialLocation(potentialLocationFeedBack: location))
        urls.append(url)
    }
    
    mutating func previousOne()->Bool {
        var tempIndex = index
        tempIndex -= 1
        while tempIndex >= 0 {
            if (!somaPoLocations[tempIndex].isBoring && (ifStillFresh(tempIndex: tempIndex) || somaPoLocations[tempIndex].alreadyUpload)) {
                break
            }
            tempIndex -= 1
        }
        if tempIndex < 0 {
            return false
        }
        index = tempIndex
        return true
    }
    
    mutating func nextOne()->Bool {
        var tempIndex = index
        tempIndex += 1
        while tempIndex < somaPoLocations.count {
            if (!somaPoLocations[tempIndex].isBoring && (ifStillFresh(tempIndex: tempIndex) || somaPoLocations[tempIndex].alreadyUpload)) {
                break
            }
            tempIndex += 1
        }
        if tempIndex >= somaPoLocations.count {
            return false
        }
        index = tempIndex
        return true
    }
    
    mutating func ifStillFresh(tempIndex:Int)->Bool {
        if !somaPoLocations[tempIndex].isFresh {
            return false
        }
        if Date().timeIntervalSince1970 - somaPoLocations[tempIndex].createdTime > 7 * 60 * 1000 {
            somaPoLocations[tempIndex].isFresh = false
            return false
        }
        return true
    }
    
//    mutating func previousLocation()->PotentialLocationFeedBack?{
//        if index <= 0{
//            print("no previous image location in cache")
//            return nil
//        }else if index >= somaPoLocations.count{
//            print("cache index out of range")
//            return nil
//        }else{
//            index -= 1
//            return somaPoLocations[index]
//        }
//    }
//
//    mutating func nextLocation()->PotentialLocationFeedBack?{
//        if index >= somaPoLocations.count - 1{
//            print("no next image location in cache")
//            return nil
//        }else{
//            index += 1
//            return somaPoLocations[index]
//        }
//    }
    
    
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

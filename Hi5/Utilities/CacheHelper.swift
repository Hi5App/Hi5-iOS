//
//  CacheHelper.swift
//  Hi5
//
//  Created by 朱一行 on 2022/5/12.
//

import Foundation

struct CacheHlper {
    /**
     iOS App
         ├── Documents --- all image/swc file is cached here
         ├── Library
         │   ├── Caches
         │   └── Preferences
         └── tmp
     */
    
    static let fileManager = FileManager.default
    static let rootURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    
    // get cache size ? MB
    static func getCacheSize() -> Double {
        var cacheSize: Double = 0
        cacheSize = caculateFileSize(url: rootURL) / 1024 / 1024
        print(String(format: "%.1fM", cacheSize))
        return cacheSize
    }
    
    static func caculateFileSize(url: URL) -> Double {
        do {
            var fileSzie = 0.0
            if isDirectory(url: url) {
                let files = fileManager.subpaths(atPath: url.path)
                for file in files ?? [] {
                    fileSzie += caculateFileSize(url: url.appendingPathComponent(file))
                }
            } else {
                let attributes: Dictionary = try fileManager.attributesOfItem(atPath: url.path)
                fileSzie = attributes[FileAttributeKey.size] as! Double
            }
            return fileSzie
        } catch {
            return 0
        }
    }
    
    static func deleteCacheFile() -> Bool {
        let files = fileManager.subpaths(atPath: rootURL.path)
        for file in files ?? [] {
            do {
                if file.hasSuffix("v3dpbd") || file.hasSuffix("swc") {
                    try fileManager.removeItem(atPath: rootURL.appendingPathComponent(file).path)
                }
            } catch {
                return false
            }
        }
        return true
    }
    
    static func isDirectory (url: URL) -> Bool {
        var isDirectory: ObjCBool = ObjCBool(false)
        _ = fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
        return isDirectory.boolValue
    }
}

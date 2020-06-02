//
//  ResourceManager.swift
//  KingLoader
//
//  Created by Purkylin King on 2020/5/30.
//  Copyright © 2020 Purkylin King. All rights reserved.
//

import Foundation
import Compression

class ResourceManager {
    static let shared = ResourceManager()
    
    private let cacheQueue = DispatchQueue(label: "generate_tgs_cache")
    
    private init() {
        try? FileManager.default.createDirectory(at: tgsThumbDirectory, withIntermediateDirectories: true, attributes: nil)
        try? FileManager.default.createDirectory(at: tgsRawDirectory, withIntermediateDirectories: true, attributes: nil)
        print(tgsThumbDirectory.path)
    }
    
    private var downloadDirectory: URL {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return url.appendingPathComponent("download")
    }
    
    private var tgsThumbDirectory: URL {
        return downloadDirectory.appendingPathComponent("thumb")
    }
    
    private var tgsRawDirectory: URL {
        return downloadDirectory.appendingPathComponent("raw")
    }
    
    public func cachePath(for url: URL) -> URL {
        if url.isFileURL {
            return url
        } else {
            return tgsRawDirectory.appendingPathComponent(url.path.md5())
        }
    }
    
    public func clearCache() {
        try? FileManager.default.removeItem(at: tgsRawDirectory)
        try? FileManager.default.removeItem(at: tgsThumbDirectory)
        
        try? FileManager.default.createDirectory(at: tgsThumbDirectory, withIntermediateDirectories: true, attributes: nil)
        try? FileManager.default.createDirectory(at: tgsRawDirectory, withIntermediateDirectories: true, attributes: nil)
    }
    
    public func cacheThumbPath(for url: URL, size: CGSize, scale: CGFloat = UIScreen.main.scale) -> URL {
        let file = cachePath(for: url)
        let w = Int(size.width) * Int(scale)
        let h = Int(size.height) * Int(scale)
        let fileName = "sticker_\(file.lastPathComponent)_\(w)x\(h)"
        return tgsThumbDirectory.appendingPathComponent(fileName)
    }
    
    public func hasDownloaded(for url: URL) -> Bool {
        let file = cachePath(for: url)
        return FileManager.default.fileExists(atPath: file.path)
    }
    
    public func hasThumb(for url: URL, size: CGSize) -> Bool {
        let file = cacheThumbPath(for: url, size: size)
        return FileManager.default.fileExists(atPath: file.path)
    }
    
    public func generateThumb(for data: Data, size: CGSize, path: String, completion: @escaping () -> Void) {
        cacheQueue.async {
            generateStickerCache(data: data, size: size, filePath: path)
            completion()
        }
    }
    
    public func loadFile(url: URL, completion: @escaping (Data?) -> Void) {
//        assertNotMainThread()
        
        if hasDownloaded(for: url) {
            let data = try! Data(contentsOf: cachePath(for: url))
            completion(data)
            return
        }
        
        let savePath = cachePath(for: url)
        // httpMaximumConnectionsPerHost, default value: 6
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let response = response as? HTTPURLResponse, response.statusCode == 200, let data = data {
                print("download ok")
                try! data.write(to: savePath)
                completion(data)
            } else {
                completion(nil)
            }
        }

        task.resume()
    }
}

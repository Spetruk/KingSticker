//
//  ResourceManager.swift
//  KingLoader
//
//  Created by Purkylin King on 2020/5/30.
//  Copyright © 2020 Purkylin King. All rights reserved.
//

import Foundation
import Compression

public class ResourceManager {
    public static let shared = ResourceManager()
    
    private let queue = DispatchQueue(label: "task")
    
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: configuration)
        return session
    }()
    
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
        queue.async {
            generateStickerCache(data: data, size: size, filePath: path)
            slog("finish generating a thumb for sticker")
            completion()
        }
    }
    
    public func cacheData(for url: URL) -> Data? {
        if !hasDownloaded(for: url) {
            return nil
        }
        
        let file = cachePath(for: url)
        return try? Data(contentsOf: file)
    }
    
    public func loadFile(url: URL, completion: @escaping (Data?) -> Void) {
        func task() {
            if hasDownloaded(for: url) {
                let data = try! Data(contentsOf: cachePath(for: url))
                completion(data)
                return
            }
            
            let savePath = cachePath(for: url)
            DownloadManager.shared.download(url: url, to: savePath, completion: completion)
        }
        
        queue.async {
            task()
        }
    }
}

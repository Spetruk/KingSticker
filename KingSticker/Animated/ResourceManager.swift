//
//  ResourceManager.swift
//  KingSticker
//
//  Copyright © 2020 Purkylin King
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

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
        slog("clear cache")
        
        DownloadManager.shared.cancelAllTasks()
        
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

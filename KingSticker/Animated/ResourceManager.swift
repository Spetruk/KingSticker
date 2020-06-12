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

class DownloadTask {
    typealias Callback = (Data?) -> Void
    
    private var key: String
    private var _task: URLSessionDataTask
    private var callbacks : [Callback]
    
    init(url: URL, task: URLSessionDataTask, completion: @escaping Callback) {
        self.key = url.path
        self._task = task
        self.callbacks = [completion]
    }
    
    func add(callback: @escaping Callback) {
        callbacks.append(callback)
    }
    
    func notify(data: Data?) {
        for callback in callbacks {
            callback(data)
        }
    }
    
    func resume() {
        _task.resume()
    }
    
    func cancel() {
        _task.cancel()
    }
}

class DownloadManager {
    static let shared = DownloadManager()
    
    private let maxConcurrentTasks = 6
    private let queue = DispatchQueue(label: "download", qos: .background)
    private let semaphore: DispatchSemaphore
    
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpMaximumConnectionsPerHost = 6
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 15
        let session = URLSession(configuration: configuration)
        return session
    }()
    
    private var taskDict: [URL : DownloadTask] = [:]
    
    private init() {
        semaphore = DispatchSemaphore(value: maxConcurrentTasks)
    }
    
    /// Download file
    func download(url: URL, to position: URL, completion: @escaping (Data?) -> Void) {
        func createTask() -> DownloadTask {
            print("schedule a task")
            let task = self.session.dataTask(with: url) { [weak self] (data, response, error) in
                if let response = response as? HTTPURLResponse, response.statusCode == 200, let data = data, data.count > 0 {
                    print("success a download task")
                    try! data.write(to: position)
                    completion(data)
                } else {
                    print("fail a download task")
                    completion(nil)
                }
                
                self?.taskDict.removeValue(forKey: url)
                self?.semaphore.signal()
            }
            
            return DownloadTask(url: url, task: task, completion: completion)
        }
        
        func run() {
            semaphore.wait()
            
            // Check again whether downloaded
            if let data = ResourceManager.shared.cacheData(for: url) {
                completion(data)
                semaphore.signal()
                return
            }

            if let task = taskDict[url] {
                // Already exists
                task.add(callback: completion)
            } else {
                let newTask = createTask()
                taskDict[url] = newTask
                newTask.resume()
            }
        }

        queue.async {
            run()
        }
    }
    
    /// Cancel all tasks
    func cancelAllTasks() {
        taskDict.forEach { (_, task) in
            task.cancel()
        }

        taskDict.removeAll()
    }
    
    /// Get the count of tasks in active
    func taskCount() -> Int {
        return taskDict.count
    }
}

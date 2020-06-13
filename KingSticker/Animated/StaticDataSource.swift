//
//  StaticDataSource.swift
//  KingSticker
//
//  Created by Purkylin King on 2020/6/13.
//  Copyright © 2020 Purkylin King. All rights reserved.
//

import Foundation

/// Static image data source
public class StaticDataSource: AnimatedDataSource {
    var url: URL
    
    public var frameCount: Int {
        return 1
    }
    
    public var frameRate: Int {
        return 60
    }
    
    public var isReady: Bool
    
    public init(url: URL) {
        self.url = url
        self.isReady = false
    }
    
    var cachedFrame: AnimatedFrame? = nil
    
    public func takeFrame() -> AnimatedFrame? {
        return cachedFrame
    }
    
    public func ready(size: CGSize, completion: @escaping (Bool) -> Void) {
        self.isReady = false
        let manager = ResourceManager.shared
        if manager.hasDownloaded(for: url) {
            self.updateData(success: true, completion: completion)
        } else {
            manager.loadFile(url: url) { [weak self] data in
                DispatchQueue.main.async {
                    self?.updateData(success: true, completion: completion)
                }
            }
        }
    }
    
    private func updateData(success: Bool, completion: (Bool) -> Void) {
        if success, let data = ResourceManager.shared.cacheData(for: url), let image = UIImage(data: data)  {
            self.cachedFrame = AnimatedFrame(image: image, duration: 1.0)
            isReady = true
            completion(true)
        } else {
            isReady = false
            completion(false)
        }
    }
}

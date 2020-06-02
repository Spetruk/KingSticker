//
//  GifDataSource.swift
//  KingLoader
//
//  Created by Purkylin King on 2020/6/2.
//  Copyright © 2020 Purkylin King. All rights reserved.
//

import Foundation

class GifDataSource: AnimatedDataSource {
    private var frames: [AnimatedFrame] = []
    private var currentIndex = 0
    private var preferredSize: CGSize = .zero
    private let url: URL
    private var showFirstFrame: Bool = false
    var isReady: Bool = true

    
    init(url: URL, firstFrame: Bool = false) {
        self.url = url
        self.showFirstFrame = firstFrame
    }
    
    var frameCount: Int = 0
    var frameRate: Int = 60
    
    func takeFrame() -> AnimatedFrame? {
        guard isReady else { fatalError("not ready") }
        guard frameCount > 0 && currentIndex < self.frameCount else { fatalError() }
        defer {
            currentIndex = (currentIndex + 1) % self.frameCount
        }
        
        return frames[currentIndex]
    }
    
    func ready(size: CGSize, completion: @escaping (Bool) -> Void) {
        self.isReady = false
        let manager = ResourceManager.shared
        if manager.hasDownloaded(for: url) {
            self.updateData(success: true, completion: completion)
        } else {
            manager.loadFile(url: url) { [weak self] data in
                self?.updateData(success: true, completion: completion)
            }
        }
    }
    
    func parseFrames() -> Bool {
        let cacheUrl = ResourceManager.shared.cachePath(for: self.url)
        if let data = try? Data(contentsOf: cacheUrl), data.count > 0 {
            if let frames = GifDecoder.decode(from: data, firstFrame: self.showFirstFrame, preferredSize: preferredSize) {
                frameCount = frames.count
                self.frames = frames
                return true
            }
        }
        
        return false
    }
    
    private func updateData(success: Bool, completion: (Bool) -> Void) {
        if success && parseFrames() {
            isReady = true
            completion(true)
        } else {
            isReady = false
            completion(false)
        }
    }
}

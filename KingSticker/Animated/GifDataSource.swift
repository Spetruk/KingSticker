//
//  GifDataSource.swift
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

public class GifDataSource: AnimatedDataSource {
    private var frames: [AnimatedFrame] = []
    private var currentIndex = 0
    private var preferredSize: CGSize = .zero
    public var url: URL
    private var showFirstFrame: Bool = false
    

    public init(url: URL, firstFrame: Bool = false) {
        self.url = url
        self.showFirstFrame = firstFrame
    }
    
    public var frameCount: Int = 0
    public var frameRate: Int = 60
    public var isReady: Bool = true
    
    public func takeFrame() -> AnimatedFrame? {
        guard isReady else { fatalError("not ready") }
        guard frameCount > 0 && currentIndex < self.frameCount else { fatalError() }
        defer {
            currentIndex = (currentIndex + 1) % self.frameCount
        }
        
        return frames[currentIndex]
    }
    
    public func ready(size: CGSize, completion: @escaping (Bool) -> Void) {
        assertMainThread()
        
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
        assertMainThread()
        
        if success && parseFrames() {
            isReady = true
            completion(true)
        } else {
            isReady = false
            completion(false)
        }
    }
}

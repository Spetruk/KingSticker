//
//  AnimatedView.swift
//  KingLoader
//
//  Created by Purkylin King on 2020/5/30.
//  Copyright © 2020 Purkylin King. All rights reserved.
//

import UIKit

protocol AnimatedDataSource {
    var frameCount: Int { get }
    var frameRate: Int { get }
    
    func takeFrame() -> AnimatedFrame
}

class AnimatedView: UIImageView {
    private lazy var timer: CADisplayLink = {
        let displayLink = CADisplayLink(target: self, selector: #selector(onTimer))
        displayLink.preferredFramesPerSecond = 60
        displayLink.isPaused = true
        displayLink.add(to: .main, forMode: .common)

        return displayLink
    }()
    
    private var dataSource: AnimatedDataSource?
    private var timeSinceLastFrameChange: TimeInterval = 0.0
    private var currentFrame: AnimatedFrame?
    
    private func reset() {
        self.currentFrame = nil
        self.timeSinceLastFrameChange = 0.0
        self.timer.isPaused = true
    }
    
    @objc func onTimer() {
        if shouldChangedFrame() {
            render()
        }
    }
    
    func render() {
        guard let dataSource = self.dataSource else { return }
        self.currentFrame = dataSource.takeFrame()
        self.image = currentFrame!.image
    }
    
    public func setImage(dataSource: AnimatedDataSource) {
        reset()
        self.dataSource = dataSource
        timer.isPaused = false
    }
}

extension AnimatedView {
    func shouldChangedFrame() -> Bool {
        if let frame = self.currentFrame {
            if timeSinceLastFrameChange + timer.duration >= frame.duration {
                timeSinceLastFrameChange = 0.0
                return true
            } else {
                timeSinceLastFrameChange += timer.duration
                return false
            }
        } else {
            return true
        }
    }
}

class GifDataSource: AnimatedDataSource {
    private var frames: [AnimatedFrame] = []
    private var currentIndex = 0
    private var preferredSize: CGSize
    
    init(url: URL, firstFrame: Bool, preferredSize: CGSize) {
        self.preferredSize = preferredSize
        let data = try! Data(contentsOf: url)
        if let frames = GifDecoder.decode(from: data, firstFrame: firstFrame, preferredSize: preferredSize) {
            frameCount = frames.count
            self.frames = frames
        }
    }
    
    var frameCount: Int = 0
    
    var frameRate: Int = 60
    
    func takeFrame() -> AnimatedFrame {
        guard frameCount > 0 && currentIndex < self.frameCount else { fatalError() }
        defer {
            currentIndex = (currentIndex + 1) % self.frameCount
        }
        
        return frames[currentIndex]
    }
}

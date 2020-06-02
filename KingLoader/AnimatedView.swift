//
//  AnimatedView.swift
//  KingLoader
//
//  Created by Purkylin King on 2020/5/30.
//  Copyright © 2020 Purkylin King. All rights reserved.
//

import UIKit

public protocol AnimatedDataSource {
    var frameCount: Int { get }
    var frameRate: Int { get }
    var isReady: Bool { get }
    
    func takeFrame() -> AnimatedFrame?
    func ready(size: CGSize, completion: @escaping (Bool) -> Void)
}

public struct AnimationViewOptions: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    /// Only show first frame
    static let firstFrame = AnimationViewOptions(rawValue: 1 << 0)
}

private let queue = DispatchQueue(label: "AnimatedView")

public class AnimatedView: UIImageView {
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
    private var showFirstFrame: Bool = false // only show first frame
    
    deinit {
        print("deinit AnimatedView")
    }
    
    private func reset() {
        self.currentFrame = nil
        self.timeSinceLastFrameChange = 0.0
        self.timer.isPaused = true
    }
    
    @objc private func onTimer() {
        if shouldChangedFrame() {
            render()
        }
    }
    
    private func render() {
        guard let dataSource = self.dataSource else { return }
        
        queue.async { [weak self] in
            if dataSource.isReady, let strongSelf = self, let frame = strongSelf.dataSource?.takeFrame() {
                strongSelf.currentFrame = frame
                DispatchQueue.main.async {
                    strongSelf.layer.contents = frame.image.cgImage
                }
            }
        }
    }
    
    /// Set datasource
    public func setImage(dataSource: AnimatedDataSource, size: CGSize = CGSize(width: 60, height: 60), options: [AnimationViewOptions] = []) {
        self.reset()
        self.dataSource = dataSource
        self.showFirstFrame = options.contains(.firstFrame)
        
        dataSource.ready(size: size) { [weak self] success in
            guard let strongSelf = self else { return }
            if success {
                if strongSelf.showFirstFrame {
                    strongSelf.render()
                } else {
                    strongSelf.timer.isPaused = false
                }
            }
        }
    }
    
    /// Pause animation
    public func pause() {
        guard !showFirstFrame else { return }
        self.timer.isPaused = true
    }
    
    /// Resume animation
    public func resume() {
        guard !showFirstFrame else { return }
        self.timer.isPaused = false
    }
}

extension AnimatedView {
    private func shouldChangedFrame() -> Bool {
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

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

public class AnimatedView: UIImageView {
    private weak var timer: CADisplayLinkProxy?
    
    private var dataSource: AnimatedDataSource?
    private var timeSinceLastFrameChange: TimeInterval = 0.0
    private var currentFrame: AnimatedFrame?
    private var showFirstFrame: Bool = false // only show first frame
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupDisplayLink()
    }
    
    public init() {
        super.init(frame: .zero)
        self.setupDisplayLink()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("deinit AnimatedView")
        timer?.invalidate()
    }
    
    private func setupDisplayLink() {
        self.timer = CADisplayLinkProxy(handle: { [weak self] in
            self?.onTimer()
        })
    }
    
    private func reset() {
        self.currentFrame = nil
        self.timeSinceLastFrameChange = 0.0
        self.timer?.isPaused = true
    }
    
    @objc private func onTimer() {
        if shouldChangedFrame() {
            DispatchQueue.main.async { [weak self] in
                self?.render()
            }
        }
    }
    
    private func render() {
        assertMainThread()
        guard let dataSource = self.dataSource else { return }
        
        if dataSource.isReady, let frame = dataSource.takeFrame() {
            self.currentFrame = frame
            self.image = frame.image
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
                    strongSelf.timer?.isPaused = false
                }
            }
        }
    }
    
    /// Pause animation
    public func pause() {
        guard !showFirstFrame else { return }
        self.timer?.isPaused = true
    }
    
    /// Resume animation
    public func resume() {
        guard !showFirstFrame else { return }
        self.timer?.isPaused = false
    }
}

extension AnimatedView {
    private func shouldChangedFrame() -> Bool {
        if let frame = self.currentFrame, let timer = self.timer {
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

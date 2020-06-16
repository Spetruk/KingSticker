//
//  AnimatedView.swift
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

import UIKit

public protocol AnimatedDataSource {
    var url: URL { get }
    
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
    public static let firstFrame = AnimationViewOptions(rawValue: 1 << 0)
}

public class AnimatedView: UIImageView {
    private weak var timer: CADisplayLinkProxy?
    
    private var dataSource: AnimatedDataSource?
    private var timeSinceLastFrameChange: TimeInterval = 0.0
    private var currentFrame: AnimatedFrame?
    private var showFirstFrame: Bool = false // only show first frame
    
    private var hasCachedFirstFrame = false
    
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
        slog("deinit AnimatedView")
        timer?.invalidate()
    }
    
    private func setupDisplayLink() {
        self.timer = CADisplayLinkProxy(handle: { [weak self] in
            self?.onTimer()
        })
    }
    
    private func reset() {
        self.image = nil
        self.currentFrame = nil
        self.timeSinceLastFrameChange = 0.0
        self.timer?.isPaused = true
        self.hasCachedFirstFrame = false
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
        
        if self.image == nil {
            self.image = MemoryCache.shared.value(for: dataSource.url)
            if self.image != nil {
                slog("hit")
            }
        }
        
        if dataSource.isReady, let frame = dataSource.takeFrame() {
            self.currentFrame = frame
            self.image = frame.image
            
            if !hasCachedFirstFrame {
                MemoryCache.shared.update(value: frame.image, for: dataSource.url)
                hasCachedFirstFrame = true
            }
        }
    }
    
    /// Set datasource
    public func setImage(dataSource: AnimatedDataSource, size: CGSize = CGSize(width: 60, height: 60), options: [AnimationViewOptions] = []) {
        self.reset()
        self.dataSource = dataSource
        self.showFirstFrame = options.contains(.firstFrame)
        
        render()
        
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

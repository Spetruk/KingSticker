//
//  CADisplayLinkProxy.swift
//  KingLoader
//
//  Created by Purkylin King on 2020/6/3.
//  Copyright © 2020 Purkylin King. All rights reserved.
//

import UIKit

class CADisplayLinkProxy {
    var displaylink: CADisplayLink?
    var handle: (() -> Void)?
    
    var isPaused: Bool = false {
        didSet {
            displaylink?.isPaused = self.isPaused
        }
    }
    
    var duration: TimeInterval {
        return displaylink?.duration ?? 0
    }
    
    init(handle: (() -> Void)?) {
        self.handle = handle
        self.displaylink = CADisplayLink(target: self, selector: #selector(updateHandle))
        self.displaylink?.add(to: RunLoop.current, forMode: .common)
    }
    
    @objc func updateHandle() {
        handle?()
    }
    
    func invalidate() {
        displaylink?.remove(from: RunLoop.current, forMode: .common)
        displaylink?.invalidate()
        displaylink = nil
    }
}

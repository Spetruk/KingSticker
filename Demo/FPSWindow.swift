//
//  FPSWindow.swift
//  KingLoader
//
//  Created by Purkylin King on 2020/6/3.
//  Copyright © 2020 Purkylin King. All rights reserved.
//

import UIKit
import KingSticker

private let radius: CGFloat = 24
private let edge : CGFloat = 1

final class FPSViewController: UIViewController {
    private let floatView = UIView()
    private let fpsLabel = UILabel()
    
    private var count = 0
    private var timestamp: CFTimeInterval = 0
    private var initialCenter: CGPoint = .zero
    
    private lazy var displayLink: CADisplayLink = {
        let displayLink = CADisplayLink(target: self, selector: #selector(onTimer))
        return displayLink
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        displayLink.add(to: .main, forMode: .common)
    }
    
    func setupViews() {
        view.frame = CGRect(x: 0, y: 0, width: radius * 2, height: radius * 2)
        view.backgroundColor = .clear
        view.addSubview(floatView)
        floatView.frame = view.frame
        
        floatView.addSubview(fpsLabel)
        fpsLabel.frame = floatView.bounds
        fpsLabel.textColor = .red
        fpsLabel.textAlignment = .center
    }
    
    @objc func onTimer() {
        count += 1
        let now = displayLink.timestamp
        let interval = now - timestamp
        
        if interval > 1.0 {
            let fps = Int(ceil(Double(count) / interval))
            updateFrameRate(value: fps)
            
            // reset
            self.timestamp = now
            self.count = 0
        }
    }
    
    func updateFrameRate(value: Int) {
        self.fpsLabel.text = "\(value)"
    }
}

class FPSWindow: UIWindow {
    private static let shared = FPSWindow()
    
    private var initialCenter: CGPoint = .zero
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(onDrag))
        self.addGestureRecognizer(pan)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap))
        self.addGestureRecognizer(tap)
    }
    
    @objc func onTap(_ gestureRecognizer: UITapGestureRecognizer) {
        print("tap")
//        let alert = UIAlertController(title: "DebugPanel", message: nil, preferredStyle: .actionSheet)
//        alert.addAction(UIAlertAction(title: "aaa", style: .cancel, handler: nil))
//        if let vc = topMostViewController() {
//            vc.present(alert, animated: true, completion: nil)
//        }
        
        if let vc = topMostViewController() {
            let alert = UIAlertController(title: "Tool", message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Clear Cache", style: .destructive, handler: { _ in
                ResourceManager.shared.clearCache()
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    @objc func onDrag(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard gestureRecognizer.view != nil else { return }
        
        let target = gestureRecognizer.view!
        let translation = gestureRecognizer.translation(in: target)
        if gestureRecognizer.state == .began {
            self.initialCenter = target.center
        }
        
        let newCenter = CGPoint(x: initialCenter.x + translation.x, y: initialCenter.y + translation.y)
        
        if gestureRecognizer.state == .ended {
            ensureSafeArea(for: newCenter)
            return
        }
        
        if gestureRecognizer.state != .cancelled {
            target.center = newCenter
        } else {
            target.center = initialCenter
        }
    }
    
    func ensureSafeArea(for point: CGPoint) {
        let screenSize = UIScreen.main.bounds.size
        var topPadding: CGFloat = 0
        var bottomPadding: CGFloat = 0
        
        if #available(iOS 11.0, *) {
            let window = UIApplication.shared.keyWindow!
            topPadding = window.safeAreaInsets.top
            bottomPadding = window.safeAreaInsets.bottom
        }
        
        var x = point.x
        var y = point.y
        
        let top = topPadding + edge
        let bottom = screenSize.height - bottomPadding - edge
        
        if y < top {
            y = radius + top
            
            if x < radius + edge {
                x = radius + edge
            }
            
            if x > screenSize.width - radius - edge {
                x = screenSize.width - radius - edge
            }
        } else if y < bottom {
            if x < screenSize.width / 2 {
                x = radius + edge
            } else {
                x = screenSize.width - radius - edge
            }
        } else {
            y = bottom - radius
            
            if x < radius + edge {
                x = radius + edge
            }
            
            if x > screenSize.width - radius - edge {
                x = screenSize.width - radius - edge
            }
        }
        
        let newCenter = CGPoint(x: x, y: y)
        let length = distance(p1: point, p2: newCenter)
        let time = length / max(screenSize.width, screenSize.height)
        UIView.animate(withDuration: Double(time)) {
            self.center = newCenter
        }
    }
    
    private func distance(p1: CGPoint, p2: CGPoint) -> CGFloat {
        let tmp = (p1.x - p2.x) * (p1.x - p2.x) + (p1.y - p2.y) * (p1.y - p2.y)
        return sqrt(tmp)
    }
    
    
    static func show() {
        let screenSize = UIScreen.main.bounds
        let initialPosition = CGPoint(x: screenSize.width - radius, y: screenSize.height / 2)
        
        let window = FPSWindow.shared
        window.frame = CGRect(x: initialPosition.x, y: initialPosition.y, width: radius * 2, height: radius * 2)
        window.rootViewController = FPSViewController()
        window.windowLevel = .alert
        window.isHidden = false
        window.layer.cornerRadius = radius
        window.layer.masksToBounds = true
    }
}

func topMostViewController() -> UIViewController? {
    let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
    
    if var topController = keyWindow?.rootViewController {
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        
        return topController
    }
    
    return nil
}

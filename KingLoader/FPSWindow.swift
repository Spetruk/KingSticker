//
//  FPSWindow.swift
//  KingLoader
//
//  Created by Purkylin King on 2020/6/3.
//  Copyright © 2020 Purkylin King. All rights reserved.
//

import UIKit

private let radius: CGFloat = 30

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
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(onDrag))
        self.addGestureRecognizer(gesture)
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
        
        var x = point.x
        var y = point.y
        
        // left
        if x < radius {
            x = radius
        }
        
        // right
        if x > screenSize.width - radius {
            x = screenSize.width - radius
        }
        
        // top
        if y < radius {
            y = radius + 44
        }
        
        // bottom
        if y > screenSize.height - radius {
            y = screenSize.height - radius - 44
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

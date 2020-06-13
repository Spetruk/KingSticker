//
//  AutoDataSource.swift
//  KingSticker
//
//  Created by Purkylin King on 2020/6/13.
//  Copyright © 2020 Purkylin King. All rights reserved.
//

import Foundation

/// Auto create data source according filename extension
public class AutoDataSource: AnimatedDataSource {
    public var frameCount: Int {
        return _dataSource.frameCount
    }
    
    public var frameRate: Int {
        return _dataSource.frameRate
    }
    
    public var isReady: Bool {
        return _dataSource.isReady
    }
    
    private let _dataSource: AnimatedDataSource
    
    public func takeFrame() -> AnimatedFrame? {
        return _dataSource.takeFrame()
    }
    
    public func ready(size: CGSize, completion: @escaping (Bool) -> Void) {
        _dataSource.ready(size: size, completion: completion)
    }
    
    public init(url: URL) {
        if url.path.hasSuffix("tgs") || url.path.hasSuffix("json") {
            self._dataSource = LottieDataSource(url: url)
        } else if url.path.hasSuffix("gif") {
            self._dataSource = GifDataSource(url: url, firstFrame: false)
        } else {
            self._dataSource = StaticDataSource(url: url)
            fatalError("Not valid url")
        }
    }
}

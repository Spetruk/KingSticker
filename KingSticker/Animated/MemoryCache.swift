//
//  MemoryCache.swift
//  KingSticker
//
//  Created by Purkylin King on 2020/6/13.
//  Copyright © 2020 Purkylin King. All rights reserved.
//

import UIKit

class MemoryCache {
    static let shared = MemoryCache()
    
    private let cache = NSCache<NSURL, UIImage>()
    
    private init() {
        cache.countLimit = 100
    }
    
    func value(for key: URL) -> UIImage? {
        return cache.object(forKey: key as NSURL)
    }
    
    func update(value: UIImage, for key: URL) {
        cache.setObject(value, forKey: key as NSURL)
    }
}

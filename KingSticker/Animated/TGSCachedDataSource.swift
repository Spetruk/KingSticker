//
//  TGSCachedDataSource.swift
//  KingLoader
//
//  Created by Purkylin King on 2020/5/30.
//  Copyright © 2020 Purkylin King. All rights reserved.
//

import Foundation
import Compression

private let queue = DispatchQueue(label: "datasource")

public final class TGSCachedFrameSource: AnimatedDataSource {
    public var frameRate: Int = 0
    public var frameCount: Int = 0
    var width: Int = 0
    var bytesPerRow: Int = 0
    public var height: Int = 0
    public var isReady: Bool
    
    var url: URL
    
    var dataComplete = true // not useful
    
    private var expectedSize: CGSize = .zero
    
    private var frameIndex: Int = 0
    private var initialOffset: Int = 0
    private var offset: Int = 0
    
    private var decodeBuffer: Data!
    private var frameBuffer: Data!
    private var data: Data!
    private var scratchBuffer: Data!
    
    var duration: TimeInterval {
        return 1.0 / Double(frameRate)
    }
    
    public init(url: URL) {
        self.url = url
        self.isReady = false
    }
    
    public func ready(size: CGSize, completion: @escaping (Bool) -> Void) {
        self.expectedSize = size
        let manager = ResourceManager.shared
        if manager.hasDownloaded(for: url) {
            cacheThumbIfNeed(size: size, completion: completion)
        } else {
            manager.loadFile(url: url) { [weak self] data in
                if let data = data {
                    self?.cacheThumb(data: data, size: size, completion: completion)
                } else {
                    self?.updateData(success: false, completion: completion)
                }
            }
        }
    }
    
    private func cacheThumb(data: Data, size: CGSize, completion: @escaping (Bool) -> Void) {
        let cacheUrl = ResourceManager.shared.cacheThumbPath(for: self.url, size: size)
        ResourceManager.shared.generateThumb(for: data, size: size, path: cacheUrl.path) { [weak self] in
            self?.updateData(success: true, completion: completion)
        }
    }

    
    private func cacheThumbIfNeed(size: CGSize, completion: @escaping (Bool) -> Void) {
        let cacheUrl = ResourceManager.shared.cacheThumbPath(for: url, size: size)
        if FileManager.default.fileExists(atPath: cacheUrl.path) {
            self.updateData(success: true, completion: completion)
        } else {
            if let data = try? Data(contentsOf: url), data.count > 0 {
                cacheThumb(data: data, size: size, completion: completion)
            } else {
                updateData(success: false, completion: completion)
            }
        }
    }
    
    private func config(data: Data) {
        self.data = data
        self.scratchBuffer = Data(count: compression_decode_scratch_buffer_size(COMPRESSION_LZFSE))
        
        var offset = 0
        var width = 0
        var height = 0
        var bytesPerRow = 0
        var frameRate = 0
        var frameCount = 0
        
        if !self.data.withUnsafeBytes({ (bytes: UnsafePointer<UInt8>) -> Bool in
            var frameRateValue: Int32 = 0
            var frameCountValue: Int32 = 0
            var widthValue: Int32 = 0
            var heightValue: Int32 = 0
            var bytesPerRowValue: Int32 = 0
            memcpy(&frameRateValue, bytes.advanced(by: offset), 4)
            offset += 4
            memcpy(&frameCountValue, bytes.advanced(by: offset), 4)
            offset += 4
            memcpy(&widthValue, bytes.advanced(by: offset), 4)
            offset += 4
            memcpy(&heightValue, bytes.advanced(by: offset), 4)
            offset += 4
            memcpy(&bytesPerRowValue, bytes.advanced(by: offset), 4)
            offset += 4
            frameRate = Int(frameRateValue)
            frameCount = Int(frameCountValue)
            width = Int(widthValue)
            height = Int(heightValue)
            bytesPerRow = Int(bytesPerRowValue)
            
            return true
        }) {
            return
        }
        
        self.bytesPerRow = bytesPerRow
        
        self.width = width
        self.height = height
        self.frameRate = frameRate
        self.frameCount = frameCount
        
        self.frameIndex = 0
        self.initialOffset = offset
        self.offset = offset
        
        self.decodeBuffer = Data(count: self.bytesPerRow * height)
        self.frameBuffer = Data(count: self.bytesPerRow * height)
        let frameBufferLength = self.frameBuffer.count
        self.frameBuffer.withUnsafeMutableBytes { (bytes: UnsafeMutablePointer<UInt8>) -> Void in
            memset(bytes, 0, frameBufferLength)
        }
    }
    
    public func takeFrame() -> AnimatedFrame? {
        assertMainThread()
        guard isReady else { return nil }
        
        var frameData: Data?
        var isLastFrame = false
        
        let dataLength = self.data.count
        let decodeBufferLength = self.decodeBuffer.count
        let frameBufferLength = self.frameBuffer.count
        
        let frameIndex = self.frameIndex
        
        self.data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> Void in
            if self.offset + 4 > dataLength {
                if self.dataComplete {
                    self.frameIndex = 0
                    self.offset = self.initialOffset
                    self.frameBuffer.withUnsafeMutableBytes { (bytes: UnsafeMutablePointer<UInt8>) -> Void in
                        memset(bytes, 0, frameBufferLength)
                    }
                }
                return
            }
            
            var frameLength: Int32 = 0
            memcpy(&frameLength, bytes.advanced(by: self.offset), 4)
            
            if self.offset + 4 + Int(frameLength) > dataLength {
                return
            }
            
            self.offset += 4
            
            self.scratchBuffer.withUnsafeMutableBytes { (scratchBytes: UnsafeMutablePointer<UInt8>) -> Void in
                self.decodeBuffer.withUnsafeMutableBytes { (decodeBytes: UnsafeMutablePointer<UInt8>) -> Void in
                    self.frameBuffer.withUnsafeMutableBytes { (frameBytes: UnsafeMutablePointer<UInt8>) -> Void in
                        compression_decode_buffer(decodeBytes, decodeBufferLength, bytes.advanced(by: self.offset), Int(frameLength), UnsafeMutableRawPointer(scratchBytes), COMPRESSION_LZFSE)
                        
                        var lhs = UnsafeMutableRawPointer(frameBytes).assumingMemoryBound(to: UInt64.self)
                        var rhs = UnsafeRawPointer(decodeBytes).assumingMemoryBound(to: UInt64.self)
                        for _ in 0 ..< decodeBufferLength / 8 {
                            lhs.pointee = lhs.pointee ^ rhs.pointee
                            lhs = lhs.advanced(by: 1)
                            rhs = rhs.advanced(by: 1)
                        }
                        var lhsRest = UnsafeMutableRawPointer(frameBytes).assumingMemoryBound(to: UInt8.self).advanced(by: (decodeBufferLength / 8) * 8)
                        var rhsRest = UnsafeMutableRawPointer(decodeBytes).assumingMemoryBound(to: UInt8.self).advanced(by: (decodeBufferLength / 8) * 8)
                        for _ in (decodeBufferLength / 8) * 8 ..< decodeBufferLength {
                            lhsRest.pointee = rhsRest.pointee ^ lhsRest.pointee
                            lhsRest = lhsRest.advanced(by: 1)
                            rhsRest = rhsRest.advanced(by: 1)
                        }
                        
                        frameData = Data(bytes: frameBytes, count: decodeBufferLength)
                    }
                }
            }
            
            self.frameIndex += 1
            self.offset += Int(frameLength)
            if self.offset == dataLength && self.dataComplete {
                isLastFrame = true
                self.frameIndex = 0
                self.offset = self.initialOffset
                self.frameBuffer.withUnsafeMutableBytes { (bytes: UnsafeMutablePointer<UInt8>) -> Void in
                    memset(bytes, 0, frameBufferLength)
                }
            }
        }
        
        if let frameData = frameData {
            let image = AnimatedStickerFrame(data: frameData, type: .yuva, width: Int(expectedSize.width), height: Int(expectedSize.height), bytesPerRow: self.bytesPerRow, index: frameIndex, isLastFrame: isLastFrame).getImage()
            return AnimatedFrame(image: image, duration: duration)
        } else {
            return AnimatedFrame(image: UIImage(), duration: duration)
        }
    }
    
    func updateData(success: Bool, completion: @escaping (Bool) -> Void) {
        let cacheUrl = ResourceManager.shared.cacheThumbPath(for: self.url, size: self.expectedSize)
        if let data = try? Data(contentsOf: cacheUrl), data.count > 0 {
            queue.sync {
                self.config(data: data)
            }
            self.isReady = true
            completion(true)
        } else {
            self.isReady = false
            completion(false)
        }
    }
}

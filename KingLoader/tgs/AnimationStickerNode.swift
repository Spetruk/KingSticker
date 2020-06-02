import Foundation
import Compression
import RLottieBinding

private let sharedQueue = DispatchQueue.global()

final class AnimatedStickerFrame {
    let data: Data
    let type: AnimationRendererFrameType
    let width: Int
    let height: Int
    let bytesPerRow: Int
    let index: Int
    let isLastFrame: Bool
    
    init(data: Data, type: AnimationRendererFrameType, width: Int, height: Int, bytesPerRow: Int, index: Int, isLastFrame: Bool) {
        self.data = data
        self.type = type
        self.width = width
        self.height = height
        self.bytesPerRow = bytesPerRow
        self.index = index
        self.isLastFrame = isLastFrame
    }
    
    func getImage() -> UIImage {
        return softRender(width: width, height: height, bytesPerRow: bytesPerRow, data: data, type: type)!
    }
}

private protocol AnimatedStickerFrameSource: class {
    var frameRate: Int { get }
    var frameCount: Int { get }
    
    func takeFrame() -> AnimatedStickerFrame?
    func skipToEnd()
}

private final class AnimatedStickerFrameSourceWrapper {
    let value: AnimatedStickerFrameSource
    
    init(_ value: AnimatedStickerFrameSource) {
        self.value = value
    }
}

private final class AnimatedStickerCachedFrameSource: AnimatedStickerFrameSource {
    private let queue: DispatchQueue
    private var data: Data
    private var dataComplete: Bool
    private let notifyUpdated: () -> Void
    
    private var scratchBuffer: Data
    let width: Int
    let bytesPerRow: Int
    let height: Int
    let frameRate: Int
    let frameCount: Int
    private var frameIndex: Int
    private let initialOffset: Int
    private var offset: Int
    var decodeBuffer: Data
    var frameBuffer: Data
    
    init?(queue: DispatchQueue, data: Data, complete: Bool, notifyUpdated: @escaping () -> Void) {
        self.queue = queue
        self.data = data
        self.dataComplete = complete
        self.notifyUpdated = notifyUpdated
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
            return nil
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
    
    func takeFrame() -> AnimatedStickerFrame? {
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
            return AnimatedStickerFrame(data: frameData, type: .yuva, width: self.width, height: self.height, bytesPerRow: self.bytesPerRow, index: frameIndex, isLastFrame: isLastFrame)
        } else {
            return nil
        }
    }
    
    func updateData(data: Data, complete: Bool) {
        self.data = data
        self.dataComplete = complete
    }
    
    func skipToEnd() {
    }
}

private final class AnimatedStickerDirectFrameSource: AnimatedStickerFrameSource {
    private let queue: DispatchQueue
    private let data: Data
    private let width: Int
    private let height: Int
    private let bytesPerRow: Int
    let frameCount: Int
    let frameRate: Int
    private var currentFrame: Int
    private let animation: LottieInstance
    
    init?(queue: DispatchQueue, data: Data, width: Int, height: Int) {
        self.queue = queue
        self.data = data
        self.width = width
        self.height = height
        self.bytesPerRow = (4 * Int(width) + 15) & (~15)
        self.currentFrame = 0
        let rawData = TGGUnzipData(data, 8 * 1024 * 1024) ?? data
        guard let animation = LottieInstance(data: rawData, cacheKey: "") else {
            return nil
        }
        self.animation = animation
        self.frameCount = Int(animation.frameCount)
        self.frameRate = Int(animation.frameRate)
    }
    
    func takeFrame() -> AnimatedStickerFrame? {
        let frameIndex = self.currentFrame % self.frameCount
        self.currentFrame += 1
        var frameData = Data(count: self.bytesPerRow * self.height)
        frameData.withUnsafeMutableBytes { (bytes: UnsafeMutablePointer<UInt8>) -> Void in
            memset(bytes, 0, self.bytesPerRow * self.height)
            self.animation.renderFrame(with: Int32(frameIndex), into: bytes, width: Int32(self.width), height: Int32(self.height), bytesPerRow: Int32(self.bytesPerRow))
        }
        return AnimatedStickerFrame(data: frameData, type: .argb, width: self.width, height: self.height, bytesPerRow: self.bytesPerRow, index: frameIndex, isLastFrame: frameIndex == self.frameCount - 1)
    }
    
    func skipToEnd() {
        self.currentFrame = self.frameCount - 1
    }
}

//
//  StickerUtil.swift
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

import Foundation
import RLottieBinding
import Compression

private let queue = DispatchQueue(label: "generate thumb")

public func generateStickerCache(data: Data, size: CGSize, filePath: String) {
    let startTime = CACurrentMediaTime()
    var drawingTime: Double = 0
    var appendingTime: Double = 0
    var deltaTime: Double = 0
    var compressionTime: Double = 0
    
    let decompressedData: Data? = data // TGGUnzipData(data, 8 * 1024 * 1024)
    if let decompressedData = decompressedData {
        if let player = LottieInstance(data: decompressedData, cacheKey: "") {
            let endFrame = Int(player.frameCount)
            
            let bytesPerRow = (4 * Int(size.width) + 15) & (~15)
            
            var currentFrame: Int32 = 0
            
            guard let file = ManagedFile(queue: queue, path: filePath, mode: .readwrite) else {
                fatalError("open file failed")
            }
            
            func writeData(_ data: UnsafeRawPointer, length: Int) {
                file.write(data, count: length)
            }
            
            var numberOfFramesCommitted = 0
            
            var fps: Int32 = player.frameRate
            var frameCount: Int32 = player.frameCount
            writeData(&fps, length: 4)
            writeData(&frameCount, length: 4)
            var widthValue: Int32 = Int32(size.width)
            var heightValue: Int32 = Int32(size.height)
            var bytesPerRowValue: Int32 = Int32(bytesPerRow)
            writeData(&widthValue, length: 4)
            writeData(&heightValue, length: 4)
            writeData(&bytesPerRowValue, length: 4)
            
            let frameLength = bytesPerRow * Int(size.height)
            assert(frameLength % 16 == 0)
            
            let currentFrameData = malloc(frameLength)!
            memset(currentFrameData, 0, frameLength)
            
            let yuvaPixelsPerAlphaRow = (Int(size.width) + 1) & (~1)
            assert(yuvaPixelsPerAlphaRow % 2 == 0)
            
            let yuvaLength = Int(size.width) * Int(size.height) * 2 + yuvaPixelsPerAlphaRow * Int(size.height) / 2
            var yuvaFrameData = malloc(yuvaLength)!
            memset(yuvaFrameData, 0, yuvaLength)
            
            var previousYuvaFrameData = malloc(yuvaLength)!
            memset(previousYuvaFrameData, 0, yuvaLength)
            
            defer {
                free(currentFrameData)
                free(previousYuvaFrameData)
                free(yuvaFrameData)
            }
            
            var compressedFrameData = Data(count: frameLength)
            let compressedFrameDataLength = compressedFrameData.count
            
            let scratchData = malloc(compression_encode_scratch_buffer_size(COMPRESSION_LZFSE))!
            defer {
                free(scratchData)
            }
            
            while currentFrame < endFrame {
                let drawStartTime = CACurrentMediaTime()
                memset(currentFrameData, 0, frameLength)
                player.renderFrame(with: Int32(currentFrame), into: currentFrameData.assumingMemoryBound(to: UInt8.self), width: Int32(size.width), height: Int32(size.height), bytesPerRow: Int32(bytesPerRow))
                drawingTime += CACurrentMediaTime() - drawStartTime
                
                let appendStartTime = CACurrentMediaTime()
                
                // use yuva can reduce file/memory size
                encodeRGBAToYUVA(yuvaFrameData.assumingMemoryBound(to: UInt8.self), currentFrameData.assumingMemoryBound(to: UInt8.self), Int32(size.width), Int32(size.height), Int32(bytesPerRow))
                
                appendingTime += CACurrentMediaTime() - appendStartTime
                
                let deltaStartTime = CACurrentMediaTime()
                var lhs = previousYuvaFrameData.assumingMemoryBound(to: UInt64.self)
                var rhs = yuvaFrameData.assumingMemoryBound(to: UInt64.self)
                for _ in 0 ..< yuvaLength / 8 {
                    lhs.pointee = rhs.pointee ^ lhs.pointee
                    lhs = lhs.advanced(by: 1)
                    rhs = rhs.advanced(by: 1)
                }
                var lhsRest = previousYuvaFrameData.assumingMemoryBound(to: UInt8.self).advanced(by: (yuvaLength / 8) * 8)
                var rhsRest = yuvaFrameData.assumingMemoryBound(to: UInt8.self).advanced(by: (yuvaLength / 8) * 8)
                for _ in (yuvaLength / 8) * 8 ..< yuvaLength {
                    lhsRest.pointee = rhsRest.pointee ^ lhsRest.pointee
                    lhsRest = lhsRest.advanced(by: 1)
                    rhsRest = rhsRest.advanced(by: 1)
                }
                deltaTime += CACurrentMediaTime() - deltaStartTime
                
                let compressionStartTime = CACurrentMediaTime()
                compressedFrameData.withUnsafeMutableBytes { (bytes: UnsafeMutablePointer<UInt8>) -> Void in
                    let length = compression_encode_buffer(bytes, compressedFrameDataLength, previousYuvaFrameData.assumingMemoryBound(to: UInt8.self), yuvaLength, scratchData, COMPRESSION_LZFSE)
                    var frameLengthValue: Int32 = Int32(length)
                    writeData(&frameLengthValue, length: 4)
                    writeData(bytes, length: length)
                }
                
                let tmp = previousYuvaFrameData
                previousYuvaFrameData = yuvaFrameData
                yuvaFrameData = tmp
                
                compressionTime += CACurrentMediaTime() - compressionStartTime
                
                currentFrame += 1
                
                numberOfFramesCommitted += 1
                
                if numberOfFramesCommitted >= 5 {
                    numberOfFramesCommitted = 0
                }
            }
        }

    }
}


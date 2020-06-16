//
//  ImageUtil.swift
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

enum AnimationRendererFrameType {
    case argb
    case yuva
}

let deviceColorSpace: CGColorSpace = {
    if let colorSpace = CGColorSpace(name: CGColorSpace.displayP3) {
        return colorSpace
    } else {
        return CGColorSpaceCreateDeviceRGB()
    }
}()

func generateImagePixel(_ size: CGSize, scale: CGFloat, pixelGenerator: (CGSize, UnsafeMutablePointer<UInt8>, Int) -> Void) -> UIImage? {
    let scaledSize = CGSize(width: size.width * scale, height: size.height * scale)
    let bytesPerRow = (4 * Int(scaledSize.width) + 15) & (~15)
    let length = bytesPerRow * Int(scaledSize.height)
    let bytes = malloc(length)!.assumingMemoryBound(to: UInt8.self)
    guard let provider = CGDataProvider(dataInfo: bytes, data: bytes, size: length, releaseData: { bytes, _, _ in
        free(bytes)
    })
        else {
            return nil
    }
    
    pixelGenerator(scaledSize, bytes, bytesPerRow)
    
    let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
    
    guard let image = CGImage(width: Int(scaledSize.width), height: Int(scaledSize.height), bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: bytesPerRow, space: deviceColorSpace, bitmapInfo: bitmapInfo, provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
        else {
            return nil
    }
    
    return UIImage(cgImage: image, scale: scale, orientation: .up)
}

func softRender(width: Int, height: Int, bytesPerRow: Int, data: Data, type: AnimationRendererFrameType) -> UIImage? {
    
    let calculatedBytesPerRow = (4 * Int(width) + 15) & (~15)
    assert(bytesPerRow == calculatedBytesPerRow)
    
    let scale = UIScreen.main.scale
    let image = generateImagePixel(CGSize(width: CGFloat(width) / scale, height: CGFloat(height) / scale), scale: scale, pixelGenerator: { _, pixelData, bytesPerRow in
        switch type {
        case .yuva:
            data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> Void in
                decodeYUVAToRGBA(bytes, pixelData, Int32(width), Int32(height), Int32(bytesPerRow))
            }
        case .argb:
            data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> Void in
                memcpy(pixelData, bytes, data.count)
            }
        }
    })

    return image
}

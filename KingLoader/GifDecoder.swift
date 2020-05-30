//
//  GifDecoder.swift
//  KingLoader
//
//  Created by Purkylin King on 2020/5/30.
//  Copyright © 2020 Purkylin King. All rights reserved.
//

import UIKit
import ImageIO
import CoreServices

public struct AnimatedFrame {
    let image: UIImage
    let duration: TimeInterval
}

public class GifDecoder {
    public static func decode(from data: Data, firstFrame: Bool = false, preferredSize: CGSize = .zero) -> [AnimatedFrame]? {
        let options = [
            kCGImageSourceShouldCache as String : true,
            kCGImageSourceTypeIdentifierHint as String : kUTTypeGIF,
            ] as CFDictionary
        
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, options) else {
            debugPrint("Cannot create image source with data!")
            return nil
        }
        
        let framesCount = CGImageSourceGetCount(imageSource)
        var frameList = [AnimatedFrame]()
        
        for i in 0..<framesCount {
            guard let imageRef = CGImageSourceCreateImageAtIndex(imageSource, i, nil) else { return nil }
            let duration = getFrameDuration(from: imageSource, at: i)
            var image = UIImage(cgImage: imageRef)
            if preferredSize != .zero {
                image = image.resized(to: preferredSize)
            }
            let frame = AnimatedFrame(image: image, duration: duration)
            frameList.append(frame)
            
            if firstFrame {
                break
            }
        }
        
        return frameList
    }
    
    /// get frame duration time
    private static func getFrameDuration(from imageSource: CGImageSource, at index: Int) -> TimeInterval {
        guard let info = CGImageSourceCopyPropertiesAtIndex(imageSource, index, nil) as? [String : Any] else { return 0.0 }
        
        let defaultFrameDuration = 0.1
        guard let gifInfo = info[kCGImagePropertyGIFDictionary as String] as? [String : Any] else { return defaultFrameDuration }
        
        let unclampedDelayTime = gifInfo[kCGImagePropertyGIFUnclampedDelayTime as String] as? NSNumber
        let delayTime = gifInfo[kCGImagePropertyGIFDelayTime as String] as? NSNumber
        let duration = unclampedDelayTime ?? delayTime
        
        guard let frameDuration = duration else { return defaultFrameDuration }
        return frameDuration.doubleValue > 0.011 ? frameDuration.doubleValue : defaultFrameDuration
    }
}

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { (context) in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

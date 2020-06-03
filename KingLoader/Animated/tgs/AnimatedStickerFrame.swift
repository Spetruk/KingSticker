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

# KingSticker
Render tgs(zip)/lottie/gif file

## Motivation
When you want to show a screen of gif/tgs, will have poor performance using [Lottie](https://github.com/airbnb/lottie-ios). That repo has an [issue](https://github.com/SDWebImage/SDWebImageLottiePlugin/issues/1), so I extract some code from [Telegram](https://github.com/TelegramMessenger/Telegram-iOS).

## Feature
- [x] No external dependencies
- [x] Cache
- [x] Smooth

## Known issues
* High cpu about 150%
* Memory cahce not full implemented
* A little hot

## Usage

```Swift
import KingSticker

if url.path.hasSuffix("tgs") || url.path.hasSuffix("json") {
    let dataSource = TGSCachedFrameSource(url: url)
    imageView.setImage(dataSource: dataSource, options: [])
} else if url.path.hasSuffix("gif") {
    let dataSource = GifDataSource(url: url, firstFrame: false)
    imageView.setImage(dataSource: dataSource, options: [])
}
```

## Related projects
1. [SDWebImageLottieCoder](https://github.com/SDWebImage/SDWebImageLottieCoder)
2. [SDWebImageLottiePlugin](https://github.com/SDWebImage/SDWebImageLottiePlugin)

They are both backend by SDWebImage.

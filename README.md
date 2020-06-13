# KingSticker
Render tgs(zip)/lottie/gif file for iOS

## Motivation
When you want to show a screen of gif/tgs, will have poor performance using [Lottie](https://github.com/airbnb/lottie-ios). That repo has an [issue](https://github.com/SDWebImage/SDWebImageLottiePlugin/issues/1), so I extract some code from [Telegram](https://github.com/TelegramMessenger/Telegram-iOS).

## Feature
- [x] No external dependencies
- [x] Cache
- [x] Smooth

## Known issues
* High cpu about 150% when load more sticker in one screen
* Memory cache not full implemented
* A little hot

## Usage

```Swift
// Basic usage
import KingSticker
let imageView = AnimatedView()
let dataSource = AutoDataSource(url: url)
imageView.setImage(dataSource: dataSource)

// Advanced usage
let dataSource = GifDataSource(url: url, firstFrame: true)
imageView.setImage(dataSource: dataSource, options: [])
```

## Install(Carthage)

`github "purkylin/KingSticker"`

## Related projects
1. [SDWebImageLottieCoder](https://github.com/SDWebImage/SDWebImageLottieCoder)
2. [SDWebImageLottiePlugin](https://github.com/SDWebImage/SDWebImageLottiePlugin)

They are both backend by SDWebImage.

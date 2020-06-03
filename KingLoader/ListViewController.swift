//
//  ListViewController.swift
//  KingLoader
//
//  Created by Purkylin King on 2020/5/30.
//  Copyright © 2020 Purkylin King. All rights reserved.
//

import UIKit

class ListViewController: UIViewController {
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 60, height: 60)
        let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
        v.register(CustomCell.self, forCellWithReuseIdentifier: self.reuseIdentifier)
        v.dataSource = self
        v.delegate = self
        return v
    }()
    
    var stickers = [URL]()
    
    private let reuseIdentifier = "cell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        view.addSubview(collectionView)
        collectionView.frame = CGRect(origin: .zero, size: CGSize(width: view.bounds.width, height: view.bounds.height / 1))
        collectionView.backgroundColor = .white
        // ResourceManager.shared.clearCache()
        loadData()
    }
    
    func loadData() {
        let arr = [
            "https://secretapp.azureedge.net/emojitgs/secret1/01.gif",
            "https://secretapp.azureedge.net/emojitgs/secret1/02.gif",
            "https://secretapp.azureedge.net/emojitgs/secret1/03.gif",
            "https://secretapp.azureedge.net/emojitgs/secret1/04.gif",
            "https://secretapp.azureedge.net/emojitgs/secret1/05.gif",
            "https://secretapp.azureedge.net/emojitgs/secret1/06.gif",
            "https://secretapp.azureedge.net/emojitgs/secret1/07.gif",
            "https://secretapp.azureedge.net/emojitgs/secret1/08.gif",
            "https://secretapp.azureedge.net/emojitgs/secret1/09.gif",
            "https://secretapp.azureedge.net/emojitgs/secret1/10.gif",
            "https://secretapp.azureedge.net/emojitgs/secret1/11.gif",
            "https://secretapp.azureedge.net/emojitgs/secret1/12.gif",
            "https://secretapp.azureedge.net/emojitgs/secret21/13.gif",
            "https://secretapp.azureedge.net/emojitgs/secret21/14.gif",
            "https://secretapp.azureedge.net/emojitgs/secret21/15.gif",
            "https://secretapp.azureedge.net/emojitgs/secret1/16.gif",
            "https://secretapp.azureedge.net/emojitgs/secret1/17.gif",
            "https://secretapp.azureedge.net/emojitgs/secret1/18.gif",
            "https://secretapp.azureedge.net/emojitgs/secret1/19.gif",
            "https://secretapp.azureedge.net/emojitgs/secret1/20.gif",
            "https://secretapp.azureedge.net/emojitgs/secret1/21.gif",
            "https://secretapp.azureedge.net/emojitgs/secret1/22.gif",
            "https://secretapp.azureedge.net/emojitgs/secret1/23.gif",
            "https://secretapp.azureedge.net/emojitgs/secret1/24.gif",
            "https://secretapp.azureedge.net/emojitgs/secret1/25.gif",
            "https://secretapp.azureedge.net/emojitgs/secret1/26.gif",
            "https://secretapp.azureedge.net/emojitgs/Cat2O/2_1471004892762996770.tgs",
            "https://secretapp.azureedge.net/emojitgs/Cat2O/2_1471004892762996771.tgs",
            "https://secretapp.azureedge.net/emojitgs/Cat2O/2_1471004892762996772.tgs",
            "https://secretapp.azureedge.net/emojitgs/Cat2O/2_1471004892762996773.tgs",
            "https://secretapp.azureedge.net/emojitgs/Cat2O/2_1471004892762996774.tgs",
            "https://secretapp.azureedge.net/emojitgs/Cat2O/2_1471004892762996776.tgs",
            "https://secretapp.azureedge.net/emojitgs/Cat2O/2_1471004892762996777.tgs",
            "https://secretapp.azureedge.net/emojitgs/Cat2O/2_1471004892762996779.tgs",
            "https://secretapp.azureedge.net/emojitgs/Cat2O/2_1471004892762996780.tgs",
            "https://secretapp.azureedge.net/emojitgs/Cat2O/2_1471004892762996782.tgs",
            "https://secretapp.azureedge.net/emojitgs/Cat2O/2_1471004892762996783.tgs",
            "https://secretapp.azureedge.net/emojitgs/Cat2O/2_1471004892762996784.tgs",
            "https://secretapp.azureedge.net/emojitgs/Cat2O/2_1471004892762996785.tgs",
            "https://secretapp.azureedge.net/emojitgs/Cat2O/2_1471004892762996786.tgs",
            "https://secretapp.azureedge.net/emojitgs/Cat2O/2_1471004892762996787.tgs",
            "https://secretapp.azureedge.net/emojitgs/Cat2O/2_1471004892762996789.tgs",
            "https://secretapp.azureedge.net/emojitgs/Cat2O/2_1471004892762996799.tgs",
            "https://secretapp.azureedge.net/emojitgs/Cat2O/2_1471004892762996801.tgs",
            "https://secretapp.azureedge.net/emojitgs/Cat2O/2_1471004892762996804.tgs",
            "https://secretapp.azureedge.net/emojitgs/Cat2O/2_1471004892762996805.tgs",
            "https://secretapp.azureedge.net/emojitgs/Cat2O/2_1471004892762996807.tgs",
            "https://secretapp.azureedge.net/emojitgs/Cat2O/2_1471004892762996808.tgs",
            "https://secretapp.azureedge.net/emojitgs/Cat2O/2_1471004892762996809.tgs",
            "https://secretapp.azureedge.net/emojitgs/Cat2O/2_1471004892762996810.tgs",
            "https://secretapp.azureedge.net/emojitgs/Cat2O/2_1471004892762996811.tgs",
            "https://secretapp.azureedge.net/emojitgs/Cat2O/2_1903541432711381107.tgs",
            "https://secretapp.azureedge.net/emojitgs/CockAroundTheClock/2_1903541432711381108.tgs",
            "https://secretapp.azureedge.net/emojitgs/CockAroundTheClock/2_1903541432711381109.tgs",
            "https://secretapp.azureedge.net/emojitgs/CockAroundTheClock/2_1903541432711381110.tgs",
            "https://secretapp.azureedge.net/emojitgs/CockAroundTheClock/2_1903541432711381112.tgs",
            "https://secretapp.azureedge.net/emojitgs/CockAroundTheClock/2_1903541432711381113.tgs",
            "https://secretapp.azureedge.net/emojitgs/CockAroundTheClock/2_1903541432711381114.tgs",
            "https://secretapp.azureedge.net/emojitgs/CockAroundTheClock/2_1903541432711381115.tgs",
            "https://secretapp.azureedge.net/emojitgs/CockAroundTheClock/2_1903541432711381116.tgs",
            "https://secretapp.azureedge.net/emojitgs/CockAroundTheClock/2_1903541432711381117.tgs",
            "https://secretapp.azureedge.net/emojitgs/CockAroundTheClock/2_1903541432711381118.tgs",
            "https://secretapp.azureedge.net/emojitgs/CockAroundTheClock/2_1903541432711381119.tgs",
            "https://secretapp.azureedge.net/emojitgs/CockAroundTheClock/2_1903541432711381121.tgs",
            "https://secretapp.azureedge.net/emojitgs/CockAroundTheClock/2_1903541432711381122.tgs",
            "https://secretapp.azureedge.net/emojitgs/CockAroundTheClock/2_1903541432711381123.tgs",
            "https://secretapp.azureedge.net/emojitgs/CockAroundTheClock/2_1903541432711381133.tgs",
            "https://secretapp.azureedge.net/emojitgs/CockAroundTheClock/2_1903541432711381134.tgs",
            "https://secretapp.azureedge.net/emojitgs/CockAroundTheClock/2_1903541432711381135.tgs",
            "https://secretapp.azureedge.net/emojitgs/CockAroundTheClock/2_1903541432711381136.tgs",
            "https://secretapp.azureedge.net/emojitgs/CockAroundTheClock/2_1903541432711381137.tgs",
            "https://secretapp.azureedge.net/emojitgs/CockAroundTheClock/2_1903541432711381138.tgs",
            "https://secretapp.azureedge.net/emojitgs/CockAroundTheClock/2_1903541432711381139.tgs",
            "https://secretapp.azureedge.net/emojitgs/CockAroundTheClock/2_1903541432711381140.tgs",
            "https://secretapp.azureedge.net/emojitgs/CockAroundTheClock/2_1903541432711381141.tgs",
            "https://secretapp.azureedge.net/emojitgs/CockAroundTheClock/2_1903541432711381142.tgs",
            "https://secretapp.azureedge.net/emojitgs/CockAroundTheClock/2_1903541432711381156.tgs",
//            "https://secretapp.azureedge.net/emojitgs/DaisyRomashka/2_773947703670342031.tgs",
//            "https://secretapp.azureedge.net/emojitgs/DaisyRomashka/2_773947703670342033.tgs",
//            "https://secretapp.azureedge.net/emojitgs/DaisyRomashka/2_773947703670342034.tgs",
//            "https://secretapp.azureedge.net/emojitgs/DaisyRomashka/2_773947703670342035.tgs",
//            "https://secretapp.azureedge.net/emojitgs/DaisyRomashka/2_773947703670342037.tgs",
//            "https://secretapp.azureedge.net/emojitgs/DaisyRomashka/2_773947703670342038.tgs",
//            "https://secretapp.azureedge.net/emojitgs/DaisyRomashka/2_773947703670342040.tgs",
//            "https://secretapp.azureedge.net/emojitgs/DaisyRomashka/2_773947703670342041.tgs",
//            "https://secretapp.azureedge.net/emojitgs/DaisyRomashka/2_773947703670342042.tgs",
//            "https://secretapp.azureedge.net/emojitgs/DaisyRomashka/2_773947703670342045.tgs",
//            "https://secretapp.azureedge.net/emojitgs/DaisyRomashka/2_773947703670342046.tgs",
//            "https://secretapp.azureedge.net/emojitgs/DaisyRomashka/2_773947703670342050.tgs",
//            "https://secretapp.azureedge.net/emojitgs/DaisyRomashka/2_773947703670342051.tgs",
//            "https://secretapp.azureedge.net/emojitgs/DaisyRomashka/2_773947703670342052.tgs",
//            "https://secretapp.azureedge.net/emojitgs/DaisyRomashka/2_773947703670342053.tgs",
//            "https://secretapp.azureedge.net/emojitgs/DaisyRomashka/2_773947703670342054.tgs",
//            "https://secretapp.azureedge.net/emojitgs/DaisyRomashka/2_773947703670342055.tgs",
//            "https://secretapp.azureedge.net/emojitgs/DaisyRomashka/2_773947703670342057.tgs",
//            "https://secretapp.azureedge.net/emojitgs/DaisyRomashka/2_773947703670342058.tgs",
//            "https://secretapp.azureedge.net/emojitgs/DaisyRomashka/2_773947703670342060.tgs",
//            "https://secretapp.azureedge.net/emojitgs/DaisyRomashka/2_773947703670342061.tgs",
//            "https://secretapp.azureedge.net/emojitgs/DaisyRomashka/2_773947703670342062.tgs",
//            "https://secretapp.azureedge.net/emojitgs/DaisyRomashka/2_773947703670342063.tgs",
//            "https://secretapp.azureedge.net/emojitgs/DaisyRomashka/2_773947703670342064.tgs",
//            "https://secretapp.azureedge.net/emojitgs/DaisyRomashka/2_773947703670342066.tgs"
        ]
        
        self.stickers = arr.prefix(100).map { URL(string: $0)! }
        self.collectionView.reloadData()
    }
}

extension ListViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return stickers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! CustomCell
//        cell.backgroundColor = .yellow
        cell.update(url: self.stickers[indexPath.row])
        return cell
    }
}

class CustomCell: UICollectionViewCell {
    let imageView = AnimatedView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        addSubview(imageView)
        imageView.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
    }
    
    func update(url: URL) {
//        let data = try! Data(contentsOf: url)
        if url.path.hasSuffix("tgs") {
            let dataSource = TGSCachedFrameSource(url: url)
            imageView.setImage(dataSource: dataSource, options: [])
        } else if url.path.hasSuffix("gif") {
            let dataSource = GifDataSource(url: url, firstFrame: false)
            imageView.setImage(dataSource: dataSource, options: [])
        }

    }
}

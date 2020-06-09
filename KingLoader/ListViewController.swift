//
//  ListViewController.swift
//  KingLoader
//
//  Created by Purkylin King on 2020/5/30.
//  Copyright © 2020 Purkylin King. All rights reserved.
//

import UIKit
import KingSticker

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
        
        self.title = "Stickers"
        view.backgroundColor = .white
        view.addSubview(collectionView)
        collectionView.frame = CGRect(origin: .zero, size: CGSize(width: view.bounds.width, height: view.bounds.height / 1))
        collectionView.backgroundColor = .white
//        ResourceManager.shared.clearCache()
        loadData()
    }
    
    func loadData() {
        let arr = [
            "https://assets6.lottiefiles.com/animated_stickers/lf_tgs_HktDR1.json",
            "https://assets4.lottiefiles.com/animated_stickers/lf_tgs_sFL7Vv.json",
            "https://assets1.lottiefiles.com/animated_stickers/lf_tgs_GzPhIF.json",
            "https://assets1.lottiefiles.com/animated_stickers/lf_tgs_NseG8A.json",
            "https://assets8.lottiefiles.com/animated_stickers/lf_tgs_t9jKy8.json",
            "https://assets8.lottiefiles.com/animated_stickers/lf_tgs_50qsGb.json",
            "https://assets7.lottiefiles.com/animated_stickers/lf_tgs_3chCvj.json",
            "https://assets5.lottiefiles.com/animated_stickers/lf_tgs_U0t51u.json",
            "https://assets10.lottiefiles.com/animated_stickers/lf_tgs_4ePDAr.json",
            "https://assets7.lottiefiles.com/animated_stickers/lf_tgs_BYL6wZ.json",
            "https://assets4.lottiefiles.com/animated_stickers/lf_tgs_CclNS1.json",
            "https://assets10.lottiefiles.com/animated_stickers/lf_tgs_cazDC7.json",
            "https://assets3.lottiefiles.com/animated_stickers/lf_tgs_NhF7S7.json",
            "https://assets8.lottiefiles.com/animated_stickers/lf_tgs_19bhKA.json",
            "https://assets10.lottiefiles.com/animated_stickers/lf_tgs_KEiEDk.json",
            "https://assets8.lottiefiles.com/animated_stickers/lf_tgs_KYkQJn.json",
            "https://assets5.lottiefiles.com/animated_stickers/lf_tgs_DYdYL0.json",
            "https://assets3.lottiefiles.com/animated_stickers/lf_tgs_95uX9a.json",
            "https://assets3.lottiefiles.com/animated_stickers/lf_tgs_LI91Wb.json",
            "https://assets9.lottiefiles.com/animated_stickers/lf_tgs_3yBQZc.json",
            "https://assets7.lottiefiles.com/animated_stickers/lf_tgs_AA0Jpu.json",
            "https://assets3.lottiefiles.com/animated_stickers/lf_tgs_cO3sIM.json",
            "https://assets4.lottiefiles.com/animated_stickers/lf_tgs_OK5mAM.json",
            "https://assets1.lottiefiles.com/animated_stickers/lf_tgs_bq6XeO.json",
            "https://assets3.lottiefiles.com/animated_stickers/lf_tgs_T5HCbg.json",
            "https://assets1.lottiefiles.com/animated_stickers/lf_tgs_R4edsE.json",
            "https://assets2.lottiefiles.com/animated_stickers/lf_tgs_H4wfap.json",
            "https://assets9.lottiefiles.com/animated_stickers/lf_tgs_nBtfGp.json",
            "https://assets10.lottiefiles.com/animated_stickers/lf_tgs_2u944T.json",
            "https://assets9.lottiefiles.com/animated_stickers/lf_tgs_lDTQwO.json",
            "https://assets8.lottiefiles.com/animated_stickers/lf_tgs_VqFGpd.json",
            "https://assets10.lottiefiles.com/animated_stickers/lf_tgs_81iH9p.json",
            "https://assets9.lottiefiles.com/animated_stickers/lf_tgs_wmferI.json",
            "https://assets7.lottiefiles.com/animated_stickers/lf_tgs_j589I7.json",
            "https://assets3.lottiefiles.com/animated_stickers/lf_tgs_UnQGjI.json",
            "https://assets4.lottiefiles.com/animated_stickers/lf_tgs_xTP1Wv.json",
            "https://assets3.lottiefiles.com/animated_stickers/lf_tgs_IXBQ8H.json",
            "https://assets4.lottiefiles.com/animated_stickers/lf_tgs_Ib9gZj.json",
            "https://assets9.lottiefiles.com/animated_stickers/lf_tgs_HvhdxX.json",
            "https://assets8.lottiefiles.com/animated_stickers/lf_tgs_XkMtYS.json",
            "https://assets4.lottiefiles.com/animated_stickers/lf_tgs_tpoBjw.json",
            "https://assets4.lottiefiles.com/animated_stickers/lf_tgs_W76SFA.json",
            "https://assets5.lottiefiles.com/animated_stickers/lf_tgs_0sSxND.json",
            "https://assets2.lottiefiles.com/animated_stickers/lf_tgs_wNNws7.json",
            "https://assets1.lottiefiles.com/animated_stickers/lf_tgs_JlmIfF.json",
            "https://assets9.lottiefiles.com/animated_stickers/lf_tgs_N3nMCm.json",
            "https://assets2.lottiefiles.com/animated_stickers/lf_tgs_SWtINd.json",
            "https://assets8.lottiefiles.com/animated_stickers/lf_tgs_5QN45U.json",
            "https://assets6.lottiefiles.com/animated_stickers/lf_tgs_3M8O4q.json",
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Select: \(indexPath.row)th")
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
        if url.path.hasSuffix("tgs") || url.path.hasSuffix("json") {
            let dataSource = TGSCachedFrameSource(url: url)
            imageView.setImage(dataSource: dataSource, options: [])
        } else if url.path.hasSuffix("gif") {
            let dataSource = GifDataSource(url: url, firstFrame: true)
            imageView.setImage(dataSource: dataSource, options: [])
        }

    }
}

//
//  ListViewController.swift
//  KingLoader
//
//  Created by Purkylin King on 2020/5/30.
//  Copyright © 2020 Purkylin King. All rights reserved.
//

import UIKit

class ListViewController: UIViewController {
    let imageView = AnimatedView()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(imageView)
        imageView.frame = CGRect(x: 100, y: 100, width: 100, height: 80)
        
        guard let path = Bundle.main.url(forResource: "test", withExtension: "gif") else { fatalError("not found")}

        let dataSource = GifDataSource(url: path, firstFrame: false, preferredSize: CGSize(width: 100, height: 80))
        imageView.setImage(dataSource: dataSource)
        imageView.backgroundColor = .lightGray
    }
}

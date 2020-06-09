//
//  ViewController.swift
//  KingLoader
//
//  Created by Purkylin King on 2020/5/30.
//  Copyright © 2020 Purkylin King. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        FPSWindow.show()
    }

    @IBAction func btnClicked(_ sender: Any) {
        let vc = ListViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}


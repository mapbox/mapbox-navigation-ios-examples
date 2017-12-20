//
//  ExampleContainerViewController.swift
//  Navigation Examples
//
//  Created by Bobby Sudekum on 12/18/17.
//  Copyright © 2017 Mapbox. All rights reserved.
//

import Foundation
import UIKit


class ExampleContainerViewController: UIViewController {
    
    @IBOutlet weak var beginNavigation: UIButton!

    var exampleClass: UIViewController.Type?
    var exampleName: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = exampleName
        
        if exampleClass == nil {
            beginNavigation.setTitle("Example Not Found", for: .normal)
            beginNavigation.isEnabled = false
        }
    }
    
    @IBAction func didTapBeginNavigation(_ sender: Any) {
        if let exampleClass = exampleClass {
            let viewController = exampleClass.init()
            self.addChildViewController(viewController)
            self.view.addSubview(viewController.view)
            viewController.didMove(toParentViewController: self)
        }
    }
}


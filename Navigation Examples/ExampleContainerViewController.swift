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

    var exampleClass: UIViewController.Type!
    var exampleName: String = "Example Not found"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = exampleName
    }
    
    @IBAction func didTapBeginNavigation(_ sender: Any) {
        let viewController = exampleClass.init()
        self.addChildViewController(viewController)
        self.view.addSubview(viewController.view)
        viewController.didMove(toParentViewController: self)
    }
}


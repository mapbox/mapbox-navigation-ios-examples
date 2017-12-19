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
    var exampleToLoad: String = "Example Not Specified"
    
    var className: AnyClass?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = exampleToLoad
        
        let formattedClassName = exampleToLoad.replacingOccurrences(of: " ", with: "")
        className = NSClassFromString(formattedClassName)
        
        if className == nil {
            beginNavigation.isEnabled = false
            beginNavigation.setTitle("Example Not Found", for: .normal)
        }
    }
    
    @IBAction func didTapBeginNavigation(_ sender: Any) {
        if let viewController = className as? UIViewController.Type {
            let vc = viewController.init()
            self.addChildViewController(vc)
            self.view.addSubview(vc.view)
            vc.didMove(toParentViewController: self)
        }
    }
}


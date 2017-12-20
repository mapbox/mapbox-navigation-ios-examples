//
//  ExampleContainerViewController.swift
//  Navigation Examples
//
//  Created by Bobby Sudekum on 12/18/17.
//  Copyright © 2017 Mapbox. All rights reserved.
//

import Foundation
import UIKit
import MapboxCoreNavigation
import MapboxDirections

var simulationIsEnabled = false

class ExampleContainerViewController: UITableViewController {
    
    @IBOutlet weak var beginNavigation: UIButton!
    @IBOutlet weak var simulateNavigation: UISwitch! {
        didSet {
            simulationIsEnabled = simulateNavigation.isOn
        }
    }
    
    var exampleClass: UIViewController.Type?
    var exampleName: String?
    var exampleDescription: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = exampleName
        
        simulateNavigation.isOn = simulationIsEnabled
        
        if exampleClass == nil {
            beginNavigation.setTitle("Example Not Found", for: .normal)
            beginNavigation.isEnabled = false
            simulateNavigation.isEnabled = false
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
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard let exampleDescription = exampleDescription else { return nil }
        return section == tableView.numberOfSections - 1  ? exampleDescription : nil
    }
    
    @IBAction func didToggleSimulateNavigation(_ sender: Any) {
        simulateNavigation.isOn = !simulateNavigation.isOn
    }
}

func navigationLocationManager(for route: Route) -> NavigationLocationManager {
    return simulationIsEnabled ? SimulatedLocationManager(route: route) : NavigationLocationManager()
}

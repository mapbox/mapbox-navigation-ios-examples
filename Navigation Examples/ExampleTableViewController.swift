//
//  ExampleTableViewController.swift
//  Navigation Examples
//
//  Created by Bobby Sudekum on 12/18/17.
//  Copyright © 2017 Mapbox. All rights reserved.
//

import Foundation
import UIKit

class ExampleTableViewController: UITableViewController {
    override func viewDidLoad() {
        self.clearsSelectionOnViewWillAppear = false
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listOfExamples.count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ExampleCell", for: indexPath)
        
        cell.textLabel?.text = listOfExamples[indexPath.row].name
        
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "TableToExampleSegue" {
            if let controller = segue.destination as? ExampleContainerViewController, let senderCell = sender as? UITableViewCell, let text = senderCell.textLabel?.text {
                var exampleClass: UIViewController.Type?
                
                switch text {
                case "Basic":
                    exampleClass = BasicViewController.self
                case "Waypoint Arrival Screen":
                    exampleClass = WaypointArrivalScreenViewController.self
                case "Custom Style":
                    exampleClass = CustomStyleViewController.self
                    default:
                    assert(false, "Example not found")
                }
                
                controller.exampleClass = exampleClass
                controller.exampleName = text
            }
        }
    }
}

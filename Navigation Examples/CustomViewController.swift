//
//  CustomViewController.swift
//  Navigation-Examples
//
//  Created by Eric Wolfe on 1/3/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import UIKit
import MapboxNavigation
import MapboxCoreNavigation
import MapboxDirections

class CustomViewController: UIViewController {

    @IBOutlet weak var embeddedNavigationView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let origin = CLLocationCoordinate2DMake(37.77440680146262, -122.43539772352648)
        let destination = CLLocationCoordinate2DMake(37.76556957793795, -122.42409811526268)
        let options = NavigationRouteOptions(coordinates: [origin, destination])
        
        Directions.shared.calculate(options) { (waypoints, routes, error) in
            guard let route = routes?.first, error == nil else {
                print(error!.localizedDescription)
                return
            }
            
            let navigationController = NavigationViewController(for: route)
            navigationController.routeController.locationManager = SimulatedLocationManager(route: route)
            self.addChildViewController(navigationController)
            self.embeddedNavigationView.addSubview(navigationController.view)
            navigationController.didMove(toParentViewController: self)
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

import Foundation
import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections

class WaypointArrivalScreenViewController: UIViewController, NavigationViewControllerDelegate {
    
    override func viewDidLoad() {
        let waypointOne = Waypoint(coordinate: CLLocationCoordinate2DMake(37.777655950348475, -122.43199467658997))
        let waypointTwo = Waypoint(coordinate: CLLocationCoordinate2DMake(37.776087132342745, -122.4329173564911))
        let waypointThree = Waypoint(coordinate: CLLocationCoordinate2DMake(37.775357832637184, -122.43493974208832))
        
        let options = NavigationRouteOptions(waypoints: [waypointOne, waypointTwo, waypointThree])
        
        Directions.shared.calculate(options) { (waypoints, routes, error) in
            guard let route = routes?.first, error == nil else {
                print(error!.localizedDescription)
                return
            }
            
            let navigationController = NavigationViewController(for: route)
            navigationController.delegate = self
            
            // This allows the developer to simulate the route.
            // Note: If copying and pasting this code in your own project,
            // comment out `simulationIsEnabled` as it is defined elsewhere in this project.
            if simulationIsEnabled {
                navigationController.routeController.locationManager = SimulatedLocationManager(route: route)
            }
            
            self.present(navigationController, animated: true, completion: nil)
        }
    }
    
    // By default, when the user arrives at a waypoint, the next leg starts immediately.
    // If however you would like to pause and allow the user to provide input, set this delegate method to false.
    // This does however require you to increment the leg count on your own. See the example below in `confirmationControllerDidConfirm()`.
    func navigationViewController(_ navigationViewController: NavigationViewController, shouldIncrementLegWhenArrivingAtWaypoint waypoint: Waypoint) -> Bool {
        return false
    }
    
    // Show an alert when arriving at the waypoint
    func navigationViewController(_ navigationViewController: NavigationViewController, didArriveAt waypoint: Waypoint) {
        let alert = UIAlertController(title: "Arrived at \(String(describing: waypoint.name))", message: "Would you like to continue?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { action in
            // Begin the next leg once the driver confirms
            navigationViewController.routeController.routeProgress.legIndex += 1
        }))
        navigationViewController.present(alert, animated: true, completion: nil)
    }
}

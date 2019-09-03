import Foundation
import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections

class WaypointArrivalScreenViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let waypointOne = Waypoint(coordinate: CLLocationCoordinate2DMake(37.777655950348475, -122.43199467658997))
        let waypointTwo = Waypoint(coordinate: CLLocationCoordinate2DMake(37.776087132342745, -122.4329173564911))
        let waypointThree = Waypoint(coordinate: CLLocationCoordinate2DMake(37.775357832637184, -122.43493974208832))
        
        let options = NavigationRouteOptions(waypoints: [waypointOne, waypointTwo, waypointThree])
        
        Directions.shared.calculate(options) { (waypoints, routes, error) in
            guard let route = routes?.first, error == nil else {
                print(error!.localizedDescription)
                return
            }
            
            // For demonstration purposes, simulate locations if the Simulate Navigation option is on.
            let navigationService = MapboxNavigationService(route: route, simulating: simulationIsEnabled ? .always : .onPoorGPS)
            let navigationOptions = NavigationOptions(navigationService: navigationService)
            let navigationViewController = NavigationViewController(for: route, options: navigationOptions)
            navigationViewController.modalPresentationStyle = .fullScreen
            navigationViewController.delegate = self
            
            self.present(navigationViewController, animated: true, completion: nil)
        }
    }
}

extension WaypointArrivalScreenViewController: NavigationViewControllerDelegate {
    // Show an alert when arriving at the waypoint and wait until the user to start next leg.
    func navigationViewController(_ navigationViewController: NavigationViewController, didArriveAt waypoint: Waypoint) -> Bool {
        let alert = UIAlertController(title: "Arrived at \(String(describing: waypoint.name))", message: "Would you like to continue?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { action in
            // Begin the next leg once the driver confirms
            navigationViewController.navigationService.routeProgress.legIndex += 1
        }))
        navigationViewController.present(alert, animated: true, completion: nil)
        
        return false
    }
}

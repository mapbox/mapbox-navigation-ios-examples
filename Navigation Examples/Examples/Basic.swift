import Foundation
import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections

class BasicViewController: UIViewController {
    override func viewDidLoad() {
        let origin = CLLocationCoordinate2DMake(37.77440680146262, -122.43539772352648)
        let destination = CLLocationCoordinate2DMake(37.76556957793795, -122.42409811526268)
        let options = NavigationRouteOptions(coordinates: [origin, destination])
        
        Directions.shared.calculate(options) { (waypoints, routes, error) in
            guard let route = routes?.first, error == nil else {
                print(error!.localizedDescription)
                return
            }
            
            // The second argument `locationManager` is optional
            let navigationController = NavigationViewController(for: route, locationManager: navigationLocationManager(for: route))
            self.present(navigationController, animated: true, completion: nil)
        }
    }
}

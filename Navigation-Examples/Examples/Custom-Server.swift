import Foundation
import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections

class CustomServerViewController: UIViewController {
    
    let routeOptions = NavigationRouteOptions(coordinates: [
        CLLocationCoordinate2DMake(37.77440680146262, -122.43539772352648),
        CLLocationCoordinate2DMake(37.76556957793795, -122.42409811526268)
        ])

    var navigationViewController: NavigationViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Directions.shared.calculate(routeOptions) { (waypoints, routes, error) in
            guard let route = routes?.first, error == nil else {
                print(error!.localizedDescription)
                return
            }
            
            // For demonstration purposes, simulate locations if the Simulate Navigation option is on.
            let navigationService = MapboxNavigationService(route: route, simulating: simulationIsEnabled ? .always : .onPoorGPS)
            
            let navigationController = NavigationViewController(for: route, navigationService: navigationService)
            self.navigationViewController?.delegate = self
            
            self.present(self.navigationViewController!, animated: true, completion: nil)
        }
    }
}

extension CustomServerViewController: NavigationViewControllerDelegate {
    // Never reroute internally. Instead,
    // 1. Fetch a route from your server
    // 2. Map Match the coordinates from your server
    // 3. Set the route on your server
    func navigationViewController(_ navigationViewController: NavigationViewController, shouldRerouteFrom location: CLLocation) -> Bool {
        
        // Here, we are simulating a custom server.
        let routeOptions = NavigationRouteOptions(waypoints: [Waypoint(location: location), self.routeOptions.waypoints.last!])
        Directions.shared.calculate(routeOptions) { (waypoints, routes, error) in
            guard let routeCoordinates = routes?.first?.coordinates, error == nil else {
                print(error!.localizedDescription)
                return
            }
            
            //
            // ❗️IMPORTANT❗️
            // Use `Directions.calculateRoutes(matching:completionHandler:)` for navigating on a map matching response.
            //
            let matchOptions = NavigationMatchOptions(coordinates: routeCoordinates)
            
            // This defines the waypoints on the route.
            // We want the user to navigate from the first coordinate to the last coordinate without any stops in between.
            // You can specify more intermediate waypoints here if'd you like.
            matchOptions.waypointIndices = IndexSet([0, routeCoordinates.count - 1])
            
            Directions.shared.calculateRoutes(matching: matchOptions) { (waypoints, routes, error) in
                guard let route = routes?.first, error == nil else { return }
                
                // Set the route
                self.navigationViewController?.route = route
            }
        }
        
        return true
    }
}

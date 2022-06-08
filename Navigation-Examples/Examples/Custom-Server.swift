/*
 This code example is part of the Mapbox Navigation SDK for iOS demo app,
 which you can build and run: https://github.com/mapbox/mapbox-navigation-ios-examples
 To learn more about each example in this app, including descriptions and links
 to documentation, see our docs: https://docs.mapbox.com/ios/navigation/examples/custom-server
 */

import Foundation
import UIKit
import MapboxMaps
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
        
        let routeOptions = self.routeOptions
        Directions.shared.calculate(routeOptions) { [weak self] (_, result) in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let response):
                guard let strongSelf = self else {
                    return
                }
                
                // For demonstration purposes, simulate locations if the Simulate Navigation option is on.
                let navigationService = MapboxNavigationService(routeResponse: response,
                                                                routeIndex: 0,
                                                                routeOptions: routeOptions,
                                                                customRoutingProvider: NavigationSettings.shared.directions,
                                                                credentials: NavigationSettings.shared.directions.credentials,
                                                                simulating: simulationIsEnabled ? .always : .onPoorGPS)
                let navigationOptions = NavigationOptions(navigationService: navigationService)
                strongSelf.navigationViewController = NavigationViewController(for: response,
                                                                                  routeIndex: 0,
                                                                                  routeOptions: routeOptions,
                                                                                  navigationOptions: navigationOptions)
                strongSelf.navigationViewController?.modalPresentationStyle = .fullScreen
                strongSelf.navigationViewController?.delegate = strongSelf
                
                strongSelf.present(strongSelf.navigationViewController!, animated: true, completion: nil)
            }
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
        Directions.shared.calculate(routeOptions) { [weak self] (_, result) in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let response):
                guard let routeShape = response.routes?.first?.shape else {
                    return
                }
                
                //
                // ❗️IMPORTANT❗️
                // Use `Directions.calculateRoutes(matching:completionHandler:)` for navigating on a map matching response.
                //
                let matchOptions = NavigationMatchOptions(coordinates: routeShape.coordinates)
                
                // By default, each waypoint separates two legs, so the user stops at each waypoint.
                // We want the user to navigate from the first coordinate to the last coordinate without any stops in between.
                // You can specify more intermediate waypoints here if you’d like.
                for waypoint in matchOptions.waypoints.dropFirst().dropLast() {
                    waypoint.separatesLegs = false
                }
                
                Directions.shared.calculateRoutes(matching: matchOptions) { [weak self] (_, result) in
                    switch result {
                    case .failure(let error):
                        print(error.localizedDescription)
                    case .success(let response):
                        guard !(response.routes?.isEmpty ?? true) else {
                            return
                        }
                        
                        // Convert matchOptions to `RouteOptions`
                        let routeOptions = RouteOptions(matchOptions: matchOptions)
                        
                        // Set the route
                        self?.navigationViewController?.navigationService.router.updateRoute(with: .init(routeResponse: response, routeIndex: 0),
                                                                                             routeOptions: routeOptions,
                                                                                             completion: nil)
                    }
                }
            }
        }
        
        return true
    }
    
    func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool) {
        dismiss(animated: true, completion: nil)
    }
}

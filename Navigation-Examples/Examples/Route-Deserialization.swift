/*
 This code example is part of the Mapbox Navigation SDK for iOS demo app,
 which you can build and run: https://github.com/mapbox/mapbox-navigation-ios-examples
 To learn more about each example in this app, including descriptions and links
 to documentation, see our docs: https://docs.mapbox.com/ios/navigation/examples/route-deserialization
 */

import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections

class RouteDeserializationViewController: UIViewController {
    
    // MARK: - UIViewController lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let origin = CLLocationCoordinate2DMake(37.776818, -122.399076)
        let destination = CLLocationCoordinate2DMake(37.777407, -122.399814)
        let routeOptions = NavigationRouteOptions(coordinates: [origin, destination])
        
        // Load previously serialized Route object in JSON format and deserialize it.
        let routeData = JSONFromFileNamed(name: "route")
        let decoder = JSONDecoder()
        decoder.userInfo[.options] = routeOptions
        let route: Route? = try? decoder.decode(Route.self, from: routeData)
        
        if let route = route {
            let routeResponse = RouteResponse(httpResponse: nil,
                                              identifier: "deserialized-route",
                                              routes: [route],
                                              waypoints: [origin, destination].map {
                                                Waypoint(coordinate: $0)
                                              },
                                              options: .route(routeOptions),
                                              credentials: Directions.shared.credentials)
            
            let navigationService = MapboxNavigationService(routeResponse: routeResponse,
                                                            routeIndex: 0,
                                                            routeOptions: routeOptions,
                                                            customRoutingProvider: NavigationSettings.shared.directions,
                                                            credentials: NavigationSettings.shared.directions.credentials,
                                                            simulating: simulationIsEnabled ? .always : .onPoorGPS)
            let navigationOptions = NavigationOptions(navigationService: navigationService)
            let navigationViewController = NavigationViewController(for: routeResponse,
                                                                       routeIndex: 0,
                                                                       routeOptions: routeOptions,
                                                                       navigationOptions: navigationOptions)
            navigationViewController.modalPresentationStyle = .fullScreen
            self.present(navigationViewController, animated: true, completion: nil)
        } else {
            print("Unable to deserialize Route.")
        }
    }
    
    // MARK: - Utility methods
    
    private func JSONFromFileNamed(name: String) -> Data {
        
        guard let path = Bundle.main.path(forResource: name, ofType: "json") else {
            preconditionFailure("File \(name) not found.")
        }
        
        guard let data = NSData(contentsOfFile: path) as Data? else {
            preconditionFailure("No data found at \(path).")
        }
        
        return data
    }
}

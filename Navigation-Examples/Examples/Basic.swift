/*
 This code example is part of the Mapbox Navigation SDK for iOS demo app,
 which you can build and run: https://github.com/mapbox/mapbox-navigation-ios-examples
 To learn more about each example in this app, including descriptions and links
 to documentation, see our docs: https://docs.mapbox.com/ios/navigation/examples/basic
 */

import Foundation
import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections

class BasicViewController: UIViewController {
    private let routingProvider = MapboxRoutingProvider()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let origin = CLLocationCoordinate2DMake(37.77440680146262, -122.43539772352648)
        let destination = CLLocationCoordinate2DMake(37.76556957793795, -122.42409811526268)
        let options = NavigationRouteOptions(coordinates: [origin, destination])

        routingProvider.calculateRoutes(options: options) { [weak self] result in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let indexedRouteResponse):
                guard let self else {
                    return
                }
                
                // For demonstration purposes, simulate locations if the Simulate Navigation option is on.
                // Since first route is retrieved from response `routeIndex` is set to 0.
                let navigationService = MapboxNavigationService(indexedRouteResponse: indexedRouteResponse,
                                                                customRoutingProvider: self.routingProvider,
                                                                credentials: NavigationSettings.shared.directions.credentials,
                                                                simulating: simulationIsEnabled ? .always : .onPoorGPS)
                
                let navigationOptions = NavigationOptions(navigationService: navigationService)
                let navigationViewController = NavigationViewController(for: indexedRouteResponse,
                                                                        navigationOptions: navigationOptions)
                navigationViewController.modalPresentationStyle = .fullScreen
                // Render part of the route that has been traversed with full transparency, to give the illusion of a disappearing route.
                navigationViewController.routeLineTracksTraversal = true
                
                self.present(navigationViewController, animated: true, completion: nil)
            }
        }
    }
}

/*
 This code example is part of the Mapbox Navigation SDK for iOS demo app,
 which you can build and run: https://github.com/mapbox/mapbox-navigation-ios-examples
 To learn more about each example in this app, including descriptions and links
 to documentation, see our docs: https://docs.mapbox.com/ios/navigation/examples/predictive-caching
 */

import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections

class PredictiveCachingViewController: UIViewController {
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
                
                // When predictive caching is enabled, the Navigation SDK will create a cache of data within three configurable boundaries.
                var predictiveCacheOptions = PredictiveCacheOptions()
                // Predictive cache should be configured separately for navigation and maps
                // Radius around the user's location. Defaults to 2000 meters.
                predictiveCacheOptions.predictiveCacheNavigationOptions.locationOptions.routeBufferRadius = 300
                // Buffer around the route. Defaults to 500 meters.
                predictiveCacheOptions.predictiveCacheNavigationOptions.locationOptions.currentLocationRadius = 2000
                // Radius around the destination. Defaults to 5000 meters.
                predictiveCacheOptions.predictiveCacheNavigationOptions.locationOptions.destinationLocationRadius = 3000

                // You can specify zoom range for map data caching.
                predictiveCacheOptions.predictiveCacheMapsOptions.zoomRange = 5...12
                // Location cache properties can also be configured for map data caching.
                predictiveCacheOptions.predictiveCacheMapsOptions.locationOptions.destinationLocationRadius = 2000
                
                let navigationOptions = NavigationOptions(navigationService: navigationService,
                                                          predictiveCacheOptions: predictiveCacheOptions)
                let navigationViewController = NavigationViewController(for: indexedRouteResponse,
                                                                        navigationOptions: navigationOptions)
                navigationViewController.modalPresentationStyle = .fullScreen
                navigationViewController.routeLineTracksTraversal = true
                
                self.present(navigationViewController, animated: true)
            }
        }
    }
}

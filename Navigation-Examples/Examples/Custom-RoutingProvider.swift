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

/*
 This example demonstrates how users can control and customize the rerouting process.
 Unlike `Custom-Server` example, this one does not completely cancel SDK mechanism to do it
 separately, but instead controls just the part of new route calculation, preserving original
 workflow and events. In result, any related components will not know that rerouting was altered
 and will react as on usual reroute event.
 */
class CustomRoutingProviderViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let origin = CLLocationCoordinate2DMake(37.77440680146262, -122.43539772352648)
        let destination = CLLocationCoordinate2DMake(37.76556957793795, -122.42409811526268)
        let options = NavigationRouteOptions(coordinates: [origin, destination])
        
        // This example is similar to `BasicViewController` except that we are using our custom `RoutingProvider` implementation for retrieving routes.
        let customRoutingProvider = CustomProvider()
        
        _ = customRoutingProvider.calculateRoutes(options: options, completionHandler: { [weak self] (_, result) in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let response):
                guard let strongSelf = self else {
                    return
                }
                
                let navigationService = MapboxNavigationService(routeResponse: response,
                                                                routeIndex: 0,
                                                                routeOptions: options,
                                                                customRoutingProvider: customRoutingProvider, // passing `customRoutingProvider` to ensure it is used for re-routing and refreshing
                                                                credentials: NavigationSettings.shared.directions.credentials,
                                                                simulating: simulationIsEnabled ? .always : .onPoorGPS)
                
                let navigationOptions = NavigationOptions(navigationService: navigationService)
                let navigationViewController = NavigationViewController(for: response,
                                                                           routeIndex: 0,
                                                                           routeOptions: options,
                                                                           navigationOptions: navigationOptions)
                navigationViewController.modalPresentationStyle = .fullScreen
                navigationViewController.routeLineTracksTraversal = true
                
                strongSelf.present(navigationViewController, animated: true, completion: nil)
            }
        })
    }
}

class CustomProvider: RoutingProvider {
    // This can encapsulate any route building engine we need. For simplicity let's use `MapboxRoutingProvider`.
    let routeCalculator = MapboxRoutingProvider()
    
    // We can also modify the options used to calculate a route.
    func applyOptionsModification(_ options: DirectionsOptions) {
        options.attributeOptions = [.congestionLevel, .speed, .maximumSpeedLimit, .expectedTravelTime]
    }
    
    // Here any manipulations on the reponse data can take place
    func applyMapMatchingModifications(_ response: MapMatchingResponse) {
        response.matches?.forEach { match in
            match.legs.forEach { leg in
                leg.incidents = fetchExternalIncidents(for: leg)
            }
        }
    }
    
    // Let's say we have an external source of incidents data, we want to apply to the route.
    func fetchExternalIncidents(for leg: RouteLeg) -> [Incident] {
        return [Incident(identifier: "\(leg.name) incident",
                         type: .otherNews,
                         description: "Custom Incident",
                         creationDate: Date(),
                         startDate: Date(),
                         endDate: Date().addingTimeInterval(60),
                         impact: nil,
                         subtype: nil,
                         subtypeDescription: nil,
                         alertCodes: [],
                         lanesBlocked: nil,
                         shapeIndexRange: 0..<1)]
    }
    
    // MARK: RoutingProvider implementation
    
    func calculateRoutes(options: RouteOptions, completionHandler: @escaping Directions.RouteCompletionHandler) -> NavigationProviderRequest? {
        applyOptionsModification(options)
        
        // Using `MapboxRoutingProvider` also illustrates cases when we need to modify just a part of the route, or dynamically edit `RouteOptions` for each reroute.
        return routeCalculator.calculateRoutes(options: options,
                                               completionHandler: completionHandler)
    }
    
    func calculateRoutes(options: MatchOptions, completionHandler: @escaping Directions.MatchCompletionHandler) -> NavigationProviderRequest? {
        applyOptionsModification(options)
        
        return routeCalculator.calculateRoutes(options: options,
                                               completionHandler: { [weak self] (session, result) in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
                completionHandler(session, result)
            case .success(let response):
                guard let strongSelf = self else {
                    return
                }
                strongSelf.applyMapMatchingModifications(response)
                
                completionHandler(session, .success(response))
            }
        })
    }
    
    // Let's make our custom routing provider prevent route refreshes.
    func refreshRoute(indexedRouteResponse: IndexedRouteResponse, fromLegAtIndex: UInt32, completionHandler: @escaping Directions.RouteCompletionHandler) -> NavigationProviderRequest? {
        
        var options: DirectionsOptions!
        switch indexedRouteResponse.routeResponse.options {
        case.match(let matchOptions):
            options = matchOptions
        case .route(let routeOptions):
            options = routeOptions
        }
        
        completionHandler((options, NavigationSettings.shared.directions.credentials),
                            .failure(.unableToRoute))
        return nil
    }
}

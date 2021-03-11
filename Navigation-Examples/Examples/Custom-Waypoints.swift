import Foundation
import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import MapboxMaps
import Turf

class CustomWaypointsViewController: UIViewController, NavigationMapViewDelegate, NavigationViewControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()

        let origin = CLLocationCoordinate2DMake(37.77440680146262, -122.43539772352648)
        let firstWaypoint = CLLocationCoordinate2DMake(37.77671493551678, -122.42370544507409)
        let secondWaypoint = CLLocationCoordinate2DMake(37.76556957793795, -122.42409811526268)
        let options = NavigationRouteOptions(coordinates: [origin, firstWaypoint, secondWaypoint])

        Directions.shared.calculate(options) { [weak self] (session, result) in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let response):
                guard let route = response.routes?.first, let strongSelf = self else {
                    return
                }

                // For demonstration purposes, simulate locations if the Simulate Navigation option is on.
                // Since first route is retrieved from response `routeIndex` is set to 0.
                let navigationService = MapboxNavigationService(route: route, routeIndex: 0, routeOptions: options, simulating: simulationIsEnabled ? .always : .onPoorGPS)
                let navigationOptions = NavigationOptions(navigationService: navigationService)
                let navigationViewController = NavigationViewController(for: route, routeIndex: 0, routeOptions: options, navigationOptions: navigationOptions)
                navigationViewController.navigationMapView?.delegate = self
                navigationViewController.modalPresentationStyle = .fullScreen
                // Render part of the route that has been traversed with full transparency, to give the illusion of a disappearing route.
                navigationViewController.routeLineTracksTraversal = true

                strongSelf.present(navigationViewController, animated: true, completion: nil)
            }
        }
    }

    // MARK: - Styling methods
    func customCircleLayer(with identifier: String, sourceIdentifier: String) -> CircleLayer? {
        var circleLayer = CircleLayer(id: identifier)
        circleLayer.source = sourceIdentifier
        let opacity = Exp(.switchCase) {
            Exp(.any) {
                Exp(.get) {
                    "waypointCompleted"
                }
            }
            0.5
            1
        }
        circleLayer.paint?.circleColor = .constant(.init(color: UIColor(red:0.9, green:0.9, blue:0.9, alpha:1.0)))
        circleLayer.paint?.circleOpacity = .expression(opacity)
        circleLayer.paint?.circleRadius = .constant(.init(10))
        circleLayer.paint?.circleStrokeColor = .constant(.init(color: UIColor.black))
        circleLayer.paint?.circleStrokeWidth = .constant(.init(1))
        circleLayer.paint?.circleStrokeOpacity = .expression(opacity)
        return circleLayer
    }

    func customSymbolLayer(with identifier: String, sourceIdentifier: String) -> SymbolLayer? {
        var symbolLayer = SymbolLayer(id: identifier)
        symbolLayer.source = sourceIdentifier
        symbolLayer.layout?.textField = .expression(Exp(.toString){
                                                        Exp(.get){
                                                            "name"
                                                        }
                                                    })
        symbolLayer.layout?.textSize = .constant(.init(10))
        symbolLayer.paint?.textOpacity = .expression(Exp(.switchCase) {
            Exp(.any) {
                Exp(.get) {
                    "waypointCompleted"
                }
            }
            0.5
            1
        })
        symbolLayer.paint?.textHaloWidth = .constant(.init(0.25))
        symbolLayer.paint?.textHaloColor = .constant(.init(color: UIColor.black))
        return symbolLayer
    }

    func customWaypointShape(shapeFor waypoints: [Waypoint], legIndex: Int) -> FeatureCollection? {
        var features = [Feature]()
        for (waypointIndex, waypoint) in waypoints.enumerated() {
            var feature = Feature(Point(waypoint.coordinate))
            feature.properties = [
                "waypointCompleted": waypointIndex < legIndex,
                "name": "#\(waypointIndex + 1)"
            ]
            features.append(feature)
        }
        return FeatureCollection(features: features)
    }

    // MARK: - NavigationMapViewDelegate methods
    func navigationMapView(_ navigationMapView: NavigationMapView, waypointCircleLayerWithIdentifier identifier: String, sourceIdentifier: String) -> CircleLayer? {
        return customCircleLayer(with: identifier, sourceIdentifier: sourceIdentifier)
    }

    func navigationMapView(_ navigationMapView: NavigationMapView, waypointSymbolLayerWithIdentifier identifier: String, sourceIdentifier: String) -> SymbolLayer? {
        return customSymbolLayer(with: identifier, sourceIdentifier: sourceIdentifier)
    }

    func navigationMapView(_ navigationMapView: NavigationMapView, shapeFor waypoints: [Waypoint], legIndex: Int) -> FeatureCollection? {
        return customWaypointShape(shapeFor: waypoints, legIndex: legIndex)
    }

    // MARK: - NavigationViewControllerDelegate methods
    func navigationViewController(_ navigationViewController: NavigationViewController, waypointCircleLayerWithIdentifier identifier: String, sourceIdentifier: String) -> CircleLayer? {
        return customCircleLayer(with: identifier, sourceIdentifier: sourceIdentifier)
    }

    func navigationViewController(_ navigationViewController: NavigationViewController, waypointSymbolLayerWithIdentifier identifier: String, sourceIdentifier: String) -> SymbolLayer? {
        return customSymbolLayer(with: identifier, sourceIdentifier: sourceIdentifier)
    }

    func navigationViewController(_ navigationViewController: NavigationViewController, shapeFor waypoints: [Waypoint], legIndex: Int) -> FeatureCollection? {
        return customWaypointShape(shapeFor: waypoints, legIndex: legIndex)
    }
}

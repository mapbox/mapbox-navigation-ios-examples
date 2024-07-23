/*
 This code example is part of the Mapbox Navigation SDK for iOS demo app,
 which you can build and run: https://github.com/mapbox/mapbox-navigation-ios-examples
 To learn more about each example in this app, including descriptions and links
 to documentation, see our docs: https://docs.mapbox.com/ios/navigation/examples/custom-waypoint
 */

import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import MapboxMaps
import Turf

class CustomWaypointsViewController: UIViewController {
    private let routingProvider = MapboxRoutingProvider()
    
    var navigationMapView: NavigationMapView!

    var routes: [Route]? {
        return indexedRouteResponse?.routeResponse.routes
    }
    
    var indexedRouteResponse: IndexedRouteResponse? {
        didSet {
            guard routes != nil else {
                navigationMapView.removeRoutes()
                return
            }
            showCurrentRoute()
        }
    }
    
    func showCurrentRoute() {
        guard let indexedRouteResponse else { return }

        navigationMapView.show(indexedRouteResponse)
    }
    
    var startButton: UIButton!
    
    // MARK: - UIViewController lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationMapView = NavigationMapView(frame: view.bounds)
        navigationMapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        navigationMapView.delegate = self
        navigationMapView.userLocationStyle = .puck2D()
        
        view.addSubview(navigationMapView)
        
        startButton = UIButton()
        startButton.setTitle("Start Navigation", for: .normal)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.backgroundColor = .blue
        startButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        startButton.addTarget(self, action: #selector(tappedButton(sender:)), for: .touchUpInside)
        startButton.isHidden = true
        view.addSubview(startButton)
        
        startButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -20).isActive = true
        startButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        view.setNeedsLayout()
        
        requestRoute()
    }
    
    // Override layout lifecycle callback to be able to style the start button.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        startButton.layer.cornerRadius = startButton.bounds.midY
        startButton.clipsToBounds = true
        startButton.setNeedsDisplay()
    }

    @objc func tappedButton(sender: UIButton) {
        guard let indexedRouteResponse else { return }
        // For demonstration purposes, simulate locations if the Simulate Navigation option is on.
        let navigationService = MapboxNavigationService(indexedRouteResponse: indexedRouteResponse,
                                                        customRoutingProvider: routingProvider,
                                                        credentials: NavigationSettings.shared.directions.credentials,
                                                        simulating: simulationIsEnabled ? .always : .onPoorGPS)
        let navigationOptions = NavigationOptions(navigationService: navigationService)
        let navigationViewController = NavigationViewController(for: indexedRouteResponse,
                                                                navigationOptions: navigationOptions)
        navigationViewController.delegate = self
        
        present(navigationViewController, animated: true, completion: nil)
    }

    func requestRoute() {
        let origin = CLLocationCoordinate2DMake(37.773, -122.411)
        let firstWaypoint = CLLocationCoordinate2DMake(37.763252389415186, -122.40061448679577)
        let secondWaypoint = CLLocationCoordinate2DMake(37.76259647118012, -122.42072747880516)
        let navigationRouteOptions = NavigationRouteOptions(coordinates: [origin, firstWaypoint, secondWaypoint])
        
        let cameraOptions = CameraOptions(center: origin, zoom: 13.0)
        self.navigationMapView.mapView.mapboxMap.setCamera(to: cameraOptions)
        
        routingProvider.calculateRoutes(options: navigationRouteOptions) { [weak self] result in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let indexedRouteResponse):
                guard indexedRouteResponse.currentRoute != nil,
                      let self else { return }

                self.indexedRouteResponse = indexedRouteResponse
                self.startButton?.isHidden = false
            }
        }
    }
    
    func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Styling methods
    func customCircleLayer(with identifier: String, sourceIdentifier: String) -> CircleLayer {
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
        circleLayer.circleColor = .constant(.init(UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)))
        circleLayer.circleOpacity = .expression(opacity)
        circleLayer.circleRadius = .constant(.init(10))
        circleLayer.circleStrokeColor = .constant(.init(UIColor.black))
        circleLayer.circleStrokeWidth = .constant(.init(1))
        circleLayer.circleStrokeOpacity = .expression(opacity)
        return circleLayer
    }

    func customSymbolLayer(with identifier: String, sourceIdentifier: String) -> SymbolLayer {
        var symbolLayer = SymbolLayer(id: identifier)
        symbolLayer.source = sourceIdentifier
        symbolLayer.textField = .expression(Exp(.toString) {
            Exp(.get) {
                "name"
            }
        })
        symbolLayer.textSize = .constant(.init(10))
        symbolLayer.textOpacity = .expression(Exp(.switchCase) {
            Exp(.any) {
                Exp(.get) {
                    "waypointCompleted"
                }
            }
            0.5
            1
        })
        symbolLayer.textHaloWidth = .constant(.init(0.25))
        symbolLayer.textHaloColor = .constant(.init(UIColor.black))
        return symbolLayer
    }

    func customWaypointShape(shapeFor waypoints: [Waypoint], legIndex: Int) -> FeatureCollection {
        var features = [Turf.Feature]()
        for (waypointIndex, waypoint) in waypoints.enumerated() {
            var feature = Feature(geometry: .point(Point(waypoint.coordinate)))
            feature.properties = [
                "waypointCompleted": .boolean(waypointIndex < legIndex),
                "name": .number(Double(waypointIndex + 1))
            ]
            features.append(feature)
        }
        return FeatureCollection(features: features)
    }
}

// MARK: Delegate methods
extension CustomWaypointsViewController: NavigationMapViewDelegate {
    func navigationMapView(_ navigationMapView: NavigationMapView, waypointCircleLayerWithIdentifier identifier: String, sourceIdentifier: String) -> CircleLayer? {
        return customCircleLayer(with: identifier, sourceIdentifier: sourceIdentifier)
    }

    func navigationMapView(_ navigationMapView: NavigationMapView, waypointSymbolLayerWithIdentifier identifier: String, sourceIdentifier: String) -> SymbolLayer? {
        return customSymbolLayer(with: identifier, sourceIdentifier: sourceIdentifier)
    }

    func navigationMapView(_ navigationMapView: NavigationMapView, shapeFor waypoints: [Waypoint], legIndex: Int) -> FeatureCollection? {
        return customWaypointShape(shapeFor: waypoints, legIndex: legIndex)
    }
}

extension CustomWaypointsViewController: NavigationViewControllerDelegate {
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

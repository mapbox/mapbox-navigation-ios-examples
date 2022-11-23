/*
 This code example is part of the Mapbox Navigation SDK for iOS demo app,
 which you can build and run: https://github.com/mapbox/mapbox-navigation-ios-examples
 To learn more about each example in this app, including descriptions and links
 to documentation, see our docs: https://docs.mapbox.com/ios/navigation/examples/route-lines-styling
 */

import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import MapboxMaps
import Turf

class RouteLinesStylingViewController: UIViewController {
    
    typealias ActionHandler = (UIAlertAction) -> Void
    
    var navigationMapView: NavigationMapView!
    
    var currentRouteIndex = 0 {
        didSet {
            showCurrentRoute()
        }
    }

    var currentRoute: Route? {
        return routes?[currentRouteIndex]
    }
    
    var routes: [Route]? {
        return routeResponse?.routes
    }
    
    var routeResponse: RouteResponse? {
        didSet {
            guard currentRoute != nil else {
                navigationMapView.removeRoutes()
                return
            }
            currentRouteIndex = 0
        }
    }
    
    func showCurrentRoute() {
        guard let currentRoute = currentRoute else { return }
        
        var routes = [currentRoute]
        routes.append(contentsOf: self.routes!.filter {
            $0 != currentRoute
        })
        navigationMapView.show(routes)
        navigationMapView.showWaypoints(on: currentRoute)
    }
    
    var startButton: UIButton!
    
    // MARK: - UIViewController lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationMapView()
        setupPerformActionBarButtonItem()
        setupGestureRecognizers()
    }
    
    // MARK: - Setting-up methods
    
    func setupNavigationMapView() {
        navigationMapView = NavigationMapView(frame: view.bounds)
        navigationMapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        navigationMapView.userLocationStyle = .puck2D()
        navigationMapView.delegate = self
        
        
        let navigationViewportDataSource = NavigationViewportDataSource(navigationMapView.mapView, viewportDataSourceType: .raw)
        navigationMapView.navigationCamera.viewportDataSource = navigationViewportDataSource
        changeMapStyle(navigationMapView)
        
        view.addSubview(navigationMapView)
    }
    
    func setupPerformActionBarButtonItem() {
        startButton = UIButton()
        startButton.setTitle("Options", for: .normal)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.backgroundColor = .blue
        startButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        startButton.layer.cornerRadius = 10
        startButton.clipsToBounds = true
        startButton.addTarget(self, action: #selector(performAction(_:)), for: .touchUpInside)
        startButton.isHidden = true
        view.addSubview(startButton)
        
        startButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -20).isActive = true
        startButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        view.setNeedsLayout()
    }
    
    @objc func performAction(_ sender: Any) {
        let alertController = UIAlertController(title: "Perform action",
                                                message: "Select specific action to perform it", preferredStyle: .actionSheet)
        
        let startNavigation: ActionHandler = { _ in self.startNavigation() }
        let removeRoutes: ActionHandler = { _ in self.routeResponse = nil }
        
        let actions: [(String, UIAlertAction.Style, ActionHandler?)] = [
            ("Start Navigation", .default, startNavigation),
            ("Remove Routes", .default, removeRoutes),
            ("Cancel", .cancel, nil)
        ]
        
        actions
            .map({ payload in UIAlertAction(title: payload.0, style: payload.1, handler: payload.2) })
            .forEach(alertController.addAction(_:))
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.barButtonItem = navigationItem.rightBarButtonItem
        }
        
        present(alertController, animated: true, completion: nil)
    }
    
    func setupGestureRecognizers() {
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        navigationMapView.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    @objc func startNavigation() {
        guard let routeResponse = routeResponse else {
            print("Please select at least one destination coordinate to start navigation.")
            return
        }

        let indexedRouteResponse = IndexedRouteResponse(routeResponse: routeResponse, routeIndex: currentRouteIndex)
        let navigationService = MapboxNavigationService(indexedRouteResponse: indexedRouteResponse,
                                                        customRoutingProvider: NavigationSettings.shared.directions,
                                                        credentials: NavigationSettings.shared.directions.credentials,
                                                        simulating: simulationIsEnabled ? .always : .onPoorGPS)
        
        let navigationOptions = NavigationOptions(navigationService: navigationService)
        let navigationViewController = NavigationViewController(for: indexedRouteResponse,
                                                                navigationOptions: navigationOptions)
        navigationViewController.routeLineTracksTraversal = true
        changeMapStyle(navigationViewController.navigationMapView)
        navigationViewController.modalPresentationStyle = .fullScreen
        
        navigationViewController.routeLineTracksTraversal = true
        
        present(navigationViewController, animated: true, completion: nil)
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        
        let mapView = navigationMapView.mapView
        let destinationCoordinate = mapView?.mapboxMap.coordinate(for: gesture.location(in: mapView))
        requestRoute(destinationCoordinate)
    }
    
    func requestRoute(_ destinationCoordinate: CLLocationCoordinate2D?) {
        guard let userCoordinate = navigationMapView.mapView.location.latestLocation?.coordinate else {
            print("User coordinate is not valid. Make sure to enable Location Services.")
            return
        }
        guard let destinationCoordinate = destinationCoordinate else { return }
        
        let waypoints = [
            Waypoint(coordinate: userCoordinate),
            Waypoint(coordinate: destinationCoordinate)
        ]
        
        let navigationRouteOptions = NavigationRouteOptions(waypoints: waypoints)
        Directions.shared.calculate(navigationRouteOptions) { [weak self] (_, result) in
            switch result {
            case .failure(let error):
                NSLog("Error occured while requesting route: \(error.localizedDescription).")
            case .success(let response):
                guard let routes = response.routes else { return }
                self?.routeResponse = response
                self?.navigationMapView.show(routes)
                if let currentRoute = self?.currentRoute {
                    self?.navigationMapView.showWaypoints(on: currentRoute)
                }
                self?.startButton.isHidden = false
            }
        }
    }
    
    func changeMapStyle(_ navigationMapView: NavigationMapView?) {
        navigationMapView?.traversedRouteColor = .black
        navigationMapView?.trafficUnknownColor = .red
        navigationMapView?.trafficLowColor = .red
        navigationMapView?.trafficUnknownColor = .yellow
        navigationMapView?.trafficLowColor = .purple
        navigationMapView?.trafficModerateColor = .green
        navigationMapView?.trafficHeavyColor = .gray
        navigationMapView?.trafficSevereColor = .orange
        navigationMapView?.alternativeTrafficUnknownColor = .systemPink
        navigationMapView?.alternativeTrafficLowColor = .brown
        navigationMapView?.alternativeTrafficModerateColor = .cyan
        navigationMapView?.alternativeTrafficHeavyColor = .magenta
        navigationMapView?.alternativeTrafficSevereColor = .systemTeal
        navigationMapView?.routeRestrictedAreaColor = .systemTeal
        
        navigationMapView?.routeCasingColor = .red
        navigationMapView?.routeAlternateColor = .orange
        navigationMapView?.routeAlternateCasingColor = .brown
        navigationMapView?.traversedRouteColor = .darkGray
        navigationMapView?.maneuverArrowColor = .blue
        navigationMapView?.maneuverArrowStrokeColor = .systemPink
    }
}

extension RouteLinesStylingViewController: NavigationMapViewDelegate {
    // Delegate method called when the user selects a route
    func navigationMapView(_ mapView: NavigationMapView, didSelect route: Route) {
        self.currentRouteIndex = self.routes?.firstIndex(of: route) ?? 0
    }
}

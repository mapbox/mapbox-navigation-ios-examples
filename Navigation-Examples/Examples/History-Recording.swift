/*
 This code example is part of the Mapbox Navigation SDK for iOS demo app,
 which you can build and run: https://github.com/mapbox/mapbox-navigation-ios-examples
 To learn more about each example in this app, including descriptions and links
 to documentation, see our docs: https://docs.mapbox.com/ios/navigation/examples
 */

import UIKit
import MapboxNavigation
import MapboxCoreNavigation
import MapboxDirections
import MapboxMaps

class HistoryRecordingViewController: UIViewController, NavigationMapViewDelegate, NavigationViewControllerDelegate {
    private let routingProvider = MapboxRoutingProvider()

    var navigationMapView: NavigationMapView! {
        didSet {
            if let navigationMapView = oldValue {
                navigationMapView.removeFromSuperview()
            }
            
            if navigationMapView != nil {
                configure()
            }
        }
    }
    
    private var passiveLocationManager: PassiveLocationManager?
    
    var indexedRouteResponse: IndexedRouteResponse? {
        didSet {
            guard currentRoute != nil else {
                navigationMapView.removeRoutes()
                return
            }
            showCurrentRoute()
        }
    }

    var currentRoute: Route? {
        return indexedRouteResponse?.currentRoute
    }

    var routes: [Route]? {
        return indexedRouteResponse?.routeResponse.routes
    }

    func showCurrentRoute() {
        guard let currentRoute = currentRoute else { return }

        var routes = [currentRoute]
        routes.append(contentsOf: self.routes!.filter {
            $0 != currentRoute
        })
        navigationMapView.showcase(routes)
    }
    
    var startButton: UIButton!
    
    let defaultHistoryDirectoryURL: URL = {
        let basePath: String
        if let applicationSupportPath =
            NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first {
            basePath = applicationSupportPath
        } else {
            basePath = NSTemporaryDirectory()
        }
        let historyDirectoryURL = URL(fileURLWithPath: basePath, isDirectory: true)
            .appendingPathComponent("com.mapbox.Example")
            .appendingPathComponent("NavigationHistory")
        
        if FileManager.default.fileExists(atPath: historyDirectoryURL.path) == false {
            try? FileManager.default.createDirectory(at: historyDirectoryURL,
                                                     withIntermediateDirectories: true,
                                                     attributes: nil)
        }
        return historyDirectoryURL
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if navigationMapView == nil {
            navigationMapView = NavigationMapView(frame: view.bounds)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        PassiveLocationManager.startRecordingHistory()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        PassiveLocationManager.stopRecordingHistory { historyFileUrl in
            guard let historyFileUrl = historyFileUrl else { return }
            print("Free Drive History file has been successfully saved at the path: \(historyFileUrl.path)")
        }
    }
    
    private func configure() {
        
        // Directory setup should be done before `PassiveLocationManager.startRecordingHistory()` call
        PassiveLocationManager.historyDirectoryURL = self.defaultHistoryDirectoryURL
        setupNavigationMapView()
        setupPassiveLocationProvider()
        
        // set long press gesture
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        navigationMapView.addGestureRecognizer(gesture)
        
        // set start button
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
        
    }
    
    private func setupPassiveLocationProvider() {
        let passiveLocationManager = PassiveLocationManager()
        self.passiveLocationManager = passiveLocationManager
        let passiveLocationProvider = PassiveLocationProvider(locationManager: passiveLocationManager)
        navigationMapView.mapView.location.overrideLocationProvider(with: passiveLocationProvider)
        passiveLocationProvider.startUpdatingLocation()
    }
    
    private func setupNavigationMapView() {
        navigationMapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        navigationMapView.userLocationStyle = .puck2D()
        navigationMapView.delegate = self
        view.addSubview(navigationMapView)
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .ended else { return }
        let location = navigationMapView.mapView.mapboxMap.coordinate(for: gesture.location(in: navigationMapView.mapView))
        
        requestRoute(destination: location)
    }
    
    func requestRoute(destination: CLLocationCoordinate2D) {
        guard let userLocation = navigationMapView.mapView.location.latestLocation else { return }
        let location = CLLocation(latitude: userLocation.coordinate.latitude,
                                  longitude: userLocation.coordinate.longitude)
        
        let userWaypoint = Waypoint(location: location,
                                    heading: userLocation.heading,
                                    name: "user")
        
        let destinationWaypoint = Waypoint(coordinate: destination)
        
        let navigationRouteOptions = NavigationRouteOptions(waypoints: [userWaypoint, destinationWaypoint])
        
        routingProvider.calculateRoutes(options: navigationRouteOptions) { [weak self] result in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let indexedRouteResponse):
                guard let self, indexedRouteResponse.currentRoute != nil else { return }

                self.indexedRouteResponse = indexedRouteResponse
                self.startButton?.isHidden = false
            }
        }
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
        navigationViewController.modalPresentationStyle = .fullScreen
        navigationViewController.routeLineTracksTraversal = true
        
        presentAndRemoveNaviagationMapView(navigationViewController)
    }
    
    // Delegate method called when the user selects a route
    func navigationMapView(_ mapView: NavigationMapView, didSelect route: Route) {
        guard let routes = indexedRouteResponse?.routeResponse.routes else { return }

        let currentRouteIndex = routes.firstIndex(of: route) ?? 0
        indexedRouteResponse?.routeIndex = currentRouteIndex
        showCurrentRoute()
    }
    
    func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool) {
        RouteController.stopRecordingHistory { historyFileUrl in
            guard let historyFileUrl = historyFileUrl else { return }
            print("Active Guidance History file has been successfully saved at the path: \(historyFileUrl.path)")
        }
        dismiss(animated: true, completion: nil)
        if navigationMapView == nil {
            navigationMapView = NavigationMapView(frame: view.bounds)
        }
    }
    
    func presentAndRemoveNaviagationMapView(_ navigationViewController: NavigationViewController,
                                            animated: Bool = true,
                                            completion: CompletionHandler? = nil) {

        navigationViewController.modalPresentationStyle = .fullScreen
        present(navigationViewController, animated: animated) {
            completion?()
            self.navigationMapView?.removeFromSuperview()
            self.navigationMapView = nil
            self.passiveLocationManager = nil
            
            // History directory for Active Guidance can be set with `RouteController.historyDirectoryURL`
            // In this example, this line is not required because the history direcotry has alreday been set by `PassiveLocationManager.historyDirectoryURL`.
            RouteController.historyDirectoryURL = self.defaultHistoryDirectoryURL
            
            RouteController.startRecordingHistory()
        }
    }
}

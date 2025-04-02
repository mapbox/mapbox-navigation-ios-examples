/*
 This code example is part of the Mapbox Navigation SDK for iOS demo app,
 which you can build and run: https://github.com/mapbox/mapbox-navigation-ios-examples
 To learn more about each example in this app, including descriptions and links
 to documentation, see our docs: https://docs.mapbox.com/ios/navigation/examples/advanced
 */

import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import MapboxMaps

class AdvancedViewController: UIViewController, NavigationMapViewDelegate, NavigationViewControllerDelegate {
    private let routingProvider = MapboxRoutingProvider()
    
    var navigationMapView: NavigationMapView! {
        didSet {
            if oldValue != nil {
                oldValue.removeFromSuperview()
            }
            
            navigationMapView.translatesAutoresizingMaskIntoConstraints = false
            
            view.insertSubview(navigationMapView, at: 0)
            
            NSLayoutConstraint.activate([
                navigationMapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                navigationMapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                navigationMapView.topAnchor.constraint(equalTo: view.topAnchor),
                navigationMapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
    }
    
    var indexedRouteResponse: IndexedRouteResponse? {
        didSet {
            guard indexedRouteResponse?.currentRoute != nil else {
                navigationMapView.removeRoutes()
                navigationMapView.removeWaypoints()
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
        navigationMapView.showRouteDurations(along: routes)
    }
    
    var startButton: UIButton!
    
    // MARK: - UIViewController lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationMapView = NavigationMapView(frame: view.bounds)
        navigationMapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        navigationMapView.delegate = self
        navigationMapView.userLocationStyle = .puck2D()
        
        let navigationViewportDataSource = NavigationViewportDataSource(navigationMapView.mapView, viewportDataSourceType: .raw)
        navigationViewportDataSource.options.followingCameraOptions.zoomUpdatesAllowed = false
        navigationViewportDataSource.followingMobileCamera.zoom = 13.0
        navigationMapView.navigationCamera.viewportDataSource = navigationViewportDataSource
        
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        navigationMapView.addGestureRecognizer(gesture)
        
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
        
        // Replace default `NavigationMapView` instance with instance that is used in preview mode.
        let navigationOptions = NavigationOptions(navigationService: navigationService,
                                                  navigationMapView: navigationMapView)
        
        let navigationViewController = NavigationViewController(for: indexedRouteResponse,
                                                                navigationOptions: navigationOptions)
        navigationViewController.delegate = self
        navigationViewController.modalPresentationStyle = .fullScreen
        
        if let latestValidLocation = navigationMapView.mapView.location.latestLocation?.location {
            navigationViewController.navigationMapView?.moveUserLocation(to: latestValidLocation)
        }
        
        startButton.isHidden = true
        
        // Hide top and bottom container views before animating their presentation.
        navigationViewController.navigationView.bottomBannerContainerView.hide(animated: false)
        navigationViewController.navigationView.topBannerContainerView.hide(animated: false)
        
        // Hide `WayNameView`, `FloatingStackView` and `SpeedLimitView` to smoothly present them.
        navigationViewController.navigationView.wayNameView.alpha = 0.0
        navigationViewController.navigationView.floatingStackView.alpha = 0.0
        navigationViewController.navigationView.speedLimitView.alpha = 0.0
        
        present(navigationViewController, animated: false) {
            // Animate top and bottom banner views presentation.
            let duration = 1.0
            navigationViewController.navigationView.bottomBannerContainerView.show(duration: duration,
                                                                                   animations: {
                navigationViewController.navigationView.wayNameView.alpha = 1.0
                navigationViewController.navigationView.floatingStackView.alpha = 1.0
                navigationViewController.navigationView.speedLimitView.alpha = 1.0
            })
            navigationViewController.navigationView.topBannerContainerView.show(duration: duration)
        }
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
                guard let self else { return }

                self.indexedRouteResponse = indexedRouteResponse
                self.startButton?.isHidden = false
            }
        }
    }
    
    // Delegate method called when the user selects a route
    func navigationMapView(_ mapView: NavigationMapView, didSelect route: Route) {
        guard let routes = indexedRouteResponse?.routeResponse.routes else { return }

        let currentRouteIndex = routes.firstIndex(of: route) ?? 0
        indexedRouteResponse?.routeIndex = currentRouteIndex
        showCurrentRoute()
    }
    
    func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool) {
        let duration = 1.0
        navigationViewController.navigationView.topBannerContainerView.hide(duration: duration)
        navigationViewController.navigationView.bottomBannerContainerView.hide(duration: duration,
                                                                               animations: {
            navigationViewController.navigationView.wayNameView.alpha = 0.0
            navigationViewController.navigationView.floatingStackView.alpha = 0.0
            navigationViewController.navigationView.speedLimitView.alpha = 0.0
        },
                                                                               completion: { [weak self] _ in
            navigationViewController.dismiss(animated: false) {
                guard let self = self else { return }
                
                // Show previously hidden button that allows to start active navigation.
                self.startButton.isHidden = false
                
                // Since `NavigationViewController` assigns `NavigationMapView`'s delegate to itself,
                // delegate should be re-assigned back to `NavigationMapView` that is used in preview mode.
                self.navigationMapView.delegate = self
                
                // Replace `NavigationMapView` instance with instance that was used in active navigation.
                self.navigationMapView = navigationViewController.navigationMapView
                
                // Since `NavigationViewController` uses `UserPuckCourseView` as a default style
                // of the user location indicator - revert to back to default look in preview mode.
                self.navigationMapView.userLocationStyle = .puck2D()
                
                // Showcase originally requested routes.
                if let routes = self.routes {
                    let cameraOptions = CameraOptions(bearing: 0.0, pitch: 0.0)
                    self.navigationMapView.showcase(routes,
                                                    routesPresentationStyle: .all(shouldFit: true, cameraOptions: cameraOptions),
                                                    animated: true,
                                                    duration: duration)
                }
            }
        })
    }
}

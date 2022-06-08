/*
 This code example is part of the Mapbox Navigation SDK for iOS demo app,
 which you can build and run: https://github.com/mapbox/mapbox-navigation-ios-examples
 To learn more about each example in this app, including descriptions and links
 to documentation, see our docs: https://docs.mapbox.com/ios/navigation/examples/custom-navigation-camera
 */

import UIKit
import MapboxNavigation
import MapboxMaps
import MapboxDirections
import MapboxCoreNavigation

class CustomNavigationCameraViewController: UIViewController {
    
    var navigationMapView: NavigationMapView!
    var routeResponse: RouteResponse!
    var navigationRouteOptions: NavigationRouteOptions!
    var startNavigationButton: UIButton!

    // MARK: - UIViewController lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationMapView()
        setupStartNavigationButton()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        startNavigationButton.layer.cornerRadius = startNavigationButton.bounds.midY
        startNavigationButton.clipsToBounds = true
        startNavigationButton.setNeedsDisplay()
    }
    
    // MARK: - Setting-up methods
    
    func setupNavigationMapView() {
        navigationMapView = NavigationMapView(frame: view.bounds)
        navigationMapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        navigationMapView.userLocationStyle = .puck2D()
        
        // Modify default `NavigationViewportDataSource` and `NavigationCameraStateTransition` to change
        // `NavigationCamera` behavior during free drive and when locations are provided by Maps SDK directly.
        navigationMapView.navigationCamera.viewportDataSource = CustomViewportDataSource(navigationMapView.mapView)
        navigationMapView.navigationCamera.cameraStateTransition = CustomCameraStateTransition(navigationMapView.mapView)
        
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        navigationMapView.addGestureRecognizer(longPressGestureRecognizer)
        
        view.addSubview(navigationMapView)
    }
    
    func setupStartNavigationButton() {
        startNavigationButton = UIButton()
        startNavigationButton.setTitle("Start Navigation", for: .normal)
        startNavigationButton.translatesAutoresizingMaskIntoConstraints = false
        startNavigationButton.backgroundColor = .lightGray
        startNavigationButton.setTitleColor(.darkGray, for: .highlighted)
        startNavigationButton.setTitleColor(.white, for: .normal)
        startNavigationButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        startNavigationButton.addTarget(self, action: #selector(startNavigationButtonPressed(_:)), for: .touchUpInside)
        startNavigationButton.isHidden = true
        view.addSubview(startNavigationButton)
        
        startNavigationButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -20).isActive = true
        startNavigationButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
    }
    
    @objc func startNavigationButtonPressed(_ sender: UIButton) {
        let navigationService = MapboxNavigationService(routeResponse: routeResponse,
                                                        routeIndex: 0,
                                                        routeOptions: navigationRouteOptions,
                                                        customRoutingProvider: NavigationSettings.shared.directions,
                                                        credentials: NavigationSettings.shared.directions.credentials,
                                                        simulating: simulationIsEnabled ? .always : .onPoorGPS)
        
        let navigationOptions = NavigationOptions(navigationService: navigationService)
        let navigationViewController = NavigationViewController(for: routeResponse,
                                                                   routeIndex: 0,
                                                                   routeOptions: navigationRouteOptions,
                                                                   navigationOptions: navigationOptions)
        navigationViewController.modalPresentationStyle = .fullScreen
        
        // Modify default `NavigationViewportDataSource` and `NavigationCameraStateTransition` to change
        // `NavigationCamera` behavior during active guidance.
        if let mapView = navigationViewController.navigationMapView?.mapView {
            let customViewportDataSource = CustomViewportDataSource(mapView)
            navigationViewController.navigationMapView?.navigationCamera.viewportDataSource = customViewportDataSource
            
            let customCameraStateTransition = CustomCameraStateTransition(mapView)
            navigationViewController.navigationMapView?.navigationCamera.cameraStateTransition = customCameraStateTransition
        }
        
        present(navigationViewController, animated: true, completion: nil)
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .ended,
              let origin = navigationMapView.mapView.location.latestLocation?.coordinate else { return }

        let destination = navigationMapView.mapView.mapboxMap.coordinate(for: gesture.location(in: navigationMapView.mapView))
        navigationRouteOptions = NavigationRouteOptions(coordinates: [origin, destination])
        
        Directions.shared.calculate(navigationRouteOptions) { [weak self] (_, result) in
            switch result {
            case .failure(let error):
                NSLog("Error occured while requesting route: \(error.localizedDescription).")
            case .success(let response):
                guard let route = response.routes?.first else { return }
                
                self?.startNavigationButton.isHidden = false
                self?.routeResponse = response
                self?.navigationMapView.show([route])
                self?.navigationMapView.showWaypoints(on: route)
            }
        }
    }
}

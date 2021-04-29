import UIKit
import MapboxNavigation
import MapboxMaps
import MapboxDirections
import MapboxCoreNavigation

class CustomNavigationCameraViewController: UIViewController {
    
    var navigationMapView: NavigationMapView!
    var route: Route!
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
        navigationMapView.mapView.update {
            $0.location.puckType = .puck2D()
        }
        
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
        let navigationService = MapboxNavigationService(route: route,
                                                        routeIndex: 0,
                                                        routeOptions: navigationRouteOptions,
                                                        simulating: simulationIsEnabled ? .always : .onPoorGPS)
        
        let navigationOptions = NavigationOptions(navigationService: navigationService)
        let navigationViewController = NavigationViewController(for: route,
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
              let origin = navigationMapView.mapView.location.latestLocation?.internalLocation.coordinate else { return }

        let destination = navigationMapView.mapView.coordinate(for: gesture.location(in: navigationMapView.mapView))
        navigationRouteOptions = NavigationRouteOptions(coordinates: [origin, destination])
        
        Directions.shared.calculate(navigationRouteOptions) { [weak self] (session, result) in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let response):
                guard let route = response.routes?.first else { return }
                
                self?.startNavigationButton.isHidden = false
                self?.route = route
                self?.navigationMapView.show([route])
                self?.navigationMapView.showWaypoints(on: route)
            }
        }
    }
}

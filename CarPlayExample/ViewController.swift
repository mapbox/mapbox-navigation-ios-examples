import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections

class ViewController: UIViewController {
    
    typealias ActionHandler = (UIAlertAction) -> Void
    
    var navigationMapView: NavigationMapView!
    
    var navigationRouteOptions: NavigationRouteOptions!
    
    var routeResponse: RouteResponse? {
        didSet {
            guard let routes = routeResponse?.routes, let currentRoute = routes.first else {
                navigationMapView.removeRoutes()
                navigationMapView.removeWaypoints()
                waypoints.removeAll()
                return
            }
            
            navigationMapView.show(routes)
            navigationMapView.showWaypoints(on: currentRoute)
        }
    }

    var waypoints: [Waypoint] = []

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
        navigationMapView.delegate = self
        navigationMapView.userLocationStyle = .puck2D()
        
        let navigationViewportDataSource = NavigationViewportDataSource(navigationMapView.mapView,
                                                                        viewportDataSourceType: .raw)
        navigationMapView.navigationCamera.viewportDataSource = navigationViewportDataSource
        
        view.addSubview(navigationMapView)
    }
    
    func setupPerformActionBarButtonItem() {
        let settingsBarButtonItem = UIBarButtonItem(title: NSString(string: "\u{2699}\u{0000FE0E}") as String,
                                                    style: .plain,
                                                    target: self,
                                                    action: #selector(performAction))
        let attributes = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 30)
        ]
        settingsBarButtonItem.setTitleTextAttributes(attributes, for: .normal)
        settingsBarButtonItem.setTitleTextAttributes(attributes, for: .highlighted)
        navigationItem.rightBarButtonItem = settingsBarButtonItem
    }
    
    // MARK: - UIGestureRecognizer related methods
    
    func setupGestureRecognizers() {
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self,
                                                                      action: #selector(handleLongPress(_:)))
        navigationMapView.addGestureRecognizer(longPressGestureRecognizer)
    }

    @objc func performAction(_ sender: Any) {
        let alertController = UIAlertController(title: "Perform action",
                                                message: "Select specific action to perform it",
                                                preferredStyle: .actionSheet)
        
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
    
    func startNavigation() {
        guard let routeResponse = routeResponse,
              let navigationRouteOptions = navigationRouteOptions else {
            presentAlert(message: "Please select at least one destination coordinate to start navigation.")
            return
        }
        
        let navigationService = MapboxNavigationService(routeResponse: routeResponse,
                                                        routeIndex: 0,
                                                        routeOptions: navigationRouteOptions,
                                                        simulating: .always)
        let navigationViewController = NavigationViewController(navigationService: navigationService)
        navigationViewController.delegate = self
        navigationViewController.modalPresentationStyle = .fullScreen
        
        present(navigationViewController, animated: true) {
            let delegate = UIApplication.shared.delegate as? AppDelegate
            
            if #available(iOS 12.0, *),
               let location = navigationService.router.location {
                delegate?.carPlayManager.beginNavigationWithCarPlay(using: location.coordinate,
                                                                    navigationService: navigationService)
            }
        }
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }

        let mapView = navigationMapView.mapView
        createWaypoints(for: mapView?.mapboxMap.coordinate(for: gesture.location(in: mapView)))
        requestRoute()
    }

    func createWaypoints(for destinationCoordinate: CLLocationCoordinate2D?) {
        guard let destinationCoordinate = destinationCoordinate else { return }
        guard let userCoordinate = navigationMapView.mapView.location.latestLocation?.coordinate else {
            presentAlert(message: "User coordinate is not valid. Make sure to enable Location Services.")
            return
        }
        
        // In case if origin waypoint is not present in list of waypoints - add it.
        let userLocationName = "User location"
        let userWaypoint = Waypoint(coordinate: userCoordinate, name: userLocationName)
        if waypoints.first?.name != userLocationName {
            waypoints.insert(userWaypoint, at: 0)
        }
        
        // Add destination waypoint to list of waypoints.
        let waypoint = Waypoint(coordinate: destinationCoordinate)
        waypoint.targetCoordinate = destinationCoordinate
        waypoints.append(waypoint)
    }

    func requestRoute() {
        let navigationRouteOptions = NavigationRouteOptions(waypoints: waypoints)
        Directions.shared.calculate(navigationRouteOptions) { [weak self] (_, result) in
            guard let self = self else { return }
            
            switch result {
            case .failure(let error):
                self.presentAlert(message: error.localizedDescription)
                
                // In case if direction calculation failed - remove last destination waypoint.
                self.waypoints.removeLast()
            case .success(let response):
                self.routeResponse = response
                self.navigationRouteOptions = navigationRouteOptions
            }
        }
    }

    // MARK: - Utility methods

    func presentAlert(_ title: String? = nil, message: String? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
            alertController.dismiss(animated: true, completion: nil)
        }))

        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - NavigationMapViewDelegate methods

extension ViewController: NavigationMapViewDelegate {
    
    func navigationMapView(_ mapView: NavigationMapView, didSelect route: Route) {
        guard let routes = routeResponse?.routes,
              let routeIndex = routes.firstIndex(where: { $0 === route }) else { return }
        
        routeResponse?.routes?.swapAt(routeIndex, 0)
    }
}

// MARK: - NavigationViewControllerDelegate methods

extension ViewController: NavigationViewControllerDelegate {
    
    func navigationViewController(_ navigationViewController: NavigationViewController,
                                  didArriveAt waypoint: Waypoint) -> Bool {
        if navigationViewController.navigationService.router.routeProgress.isFinalLeg {
            return true
        }
        
        // In case of intermediate waypoint - proceed to next leg only after specific delay.
        let delay = 5.0
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
            guard let navigationService = (self.presentedViewController as? NavigationViewController)?.navigationService else { return }
            let router = navigationService.router
            guard router.route.legs.count > router.routeProgress.legIndex + 1 else { return }
            router.routeProgress.legIndex += 1
            
            navigationService.start()
        })
        
        return false
    }
    
    func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController,
                                            byCanceling canceled: Bool) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - UIGestureRecognizerDelegate methods

extension ViewController: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow both route selection and building extrusion when tapping on screen.
        return true
    }
}

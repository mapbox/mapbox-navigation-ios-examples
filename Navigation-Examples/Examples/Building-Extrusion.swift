import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import Mapbox

class BuildingExtrusionViewController: UIViewController, NavigationMapViewDelegate, NavigationViewControllerDelegate, UIGestureRecognizerDelegate {
    
    var mapView: NavigationMapView?
    
    var routeOptions: NavigationRouteOptions?
    
    var currentRoute: Route? {
        get {
            return routes?.first
        }
        set {
            guard let selected = newValue else { routes = nil; return }
            guard let routes = routes else { self.routes = [selected]; return }
            self.routes = [selected] + routes.filter { $0 != selected }
        }
    }
    
    var routes: [Route]? {
        didSet {
            guard let routes = routes, let currentRoute = routes.first else {
                mapView?.removeRoutes()
                mapView?.removeWaypoints()
                waypoints.removeAll()
                return
            }

            mapView?.show(routes)
            mapView?.showWaypoints(on: currentRoute)
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
        mapView = NavigationMapView(frame: view.bounds)
        mapView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView?.userTrackingMode = .follow
        mapView?.navigationMapViewDelegate = self
        mapView?.style?.transition = MGLTransition(duration: 1.0, delay: 1.0)
        
        // To make sure that buildings are rendered increase zoomLevel to value which is higher than 16.0.
        // More details can be found here: https://docs.mapbox.com/vector-tiles/reference/mapbox-streets-v8/#building
        mapView?.zoomLevel = 17.0
        
        view.addSubview(mapView!)
    }
    
    func setupPerformActionBarButtonItem() {
        let settingsBarButtonItem = UIBarButtonItem(title: NSString(string: "\u{2699}\u{0000FE0E}") as String, style: .plain, target: self, action: #selector(performAction))
        settingsBarButtonItem.setTitleTextAttributes([.font : UIFont.systemFont(ofSize: 30)], for: .normal)
        settingsBarButtonItem.setTitleTextAttributes([.font : UIFont.systemFont(ofSize: 30)], for: .highlighted)
        navigationItem.rightBarButtonItem = settingsBarButtonItem
    }
    
    // MARK: - UIGestureRecognizer related methods
    
    func setupGestureRecognizers() {
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        mapView?.addGestureRecognizer(longPressGestureRecognizer)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapGestureRecognizer.delegate = self
        mapView?.addGestureRecognizer(tapGestureRecognizer)
    }

    @objc func performAction(_ sender: Any) {
        let alertController = UIAlertController(title: "Perform action",
                                                message: "Select specific action to perform it", preferredStyle: .actionSheet)
        
        typealias ActionHandler = (UIAlertAction) -> Void
        
        let startNavigation: ActionHandler = { _ in self.startNavigation() }
        let toggleDayNightStyle: ActionHandler = { _ in self.toggleDayNightStyle() }
        let unhighlightBuildings: ActionHandler = { _ in self.unhighlightBuildings() }
        let removeRoutes: ActionHandler = { _ in self.routes = nil }
        
        let actions: [(String, UIAlertAction.Style, ActionHandler?)] = [
            ("Start Navigation", .default, startNavigation),
            ("Toggle Day/Night Style", .default, toggleDayNightStyle),
            ("Unhighlight Buildings", .default, unhighlightBuildings),
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
        guard let route = currentRoute, let routeOptions = routeOptions else {
            presentAlert(message: "Please select at least one destination coordinate to start navigation.")
            return
        }

        let navigationService = MapboxNavigationService(route: route, routeIndex: 0, routeOptions: routeOptions, simulating: simulationIsEnabled ? .always : .onPoorGPS)
        let navigationOptions = NavigationOptions(navigationService: navigationService)
        let navigationViewController = NavigationViewController(for: route, routeIndex: 0, routeOptions: routeOptions, navigationOptions: navigationOptions)
        navigationViewController.routeLineTracksTraversal = true
        navigationViewController.delegate = self
        navigationViewController.modalPresentationStyle = .fullScreen
        navigationViewController.mapView?.styleURL = self.mapView?.styleURL
        
        // Set `waypointStyle` to either `.building` or `.extrudedBuilding` to allow
        // building highighting in 2D or 3D respectively.
        navigationViewController.waypointStyle = .extrudedBuilding
        
        present(navigationViewController, animated: true, completion: nil)
    }
    
    func toggleDayNightStyle() {
        if mapView?.styleURL == MGLStyle.navigationNightStyleURL {
            mapView?.styleURL = MGLStyle.navigationDayStyleURL
        } else {
            mapView?.styleURL = MGLStyle.navigationNightStyleURL
        }
    }
    
    func unhighlightBuildings() {
        waypoints.forEach({ $0.targetCoordinate = nil })
        mapView?.unhighlightBuildings()
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }

        createWaypoints(for: mapView?.convert(gesture.location(in: mapView), toCoordinateFrom: mapView))
        requestRoute()
    }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        // In case if route is already shown on map do not allow selection of buildings other than final destination.
        if let _ = currentRoute, let _ = routeOptions { return }
        guard let destination = mapView?.convert(gesture.location(in: mapView), toCoordinateFrom: mapView) else { return }
        mapView?.highlightBuildings(at: [destination], in3D: true)
    }

    func createWaypoints(for destinationCoordinate: CLLocationCoordinate2D?) {
        guard let destinationCoordinate = destinationCoordinate else { return }
        guard let userLocation = mapView?.userLocation?.location else {
            presentAlert(message: "User location is not valid. Make sure to enable Location Services.")
            return
        }

        // Unhighlight all buildings in case if there are no previous destination waypoints.
        if waypoints.isEmpty {
            unhighlightBuildings()
        }
        
        // In case if origin waypoint is not present in list of waypoints - add it.
        let userLocationName = "User location"
        let userWaypoint = Waypoint(coordinate: userLocation.coordinate, name: userLocationName)
        if waypoints.first?.name != userLocationName {
            waypoints.insert(userWaypoint, at: 0)
        }

        // Add destination waypoint to list of waypoints.
        let waypoint = Waypoint(coordinate: destinationCoordinate)
        waypoint.targetCoordinate = destinationCoordinate
        waypoints.append(waypoint)
    }

    func requestRoute() {
        let routeOptions = NavigationRouteOptions(waypoints: waypoints)
        Directions.shared.calculate(routeOptions) { [weak self] (session, result) in
            switch result {
            case .failure(let error):
                self?.presentAlert(message: error.localizedDescription)

                // In case if direction calculation failed - remove last destination waypoint.
                self?.waypoints.removeLast()
            case .success(let response):
                guard let routes = response.routes else { return }
                self?.routeOptions = routeOptions
                self?.routes = routes
                self?.mapView?.show(routes)
                if let currentRoute = self?.currentRoute {
                    self?.mapView?.showWaypoints(on: currentRoute)
                }

                if let coordinates = self?.waypoints.compactMap({ $0.targetCoordinate }) {
                    self?.mapView?.highlightBuildings(at: coordinates, in3D: true)
                }
            }
        }
    }
    
    // MARK: - NavigationMapViewDelegate methods
    
    func navigationMapView(_ mapView: NavigationMapView, didSelect route: Route) {
        self.currentRoute = route
    }
    
    // MARK: - NavigationViewControllerDelegate methods
    
    func navigationViewController(_ navigationViewController: NavigationViewController, didArriveAt waypoint: Waypoint) -> Bool {
        if navigationViewController.navigationService.router.routeProgress.isFinalLeg {
            return true
        }
        
        // In case of intermediate waypoint - proceed to next leg only after specific delay.
        let delay = 5.0
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
            guard let navigationService = (self.presentedViewController as? NavigationViewController)?.navigationService else { return }
            guard let router = navigationService.router, router.route.legs.count > router.routeProgress.legIndex + 1 else { return }
            router.routeProgress.legIndex += 1
            
            navigationService.start()
        })
        
        return false
    }
    
    func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - UIGestureRecognizerDelegate methods

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow both route selection and building extrusion when tapping on screen.
        return true
    }

    // MARK: - Utility methods

    func presentAlert(_ title: String? = nil, message: String? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            alertController.dismiss(animated: true, completion: nil)
        }))

        present(alertController, animated: true, completion: nil)
    }
}

import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import Mapbox

class BuildingExtrusionViewController: UIViewController, NavigationMapViewDelegate, NavigationViewControllerDelegate, MGLMapViewDelegate {
    
    var mapView: NavigationMapView?
    
    var routeOptions: NavigationRouteOptions?
    
    var currentRoute: Route? {
        get {
            return routes?.first
        }
        set {
            guard let selected = newValue else { routes?.remove(at: 0); return }
            guard let routes = routes else { self.routes = [selected]; return }
            self.routes = [selected] + routes.filter { $0 != selected }
        }
    }
    
    var routes: [Route]? {
        didSet {
            guard let routes = routes, let current = routes.first else { mapView?.removeRoutes(); return }
            mapView?.show(routes)
            mapView?.showWaypoints(on: current)
        }
    }
        
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
        mapView?.delegate = self
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
        mapView?.addGestureRecognizer(tapGestureRecognizer)
    }

    @objc func performAction(_ sender: Any) {
        let alertController = UIAlertController(title: "Perform action",
                                                message: "Select specific action to perform it", preferredStyle: .actionSheet)
        
        typealias ActionHandler = (UIAlertAction) -> Void
        
        let startNavigation: (UIAlertAction) -> Void = { _ in self.startNavigation()}
        let toggleDayNightStyle: (UIAlertAction) -> Void = { _ in self.toggleDayNightStyle()}
        let unhighlightBuildings: (UIAlertAction) -> Void = { _ in self.unhighlightBuildings()}
        let removeRoutes: (UIAlertAction) -> Void = { _ in self.removeRoutes()}
        
        let actions: [(String, UIAlertAction.Style, ActionHandler?)] = [
            ("Start Navigation", .default, startNavigation),
            ("Toggle Day/Night Style", .default, toggleDayNightStyle),
            ("Unhighlight Buildings", .default, unhighlightBuildings),
            ("Remove Routes", .default, removeRoutes),
            ("Cancel", .cancel, nil)
        ]
        
        actions
            .map { payload in UIAlertAction(title: payload.0, style: payload.1, handler: payload.2) }
            .forEach(alertController.addAction(_:))
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.barButtonItem = navigationItem.rightBarButtonItem
        }
        
        present(alertController, animated: true, completion: nil)
    }
    
    func startNavigation() {
        guard let route = currentRoute, let routeOptions = routeOptions else { return }
        
        let navigationService = MapboxNavigationService(route: route, routeOptions: routeOptions, simulating: simulationIsEnabled ? .always : .onPoorGPS)
        let navigationOptions = NavigationOptions(navigationService: navigationService)
        let navigationViewController = NavigationViewController(for: route, routeOptions: routeOptions, navigationOptions: navigationOptions)
        navigationViewController.mapView?.routeLineTracksTraversal = true
        navigationViewController.delegate = self
        navigationViewController.modalPresentationStyle = .fullScreen
        navigationViewController.mapView?.styleURL = self.mapView?.styleURL
        
        // Set `highlightDestinationBuildings` to allow building highighting.
        navigationViewController.highlightDestinationBuildings = true
        
        // Set `highlightBuildingsIn3D` to allow building highighting in either 2D or 3D mode.
        // In case if `highlightDestinationBuildings` is set to `false` changing this property will not have any effect.
        navigationViewController.highlightBuildingsIn3D = true
        
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
        mapView?.unhighlightBuildings()
    }
    
    func removeRoutes() {
        mapView?.removeRoutes()
        mapView?.removeWaypoints()
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        guard let destination = mapView?.convert(gesture.location(in: mapView), toCoordinateFrom: mapView) else { return }
        
        requestRoute(destination: destination)
        mapView?.highlightBuildings(for: [destination], in3D: true)
    }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let destination = mapView?.convert(gesture.location(in: mapView), toCoordinateFrom: mapView) else { return }
        mapView?.highlightBuildings(for: [destination], in3D: true)
    }
    
    func requestRoute(destination: CLLocationCoordinate2D) {
        guard let userLocation = mapView?.userLocation!.location else { return }
        let userWaypoint = Waypoint(location: userLocation, heading: mapView?.userLocation?.heading, name: "user")
        let destinationWaypoint = Waypoint(coordinate: destination)
        
        // Make sure to set `targetCoordinate` of building you'd like to highlight
        destinationWaypoint.targetCoordinate = destination

        let routeOptions = NavigationRouteOptions(waypoints: [userWaypoint, destinationWaypoint])
        
        Directions.shared.calculate(routeOptions) { [weak self] (session, result) in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let response):
                guard let routes = response.routes, let strongSelf = self else { return }
                
                strongSelf.routeOptions = routeOptions
                strongSelf.routes = routes
                strongSelf.mapView?.show(routes)
                strongSelf.mapView?.showWaypoints(on: strongSelf.currentRoute!)
            }
        }
    }
    
    // MARK: - NavigationMapViewDelegate methods
    
    func navigationMapView(_ mapView: NavigationMapView, didSelect route: Route) {
        self.currentRoute = route
    }
    
    // MARK: - NavigationViewControllerDelegate methods
    
    func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - MGLMapViewDelegate methods
    
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        removeRoutes()
    }
}

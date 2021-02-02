import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import Mapbox


class NavigationViewRouteLineStylingViewController: UIViewController, MGLMapViewDelegate, CLLocationManagerDelegate, NavigationMapViewDelegate, NavigationViewControllerDelegate {
    
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
    var startButton: UIButton?
    var locationManager = CLLocationManager()
    
    private typealias RouteRequestSuccess = (([Route]) -> Void)
    private typealias RouteRequestFailure = ((NSError) -> Void)
    
    //MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        mapView = NavigationMapView(frame: view.bounds)
        mapView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView?.userTrackingMode = .follow
        mapView?.delegate = self
        mapView?.navigationMapViewDelegate = self
        
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        mapView?.addGestureRecognizer(gesture)
        
        view.addSubview(mapView!)
        
        startButton = UIButton()
        startButton?.setTitle("Start Navigation", for: .normal)
        startButton?.translatesAutoresizingMaskIntoConstraints = false
        startButton?.backgroundColor = .blue
        startButton?.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        startButton?.addTarget(self, action: #selector(tappedButton(sender:)), for: .touchUpInside)
        startButton?.isHidden = true
        view.addSubview(startButton!)
        startButton?.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -20).isActive = true
        startButton?.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        view.setNeedsLayout()
    }
    
    //overriding layout lifecycle callback so we can style the start button
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        startButton?.layer.cornerRadius = startButton!.bounds.midY
        startButton?.clipsToBounds = true
        startButton?.setNeedsDisplay()
        
    }

    @objc func tappedButton(sender: UIButton) {
        guard let route = currentRoute, let routeOptions = routeOptions else { return }
        // For demonstration purposes, simulate locations if the Simulate Navigation option is on.
        let navigationService = MapboxNavigationService(route: route, routeIndex: 0, routeOptions: routeOptions, simulating: simulationIsEnabled ? .always : .onPoorGPS)
        
        // Set the custom turn-by-turn style with NavigationOptions
        let navigationOptions = NavigationOptions(styles: [CustomRouteLineStyle()], navigationService: navigationService)
        let navigationViewController = NavigationViewController(for: route, routeIndex: 0, routeOptions: routeOptions, navigationOptions: navigationOptions)
        navigationViewController.delegate = self
        
        // Render the passed portion of the route with full transparency
        navigationViewController.routeLineTracksTraversal = true
        navigationViewController.modalPresentationStyle = .fullScreen
        
        present(navigationViewController, animated: true, completion: nil)
    }
    
     @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .ended else { return }
        
        let spot = gesture.location(in: mapView)
        guard let location = mapView?.convert(spot, toCoordinateFrom: mapView) else { return }
        
        requestRoute(destination: location)
    }

    func requestRoute(destination: CLLocationCoordinate2D) {
        guard let userLocation = mapView?.userLocation!.location else { return }
        let userWaypoint = Waypoint(location: userLocation, heading: mapView?.userLocation?.heading, name: "user")
        let destinationWaypoint = Waypoint(coordinate: destination)
        
        let routeOptions = NavigationRouteOptions(waypoints: [userWaypoint, destinationWaypoint])
        
        Directions.shared.calculate(routeOptions) { [weak self] (session, result) in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let response):
                guard let routes = response.routes, let strongSelf = self else {
                    return
                }
                strongSelf.routeOptions = routeOptions
                strongSelf.routes = routes
                strongSelf.startButton?.isHidden = false
                strongSelf.mapView?.show(routes)
                strongSelf.mapView?.showWaypoints(on: strongSelf.currentRoute!)
            }
        }
    }
    
    // Delegate method called when the user selects a route
    func navigationMapView(_ mapView: NavigationMapView, didSelect route: Route) {
        self.currentRoute = route
    }
    
    func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool) {
        dismiss(animated: true, completion: nil)
    }
}

class CustomRouteLineStyle: DayStyle {
    required init() {
        super.init()
        mapStyleURL = URL(string: "mapbox://styles/mapbox/dark-v10")!
        styleType = .day
    }
    
    // Override individual traffic level colors to change the route line appearance in turn-by-turn mode
    // To make the route line one color set all of the traffic layers to that color
    override func apply() {
        super.apply()
        NavigationMapView.appearance().trafficLowColor = UIColor.purple
        NavigationMapView.appearance().trafficModerateColor = UIColor.purple
        NavigationMapView.appearance().trafficHeavyColor = UIColor.purple
        NavigationMapView.appearance().trafficSevereColor = UIColor.purple
        NavigationMapView.appearance().trafficUnknownColor = UIColor.purple
        NavigationMapView.appearance().routeCasingColor = UIColor.green
    }
}

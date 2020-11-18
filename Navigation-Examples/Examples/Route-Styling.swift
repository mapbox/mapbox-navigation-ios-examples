import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import Mapbox
import Turf

extension UIColor {
    
    static var random: UIColor {
        return UIColor(red: .random(in: 0...1),
                       green: .random(in: 0...1),
                       blue: .random(in: 0...1),
                       alpha: 1.0)
    }
}

class RouteStylingViewController: UIViewController, NavigationMapViewDelegate {
    
    var mapView: NavigationMapView?
        
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
                routeColors.removeAll()
                
                return
            }

            mapView?.show(routes)
            mapView?.showWaypoints(on: currentRoute)
        }
    }

    var waypoints: [Waypoint] = []
    
    /**
     Property which holds information regarding route priority (whether it's main or alternative) and coloring.
     */
    var routeColors: [String: (Bool, UIColor)] = [:]
    
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
    }

    @objc func performAction(_ sender: Any) {
        let alertController = UIAlertController(title: "Perform action",
                                                message: "Select specific action to perform it", preferredStyle: .actionSheet)
        
        typealias ActionHandler = (UIAlertAction) -> Void
        
        let removeRoutes: ActionHandler = { _ in self.routes = nil }
        
        let actions: [(String, UIAlertAction.Style, ActionHandler?)] = [
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
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }

        createWaypoints(for: mapView?.convert(gesture.location(in: mapView), toCoordinateFrom: mapView))
        requestRoute()
    }

    func createWaypoints(for destinationCoordinate: CLLocationCoordinate2D?) {
        guard let destinationCoordinate = destinationCoordinate else { return }
        guard let userLocation = mapView?.userLocation?.location else {
            presentAlert(message: "User location is not valid. Make sure to enable Location Services.")
            return
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
                self?.routes = routes
                if let currentRoute = self?.currentRoute {
                    self?.mapView?.showWaypoints(on: currentRoute)
                }
            }
        }
    }
    
    // MARK: - NavigationMapViewDelegate methods
    
    func navigationMapView(_ mapView: NavigationMapView, didSelect route: Route) {
        self.currentRoute = route
    }
    
    func navigationMapView(_ mapView: NavigationMapView, mainRouteStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        let layer = MGLLineStyleLayer(identifier: identifier, source: source)
        layer.predicate = NSPredicate(format: "isAlternateRoute == false")

        let element = routeColors[identifier]
        let color = #colorLiteral(red: 0.337254902, green: 0.6588235294, blue: 0.9843137255, alpha: 1)
        if element == nil {
            routeColors[identifier] = (true, color)
        }

        layer.lineColor = NSExpression(forConstantValue: color)
        layer.lineWidth = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", MBRouteLineWidthByZoomLevel.multiplied(by: 0.8))
        layer.lineJoin = NSExpression(forConstantValue: "round")
        layer.lineCap = NSExpression(forConstantValue: "miter")

        // In case if congestion segments are available - draw them.
        if let mainRoute = routes?.first,
           let source = source as? MGLShapeSource,
           let shape = source.shape as? MGLShapeCollectionFeature,
           let congestionSegments = shape.shapes as? Array<MGLPolylineFeature> {
            layer.lineGradient = routeLineGradient(mainRoute, congestionSegments: congestionSegments)
        }
        
        return layer
    }

    func navigationMapView(_ mapView: NavigationMapView, mainRouteCasingStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        let layer = MGLLineStyleLayer(identifier: identifier, source: source)
        layer.predicate = NSPredicate(format: "isAlternateRoute == false")

        let element = routeColors[identifier]
        let color = #colorLiteral(red: 0.1843137255, green: 0.4784313725, blue: 0.7764705882, alpha: 1)
        if element == nil {
            routeColors[identifier] = (true, color)
        }

        layer.lineColor = NSExpression(forConstantValue: color)
        layer.lineWidth = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", MBRouteLineWidthByZoomLevel.multiplied(by: 1.2))
        layer.lineJoin = NSExpression(forConstantValue: "round")
        layer.lineCap = NSExpression(forConstantValue: "miter")

        return layer
    }

    func navigationMapView(_ mapView: NavigationMapView, alternativeRouteStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        let layer = MGLLineStyleLayer(identifier: identifier, source: source)
        layer.predicate = NSPredicate(format: "isAlternateRoute == true")

        let element = routeColors[identifier]
        var color = UIColor.gray
        if let element = element {
            if element.0 == false {
                color = element.1
            }
        } else {
            color = UIColor.random
            routeColors[identifier] = (false, color)
        }

        layer.lineColor = NSExpression(forConstantValue: color)
        layer.lineWidth = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", MBRouteLineWidthByZoomLevel.multiplied(by: 0.8))
        layer.lineJoin = NSExpression(forConstantValue: "round")
        layer.lineCap = NSExpression(forConstantValue: "miter")

        return layer
    }

    func navigationMapView(_ mapView: NavigationMapView, alternativeRouteCasingStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        let layer = MGLLineStyleLayer(identifier: identifier, source: source)
        layer.predicate = NSPredicate(format: "isAlternateRoute == true")

        let element = routeColors[identifier]
        var color = UIColor.darkGray
        if let element = element {
            if element.0 == false {
                color = element.1
            }
        } else {
            color = UIColor.random
            routeColors[identifier] = (false, color)
        }

        layer.lineColor = NSExpression(forConstantValue: color)
        layer.lineWidth = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", MBRouteLineWidthByZoomLevel.multiplied(by: 1.2))
        layer.lineJoin = NSExpression(forConstantValue: "round")
        layer.lineCap = NSExpression(forConstantValue: "miter")

        return layer
    }
    
    func navigationMapView(_ mapView: NavigationMapView, shapeFor routes: [Route]) -> MGLShape? {
        guard let mainRoute = routes.first else { return nil }
        
        return MGLShapeCollectionFeature(shapes: shape(mainRoute))
    }

    func navigationMapView(_ mapView: NavigationMapView, simplifiedShapeFor route: Route) -> MGLShape? {
        let mainRoute = MGLPolylineFeature(route.shape!)
        mainRoute.attributes["isAlternateRoute"] = false

        return MGLShapeCollectionFeature(shapes: [mainRoute])
    }
    
    // MARK: - Utility methods

    func presentAlert(_ title: String? = nil, message: String? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            alertController.dismiss(animated: true, completion: nil)
        }))

        present(alertController, animated: true, completion: nil)
    }
    
    func congestionColor(_ congestionLevel: CongestionLevel?) -> UIColor {
        switch congestionLevel {
        case .low:
            return #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
        case .moderate:
            return #colorLiteral(red: 1, green: 0.5843137255, blue: 0, alpha: 1)
        case .heavy:
            return #colorLiteral(red: 1, green: 0.3019607843, blue: 0.3019607843, alpha: 1)
        case .severe:
            return #colorLiteral(red: 0.5607843137, green: 0.1411764706, blue: 0.2784313725, alpha: 1)
        default:
            return #colorLiteral(red: 0.337254902, green: 0.6588235294, blue: 0.9843137255, alpha: 0.949406036)
        }
    }
    
    /**
     Method which allows to convert array of congestion levels into `NSExpression`, which can be later consumed by `MGLLineStyleLayer`.
     */
    func routeLineGradient(_ route: Route, congestionSegments: [MGLPolylineFeature]) -> NSExpression? {
        var gradientStops = [CGFloat: UIColor]()
        var traversedDistance = 0.0
        
        for segment in congestionSegments {
            segment.getCoordinates(segment.coordinates, range: NSMakeRange(0, Int(segment.pointCount)))
            
            let buffPtr = UnsafeMutableBufferPointer(start: segment.coordinates, count: Int(segment.pointCount))
            guard let distance = LineString(Array(buffPtr)).distance() else { return nil }
            guard let congestionLevel = segment.attributes[MBCongestionAttribute] as? String else { return nil }
            let associatedCongestionColor = congestionColor(CongestionLevel(rawValue: congestionLevel))
            
            let segmentStart = CGFloat(traversedDistance / route.distance)
            gradientStops[segmentStart] = associatedCongestionColor
            
            traversedDistance = traversedDistance + distance
            
            let segmentEnd = CGFloat(traversedDistance / route.distance)
            gradientStops[segmentEnd] = associatedCongestionColor
        }
        
        if !gradientStops.isEmpty {
            return NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($lineProgress, 'linear', nil, %@)", NSDictionary(dictionary: gradientStops))
        }
        
        return nil
    }

    /**
     Method which allows to provide a custom congestion level for whole main route.
     */
    func shape(_ route: Route) -> [MGLPolylineFeature] {
        var shape: [MGLPolylineFeature] = []
        
        for leg in route.legs {
            let coordinates: [CLLocationCoordinate2D] = leg.steps.enumerated().reduce([]) { allCoordinates, current in
                let stepCoordinates = current.element.shape!.coordinates
                
                return current.offset == 0 ? stepCoordinates : allCoordinates + stepCoordinates.suffix(from: 1)
            }
            
            if let congestionLevel = CongestionLevel.allCases.randomElement() {
                let polyline = MGLPolylineFeature(coordinates: coordinates, count: UInt(coordinates.count))
                polyline.attributes[MBCongestionAttribute] = String(describing: congestionLevel)
                polyline.attributes["isAlternateRoute"] = false
                shape.append(polyline)
            }
        }
        
        return shape
    }
}

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

class RouteLineStylingViewController: UIViewController, NavigationMapViewDelegate {
    
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
        layer.lineWidth = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", MBRouteLineWidthByZoomLevel.multiplied(by: 0.8))
        layer.lineJoin = NSExpression(forConstantValue: "round")
        layer.lineCap = NSExpression(forConstantValue: "miter")

        // In case if congestion segments are available - draw them.
        if let mainRoute = routes?.first, let congestionSegments = addCongestion(mainRoute) {
            layer.lineGradient = routeLineGradient(mainRoute, congestionSegments: congestionSegments)
        }
        
        return layer
    }
    
    func navigationMapView(_ mapView: NavigationMapView, shapeFor routes: [Route]) -> MGLShape? {
        guard let mainRoute = routes.first else { return nil }
        
        return MGLShapeCollectionFeature(shapes: shape(mainRoute))
    }
    
    // MARK: - Utility methods

    func presentAlert(_ title: String? = nil, message: String? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            alertController.dismiss(animated: true, completion: nil)
        }))

        present(alertController, animated: true, completion: nil)
    }

    /**
     Method which allows to provide a custom congestion level for whole main route.
     */
    func shape(_ route: Route) -> [MGLPolylineFeature] {
        let mainRoute = MGLPolylineFeature(route.shape!)
        mainRoute.attributes["isAlternateRoute"] = false

        return [mainRoute]
    }
    
    func combine(_ coordinates: [CLLocationCoordinate2D], with congestions: [CongestionLevel]) -> [CongestionSegment] {
        var segments: [CongestionSegment] = []
        segments.reserveCapacity(congestions.count)
        for (firstSegment, congestionLevel) in zip(zip(coordinates, coordinates.suffix(from: 1)), congestions) {
            let coordinates = [firstSegment.0, firstSegment.1]
            if segments.last?.1 == congestionLevel {
                segments[segments.count - 1].0 += coordinates
            } else {
                segments.append((coordinates, congestionLevel))
            }
        }
        return segments
    }
    
    typealias CongestionSegment = ([CLLocationCoordinate2D], CongestionLevel)
    
    func routeLineGradient(_ route: Route, fractionTraveled: Double = 0.0, congestionSegments: [MGLPolylineFeature]) -> NSExpression? {
        var gradientStops = [CGFloat: UIColor]()
        
        /**
         We will keep track of this value as we iterate through
         the various congestion segments.
         */
        var distanceTraveled = fractionTraveled
        
        /**
         To create the stops dictionary that represents the route line expressed
         as gradients, for every congestion segment we need one pair of dictionary
         entries to represent the color to be displayed between that range. Depending
         on the index of the congestion segment, the pair's first or second key
         will have a buffer value added or subtracted to make room for a gradient
         transition between congestion segments.
         
         green       gradient       red
         transition
         |-----------|~~~~~~~~~~~~|----------|
         0         0.499        0.501       1.0
         */
        for (index, line) in congestionSegments.enumerated() {
            line.getCoordinates(line.coordinates, range: NSMakeRange(0, Int(line.pointCount)))
            // `UnsafeMutablePointer` is needed here to get the line’s coordinates.
            let buffPtr = UnsafeMutableBufferPointer(start: line.coordinates, count: Int(line.pointCount))
            let lineCoordinates = Array(buffPtr)
            
            // Get congestion color for the stop.
            let congestionLevel = line.attributes["congestion"] as? String
            let associatedCongestionColor = congestionColor(for: congestionLevel)
            
            // Measure the line length of the traffic segment.
            let lineString = LineString(lineCoordinates)
            guard let distance = lineString.distance() else { return nil }
            
            /**
             If this is the first congestion segment, then the starting
             percentage point will be zero.
             */
            if index == congestionSegments.startIndex {
                distanceTraveled = distanceTraveled + distance
                
                let segmentEndPercentTraveled = CGFloat((distanceTraveled / route.distance))
                gradientStops[segmentEndPercentTraveled.nextDown] = associatedCongestionColor
                continue
            }
            
            /**
             If this is the last congestion segment, then the ending
             percentage point will be 1.0, to represent 100%.
             */
            if index == congestionSegments.endIndex - 1 {
                let segmentEndPercentTraveled = CGFloat(1.0)
                gradientStops[segmentEndPercentTraveled.nextDown] = associatedCongestionColor
                continue
            }
            
            /**
             If this is not the first or last congestion segment, then
             the starting and ending percent values traveled for this segment
             will be a fractional amount more/less than the actual values.
             */
            let segmentStartPercentTraveled = CGFloat((distanceTraveled / route.distance))
            gradientStops[segmentStartPercentTraveled.nextUp] = associatedCongestionColor
            
            distanceTraveled = distanceTraveled + distance
            
            let segmentEndPercentTraveled = CGFloat((distanceTraveled / route.distance))
            gradientStops[segmentEndPercentTraveled.nextDown] = associatedCongestionColor
        }
        
        let percentTraveled = CGFloat(fractionTraveled)
        
        // Filter out only the stops that are greater than or equal to the percent of the route traveled.
        var filteredGradientStops = gradientStops.filter { key, value in
            return key >= percentTraveled
        }
        
        // Then, get the lowest value from the above and fade the range from zero that lowest value,
        // which represents the % of the route traveled.
        if let minStop = filteredGradientStops.min(by: { $0.0 < $1.0 }) {
            filteredGradientStops[0.0] = .clear
            filteredGradientStops[percentTraveled.nextDown] = .clear
            filteredGradientStops[percentTraveled] = minStop.value
        }
        
        // It's not possible to create line gradient in case if there are no route gradient stops.
        if !filteredGradientStops.isEmpty {
            // Dictionary usage is causing crashes in Release mode (when built with optimization SWIFT_OPTIMIZATION_LEVEL = -O flag).
            // Even though Dictionary contains valid objects prior to passing it to NSExpression:
            // [0.4109119609930762: UIExtendedSRGBColorSpace 0.952941 0.65098 0.309804 1,
            // 0.4109119609930761: UIExtendedSRGBColorSpace 0.337255 0.658824 0.984314 1]
            // keys become nil in NSExpression arguments list:
            // [0.4109119609930762 = nil,
            // 0.4109119609930761 = nil]
            // Passing NSDictionary with all data from original Dictionary to NSExpression fixes issue.
            return NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($lineProgress, 'linear', nil, %@)", NSDictionary(dictionary: filteredGradientStops))
        }
        return nil
    }
    
    func congestionColor(for congestionLevel: String?) -> UIColor {
        switch congestionLevel {
        case "low":
            return #colorLiteral(red: 0.337254902, green: 0.6588235294, blue: 0.9843137255, alpha: 0.949406036)
        case "moderate":
            return #colorLiteral(red: 1, green: 0.5843137255, blue: 0, alpha: 1)
        case "heavy":
            return #colorLiteral(red: 1, green: 0.3019607843, blue: 0.3019607843, alpha: 1)
        case "severe":
            return #colorLiteral(red: 0.5607843137, green: 0.1411764706, blue: 0.2784313725, alpha: 1)
        default:
            return #colorLiteral(red: 0.337254902, green: 0.6588235294, blue: 0.9843137255, alpha: 0.949406036)
        }
    }
    
    func addCongestion(_ route: Route) -> [MGLPolylineFeature]? {
        guard let coordinates = route.shape?.coordinates else { return nil }

        var linesPerLeg: [MGLPolylineFeature] = []

        for leg in route.legs {
            let lines: [MGLPolylineFeature]
            if let legCongestion = leg.segmentCongestionLevels, legCongestion.count < coordinates.count {
                // The last coord of the preceding step, is shared with the first coord of the next step, we don't need both.
                let legCoordinates: [CLLocationCoordinate2D] = leg.steps.enumerated().reduce([]) { allCoordinates, current in
                    let index = current.offset
                    let step = current.element
                    let stepCoordinates = step.shape!.coordinates
                    
                    return index == 0 ? stepCoordinates : allCoordinates + stepCoordinates.suffix(from: 1)
                }
                
                let mergedCongestionSegments = combine(legCoordinates, with: legCongestion)
                
                lines = mergedCongestionSegments.map { (congestionSegment: CongestionSegment) -> MGLPolylineFeature in
                    let polyline = MGLPolylineFeature(coordinates: congestionSegment.0, count: UInt(congestionSegment.0.count))
                    polyline.attributes[MBCongestionAttribute] = String(describing: congestionSegment.1)
                    return polyline
                }
            } else {
                // If there is no congestion, don't try and add it
                lines = [MGLPolylineFeature(route.shape!)]
            }
            
            for line in lines {
                line.attributes["isAlternateRoute"] = false
            }
            
            linesPerLeg.append(contentsOf: lines)
        }

        return linesPerLeg
    }
}

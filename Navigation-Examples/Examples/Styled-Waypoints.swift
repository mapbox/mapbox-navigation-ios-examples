import Foundation
import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections

class StyledWaypointsViewController: UIViewController, NavigationMapViewDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let origin = Waypoint(coordinate: CLLocationCoordinate2DMake(45.52515652781534, -122.67857551574706), coordinateAccuracy: -1, name: "Origin")
        let pickup = Waypoint(coordinate: CLLocationCoordinate2DMake(45.52054115838411, -122.67076492309569), coordinateAccuracy: -1, name: "Pickup")
        let dropoff = Waypoint(coordinate: CLLocationCoordinate2DMake(45.52054115838411, -122.67076492309569), coordinateAccuracy: -1, name: "Dropoff")
        let destination = Waypoint(coordinate: CLLocationCoordinate2DMake(45.512061121601, -122.65359878540038), coordinateAccuracy: -1, name: "Destination")
        
        let options = NavigationRouteOptions(waypoints: [origin, pickup, dropoff, destination], profileIdentifier: .automobile)
        
        Directions.shared.calculate(options) { (waypoints, routes, error) in
            guard let route = routes?.first, error == nil else {
                print(error!.localizedDescription)
                return
            }
            
            let navigationController = NavigationViewController(for: route)

            navigationController.mapView?.navigationMapDelegate = self
            
            // This allows the developer to simulate the route.
            // Note: If copying and pasting this code in your own project,
            // comment out `simulationIsEnabled` as it is defined elsewhere in this project.
            if simulationIsEnabled {
                navigationController.routeController.locationManager = SimulatedLocationManager(route: route)
            }
            
            self.present(navigationController, animated: true, completion: nil)
        }
    }
    
    func navigationMapView(_ mapView: NavigationMapView, shapeFor waypoints: [Waypoint]) -> MGLShape? {
        
        var pointFeatures: [MGLPointFeature] = []
        
        for waypoint in waypoints {
            let point = MGLPointFeature()
            point.attributes = ["title" : waypoint.name!]
            pointFeatures.append(point)
        }
        
        let shapeSource = MGLShapeCollectionFeature(shapes: pointFeatures)
        
        return shapeSource
    }
    
    func navigationMapView(_ mapView: NavigationMapView, waypointStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        let waypointStyleLayer = MGLCircleStyleLayer(identifier: identifier, source: source)
        // TODO: Style waypoints here based on "title" attribute
        waypointStyleLayer.circleColor = MGLStyleValue(rawValue: UIColor.red)
        waypointStyleLayer.circleRadius = MGLStyleValue(rawValue: 8)
        return waypointStyleLayer
    }
    
    func navigationMapView(_ mapView: NavigationMapView, waypointSymbolStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        return nil
    }
}


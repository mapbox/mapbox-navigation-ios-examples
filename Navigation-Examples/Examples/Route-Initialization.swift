import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import Turf

class RouteInitializationViewController: UIViewController {
    
    // MARK: - UIViewController lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let origin: CLLocationCoordinate2D = CLLocationCoordinate2DMake(37.776818, -122.399076)
        let destination: CLLocationCoordinate2D = CLLocationCoordinate2DMake(37.777407, -122.399814)
        let distance: CLLocationDistance = 92.200000000000003
        let expectedTravelTime: TimeInterval = 24.699999999999999
        let routeCoordinates = [origin, destination]
        let departureStep = createRouteStep(text: "You will arrive",
                                            instructions: "Head northwest on 5th Street",
                                            distance: distance,
                                            expectedTravelTime: expectedTravelTime,
                                            maneuverType: .depart,
                                            maneuverLocation: origin,
                                            routeCoordinates: routeCoordinates)
        
        let arrivalStep = createRouteStep(text: "You have arrived",
                                          instructions: "You have arrived at your destination",
                                          distance: 0,
                                          expectedTravelTime: 0,
                                          maneuverType: .arrive,
                                          maneuverLocation: destination)
        
        let routeLeg = RouteLeg(steps: [departureStep, arrivalStep],
                                name: "5th Street",
                                distance: distance,
                                expectedTravelTime: expectedTravelTime,
                                profileIdentifier: .automobile)
        let routeOptions = NavigationRouteOptions(coordinates: routeCoordinates)
        routeLeg.source = routeOptions.waypoints[0]
        routeLeg.destination = routeOptions.waypoints[1]
        
        let route = Route(legs: [routeLeg], shape: LineString(routeCoordinates), distance: distance, expectedTravelTime: expectedTravelTime)
        let navigationService = MapboxNavigationService(route: route, routeOptions: routeOptions, simulating: simulationIsEnabled ? .always : .onPoorGPS)
        let navigationOptions = NavigationOptions(navigationService: navigationService)
        let navigationViewController = NavigationViewController(for: route, routeOptions: routeOptions, navigationOptions: navigationOptions)
        navigationViewController.modalPresentationStyle = .fullScreen
        self.present(navigationViewController, animated: true, completion: nil)
    }
    
    // MARK: - Utility methods
    
    func createRouteStep(text: String,
                         instructions: String,
                         distance: CLLocationDistance,
                         expectedTravelTime: TimeInterval,
                         maneuverType: ManeuverType,
                         maneuverLocation: CLLocationCoordinate2D,
                         routeCoordinates: [CLLocationCoordinate2D]? = nil) -> RouteStep {
        let component = VisualInstruction.Component.text(text: .init(text: text, abbreviation: nil, abbreviationPriority: nil))
        let visualInstruction = VisualInstruction(text: text, maneuverType: maneuverType, maneuverDirection: .straightAhead, components: [component])
        let visualInstructionBanner = VisualInstructionBanner(distanceAlongStep: distance,
                                                              primary: visualInstruction,
                                                              secondary: nil,
                                                              tertiary: nil,
                                                              drivingSide: .right)
        let routeStep = RouteStep(transportType: .automobile,
                                  maneuverLocation: maneuverLocation,
                                  maneuverType: maneuverType,
                                  instructions: instructions,
                                  drivingSide: .right,
                                  distance: distance,
                                  expectedTravelTime: expectedTravelTime,
                                  instructionsDisplayedAlongStep: [visualInstructionBanner])
        
        if maneuverType == .depart, let routeCoordinates = routeCoordinates {
            routeStep.shape = LineString(routeCoordinates)
        }
        
        return routeStep
    }
}

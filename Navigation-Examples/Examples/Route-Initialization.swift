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
        let distance: CLLocationDistance = 92.2
        let expectedTravelTime: TimeInterval = 24.6
        let routeCoordinates = [origin, destination]
        let distanceAlongArrivalStep = 18.7
        
        // Add two spoken instructions about an upcoming maneuver.
        let departureSpokenInstruction = SpokenInstruction(distanceAlongStep: distance,
                                                           text: "Head northwest on 5th Street, then you have arrived at your destination",
                                                           ssmlText: "")
        let arrivalSpokenInstruction = SpokenInstruction(distanceAlongStep: distanceAlongArrivalStep,
                                                         text: "You have arrived at your destination",
                                                         ssmlText: "")
        
        // Add two instruction banners which give visual cue about a given `RouteStep`.
        let departureVisualInstructionBanner = createVisualInstructionBanner(text: "You will arrive",
                                                                             distanceAlongStep: distance)
        let arrivalVisualInstructionBanner = createVisualInstructionBanner(text: "You have arrived",
                                                                           distanceAlongStep: distanceAlongArrivalStep)
        
        // For simplification RouteLeg contains only two steps: for departure and arrival.
        let departureStep = createRouteStep(maneuverLocation: origin,
                                            maneuverType: .depart,
                                            instructions: "Head northwest on 5th Street",
                                            distance: distance,
                                            expectedTravelTime: expectedTravelTime,
                                            instructionsSpokenAlongStep: [departureSpokenInstruction, arrivalSpokenInstruction],
                                            instructionsDisplayedAlongStep: [departureVisualInstructionBanner, arrivalVisualInstructionBanner])
        departureStep.shape = LineString(routeCoordinates)
        
        let arrivalStep = createRouteStep(maneuverLocation: destination,
                                          maneuverType: .arrive,
                                          instructions: "You have arrived at your destination",
                                          distance: 0,
                                          expectedTravelTime: 0)
        arrivalStep.shape = LineString([destination])
        
        let routeLeg = RouteLeg(steps: [departureStep, arrivalStep],
                                name: "5th Street",
                                distance: distance,
                                expectedTravelTime: expectedTravelTime,
                                profileIdentifier: .automobile)
        let routeOptions = NavigationRouteOptions(coordinates: routeCoordinates)
        routeLeg.source = routeOptions.waypoints[0]
        routeLeg.destination = routeOptions.waypoints[1]
        
        // It's also possible to configure `RouteLeg` with information related to traffic congestion, expected travel time etc.
        routeLeg.segmentCongestionLevels = [
            .heavy,
            .low,
            .low,
            .moderate
        ]
        
        routeLeg.expectedSegmentTravelTimes = [
            20.6,
            2,
            1.1,
            0.9
        ]
        
        // Here `Route` object is created manually without calling Directions API directly.
        let route = Route(legs: [routeLeg], shape: LineString(routeCoordinates), distance: distance, expectedTravelTime: expectedTravelTime)
        
        // For demonstration purposes, simulate locations if the Simulate Navigation option is on.
        let navigationService = MapboxNavigationService(route: route, routeOptions: routeOptions, simulating: simulationIsEnabled ? .always : .onPoorGPS)
        let navigationOptions = NavigationOptions(navigationService: navigationService)
        let navigationViewController = NavigationViewController(for: route, routeOptions: routeOptions, navigationOptions: navigationOptions)
        navigationViewController.modalPresentationStyle = .fullScreen
        self.present(navigationViewController, animated: true, completion: nil)
    }
    
    // MARK: - Utility methods
    
    private func createRouteStep(maneuverLocation: CLLocationCoordinate2D,
                                 maneuverType: ManeuverType,
                                 instructions: String,
                                 distance: CLLocationDistance,
                                 expectedTravelTime: TimeInterval,
                                 instructionsSpokenAlongStep: [SpokenInstruction]? = nil,
                                 instructionsDisplayedAlongStep: [VisualInstructionBanner]? = nil) -> RouteStep {
        
        let routeStep = RouteStep(transportType: .automobile,
                                  maneuverLocation: maneuverLocation,
                                  maneuverType: maneuverType,
                                  maneuverDirection: .straightAhead,
                                  instructions: instructions,
                                  initialHeading: 0.0,
                                  finalHeading: 0.0,
                                  drivingSide: .right,
                                  exitCodes: [],
                                  exitNames: [],
                                  phoneticExitNames: [],
                                  distance: distance,
                                  expectedTravelTime: expectedTravelTime,
                                  names: [],
                                  phoneticNames: [],
                                  codes: [],
                                  destinationCodes: [],
                                  destinations: [],
                                  intersections: [],
                                  speedLimitSignStandard: .mutcd,
                                  speedLimitUnit: .milesPerHour,
                                  instructionsSpokenAlongStep: instructionsSpokenAlongStep,
                                  instructionsDisplayedAlongStep: instructionsDisplayedAlongStep)
        
        return routeStep
    }
    
    private func createVisualInstructionBanner(text: String, distanceAlongStep: CLLocationDistance) -> VisualInstructionBanner {
        
        let component = VisualInstruction.Component.text(text: .init(text: text,
                                                                     abbreviation: nil,
                                                                     abbreviationPriority: nil))
        
        let visualInstruction = VisualInstruction(text: text,
                                                  maneuverType: .arrive,
                                                  maneuverDirection: .straightAhead,
                                                  components: [component])
        
        let visualInstructionBanner = VisualInstructionBanner(distanceAlongStep: distanceAlongStep,
                                                              primary: visualInstruction,
                                                              secondary: nil,
                                                              tertiary: nil,
                                                              drivingSide: .right)
        
        return visualInstructionBanner
    }
}

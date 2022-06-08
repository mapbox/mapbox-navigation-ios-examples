/*
 This code example is part of the Mapbox Navigation SDK for iOS demo app,
 which you can build and run: https://github.com/mapbox/mapbox-navigation-ios-examples
 To learn more about each example in this app, including descriptions and links
 to documentation, see our docs: https://docs.mapbox.com/ios/navigation/examples/route-initialization
 */

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
        
        let departureStepCoordinates = [
            origin,
            CLLocationCoordinate2D(latitude: 37.777368, longitude: -122.399767),
            destination
        ]
        
        departureStep.shape = LineString(departureStepCoordinates)
        
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
        // Route response encapsulates more data about the route. Since this example doesn't call Directions API, we should add it manually.
        let routeResponse = RouteResponse(httpResponse: nil,
                                          identifier: "your-custom-id-here",
                                          routes: [route],
                                          waypoints: routeCoordinates.map {
                                            Waypoint(coordinate: $0,
                                                     coordinateAccuracy: nil,
                                                     name: nil)
                                          }, options: .route(routeOptions),
                                          credentials: Directions.shared.credentials)
        // For demonstration purposes, simulate locations if the Simulate Navigation option is on.
        let navigationService = MapboxNavigationService(routeResponse: routeResponse,
                                                        routeIndex: 0,
                                                        routeOptions: routeOptions,
                                                        customRoutingProvider: NavigationSettings.shared.directions,
                                                        credentials: NavigationSettings.shared.directions.credentials,
                                                        simulating: simulationIsEnabled ? .always : .onPoorGPS)
        let navigationOptions = NavigationOptions(navigationService: navigationService)
        let navigationViewController = NavigationViewController(for: routeResponse,
                                                                   routeIndex: 0,
                                                                   routeOptions: routeOptions,
                                                                   navigationOptions: navigationOptions)
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
                                                              quaternary: nil,
                                                              drivingSide: .right)
        
        return visualInstructionBanner
    }
}

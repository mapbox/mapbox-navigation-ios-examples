import Foundation
import UIKit

typealias NamedController = (
    name: String,
    description: String,
    controller: UIViewController.Type,
    pushExampleToViewController: Bool // If the example does not go directly into the example,(i.e. another map is shown) set this value to true
)

let listOfExamples: [NamedController] = [
    (
        name: "Advanced Implementation",
        description: "Demonstrates providing a custom map style and also stylizing components in the UI. Long press on the map to begin.",
        controller: AdvancedViewController.self,
        pushExampleToViewController: true
    ),
    (
        name: "Basic",
        description: "A simple hello world example showing how to create a navigation experience in the fewest lines of code possible.",
        controller: BasicViewController.self,
        pushExampleToViewController: false
    ),
    (
        name: "Custom Style",
        description: "Demonstrates providing a custom map style and also stylizing components in the UI",
        controller: CustomStyleViewController.self,
        pushExampleToViewController: false
    ),
    (
        name: "Select Alternate Route",
        description: "Demonstrates allowing the user to select an alternate route. Note: The Directions API will not always return alternate routes.",
        controller: AdvancedViewController.self,
        pushExampleToViewController: true
    ),
    (
        name: "Waypoint Arrival Screen",
        description: "Demonstrates providing a UIView for the user upon arriving at a waypoint.",
        controller: WaypointArrivalScreenViewController.self,
        pushExampleToViewController: false
    )
]

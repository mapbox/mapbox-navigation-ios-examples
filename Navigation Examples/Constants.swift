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
        description: "Demonstrates how to display a custom map style and how to apply stylized components in the UI. Long press on the map to begin.",
        controller: AdvancedViewController.self,
        pushExampleToViewController: true
    ),
    (
        name: "Basic",
        description: "A basic hello world example showing how to create a navigation experience using the fewest lines of code possible.",
        controller: BasicViewController.self,
        pushExampleToViewController: false
    ),
    (
        name: "Styled UI Elements",
        description: "Demonstrates how to customize various UI elements and also change the map style.",
        controller: CustomStyleUIElements.self,
        pushExampleToViewController: false
    ),
    (
        name: "Select Alternate Route",
        description: "Allow the user to select an alternate route. Note: The Directions API will not always return alternate routes.",
        controller: AdvancedViewController.self,
        pushExampleToViewController: true
    ),
    (
        name: "Waypoint Arrival Screen",
        description: "Demonstrates how to provide a custom UIView for the user upon arriving at a waypoint.",
        controller: WaypointArrivalScreenViewController.self,
        pushExampleToViewController: false
    )
]

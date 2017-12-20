import Foundation
import UIKit

typealias NamedController = (name: String, description: String, controller: UIViewController.Type)

let listOfExamples: [NamedController] = [
    (
        name: "Basic",
        description: "A simple hello world example showing how to create a navigation experience in the fewest lines of code possible.",
        controller: BasicViewController.self
    ),
    (
        name: "Waypoint Arrival Screen",
        description: "Demonstrates providing a UIView for the user upon arriving at a waypoint.",
        controller: WaypointArrivalScreenViewController.self
    ),
    (
        name: "Custom Style",
        description: "Demonstrates providing a custom map style and also stylizing components in the UI",
        controller: CustomStyleViewController.self
    )
]

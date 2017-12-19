import Foundation
import UIKit

typealias NamedController = (name: String, controller: UIViewController.Type)

let listOfExamples: [NamedController] = [
    (name: "Basic", controller: BasicViewController.self),
    (name:"Waypoint Arrival Screen", controller: WaypointArrivalScreenViewController.self),
    (name:"Custom Style", controller: CustomStyleViewController.self)
]

import Foundation
import UIKit

typealias namedController = (name: String, controller: UIViewController.Type)

let listOfExamples: [namedController] = [
    (name: "Basic", controller: BasicViewController.self),
    (name:"Waypoint Arrival Screen", controller: WaypointArrivalScreenViewController.self),
    (name:"Custom Style", controller: CustomStyleViewController.self)
]

import Foundation
import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import AVFoundation

class CustomVoiceControllerUI: UIViewController {
    
    let voiceController = CustomVoiceController()

    let turnLeft = NSDataAsset(name: "turnleft")!.data
    let turnRight = NSDataAsset(name: "turnright")!.data
    let straight = NSDataAsset(name: "continuestraight")!.data
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let origin = CLLocationCoordinate2DMake(37.77440680146262, -122.43539772352648)
        let destination = CLLocationCoordinate2DMake(37.76556957793795, -122.42409811526268)
        let options = NavigationRouteOptions(coordinates: [origin, destination])
        
        NotificationCenter.default.addObserver(self, selector: #selector(didPassSpokenInstructionPoint(notification:)), name: .routeControllerDidPassSpokenInstructionPoint, object: nil)
        
        Directions.shared.calculate(options) { (waypoints, routes, error) in
            guard let route = routes?.first, error == nil else {
                print(error!.localizedDescription)
                return
            }
            
            let navigationController = NavigationViewController(for: route)
            navigationController.voiceController = self.voiceController
            
            // This allows the developer to simulate the route.
            // Note: If copying and pasting this code in your own project,
            // comment out `simulationIsEnabled` as it is defined elsewhere in this project.
            if simulationIsEnabled {
                navigationController.routeController.locationManager = SimulatedLocationManager(route: route)
            }
            
            self.present(navigationController, animated: true, completion: nil)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .routeControllerDidPassSpokenInstructionPoint, object: nil)
    }
    
    @objc open func didPassSpokenInstructionPoint(notification: NSNotification) {
        let routeProgress = notification.userInfo![RouteControllerNotificationUserInfoKey.routeProgressKey] as! RouteProgress
        let soundForInstruction = audio(for: routeProgress.currentLegProgress.currentStep)
        voiceController.play(soundForInstruction)
    }
    
    func audio(for step: RouteStep) -> Data {
        switch step.maneuverDirection {
        case .left:
            return turnLeft
        case .right:
            return turnRight
        default:
            return straight
        }
    }
}

class CustomVoiceController: MapboxVoiceController {
    override func didPassSpokenInstructionPoint(notification: NSNotification) {
        return
    }
}



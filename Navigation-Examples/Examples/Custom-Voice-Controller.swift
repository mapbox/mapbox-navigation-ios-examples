import Foundation
import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import AVFoundation

class CustomVoiceControllerUI: UIViewController {
    
    var voiceController: CustomVoiceController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let origin = CLLocationCoordinate2DMake(37.77440680146262, -122.43539772352648)
        let destination = CLLocationCoordinate2DMake(37.76556957793795, -122.42409811526268)
        let routeOptions = NavigationRouteOptions(coordinates: [origin, destination])
        
        Directions.shared.calculate(routeOptions) { [weak self] (session, result) in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let response):
                guard let route = response.routes?.first, let strongSelf = self else {
                    return
                }
                
                // For demonstration purposes, simulate locations if the Simulate Navigation option is on.
                let navigationService = MapboxNavigationService(route: route, routeOptions: routeOptions, simulating: simulationIsEnabled ? .always : .onPoorGPS)
                strongSelf.voiceController = CustomVoiceController(navigationService: navigationService)
                let navigationOptions = NavigationOptions(navigationService: navigationService, voiceController: strongSelf.voiceController)
                let navigationViewController = NavigationViewController(for: route, routeOptions: routeOptions, navigationOptions: navigationOptions)
                navigationViewController.modalPresentationStyle = .fullScreen
                
                strongSelf.present(navigationViewController, animated: true, completion: nil)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        voiceController = nil
    }
}

class CustomVoiceController: MapboxVoiceController {
    
    // You will need audio files for as many or few cases as you'd like to handle
    // This example just covers left, right and straight.
    let turnLeft = NSDataAsset(name: "turnleft")!.data
    let turnRight = NSDataAsset(name: "turnright")!.data
    let straight = NSDataAsset(name: "continuestraight")!.data
    
    override func didPassSpokenInstructionPoint(notification: NSNotification) {
        let routeProgress = notification.userInfo![RouteController.NotificationUserInfoKey.routeProgressKey] as! RouteProgress
        let soundForInstruction = audio(for: routeProgress.currentLegProgress.currentStep)
        let instruction = notification.userInfo![RouteController.NotificationUserInfoKey.spokenInstructionKey] as! SpokenInstruction
        play(instruction: instruction, data: soundForInstruction)
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



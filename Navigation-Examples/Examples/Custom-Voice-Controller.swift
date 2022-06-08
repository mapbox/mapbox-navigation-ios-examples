/*
 This code example is part of the Mapbox Navigation SDK for iOS demo app,
 which you can build and run: https://github.com/mapbox/mapbox-navigation-ios-examples
 To learn more about each example in this app, including descriptions and links
 to documentation, see our docs: https://docs.mapbox.com/ios/navigation/examples/custom-voice-controller/
 */

import Foundation
import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import MapboxSpeech
import AVFoundation

class CustomVoiceControllerUI: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let origin = CLLocationCoordinate2DMake(37.77440680146262, -122.43539772352648)
        let destination = CLLocationCoordinate2DMake(37.76556957793795, -122.42409811526268)
        let routeOptions = NavigationRouteOptions(coordinates: [origin, destination])
        
        Directions.shared.calculate(routeOptions) { [weak self] (_, result) in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let response):
                self?.presentNavigationWithCustomVoiceController(routeOptions: routeOptions, response: response)
            }
        }
    }

    func presentNavigationWithCustomVoiceController(routeOptions: NavigationRouteOptions, response: RouteResponse) {
        // For demonstration purposes, simulate locations if the Simulate Navigation option is on.
        let navigationService = MapboxNavigationService(routeResponse: response,
                                                        routeIndex: 0,
                                                        routeOptions: routeOptions,
                                                        customRoutingProvider: NavigationSettings.shared.directions,
                                                        credentials: NavigationSettings.shared.directions.credentials,
                                                        simulating: simulationIsEnabled ? .always : .onPoorGPS)

        // `MultiplexedSpeechSynthesizer` will provide "a backup" functionality to cover cases, which
        // our custom implementation cannot handle.
        let speechSynthesizer = MultiplexedSpeechSynthesizer([CustomVoiceController(), SystemSpeechSynthesizer()])

        // Create a `RouteVoiceController` type with a customized `SpeechSynthesizing` instance.
        // A route voice controller monitors turn-by-turn navigation events and triggers playing spoken instructions
        // as audio using the custom `speechSynthesizer` we created above.
        let routeVoiceController = RouteVoiceController(navigationService: navigationService,
                                                        speechSynthesizer: speechSynthesizer)
        // Remember to pass our RouteVoiceController` to `Navigation Options`!
        let navigationOptions = NavigationOptions(navigationService: navigationService,
                                                  voiceController: routeVoiceController)

        // Create `NavigationViewController` with the custom `NavigationOptions`.
        let navigationViewController = NavigationViewController(for: response,
                                                                routeIndex: 0,
                                                                routeOptions: routeOptions,
                                                                navigationOptions: navigationOptions)
        navigationViewController.modalPresentationStyle = .fullScreen

        present(navigationViewController, animated: true, completion: nil)
    }
}

class CustomVoiceController: MapboxSpeechSynthesizer {
    
    // You will need audio files for as many or few cases as you'd like to handle
    // This example just covers left and right. All other cases will fail the Custom Voice Controller and
    // force a backup System Speech to kick in
    let turnLeft = NSDataAsset(name: "turnleft")!.data
    let turnRight = NSDataAsset(name: "turnright")!.data
    
    override func speak(_ instruction: SpokenInstruction, during legProgress: RouteLegProgress, locale: Locale? = nil) {

        guard let soundForInstruction = audio(for: legProgress.currentStep) else {
            // When `MultiplexedSpeechSynthesizer` receives an error from one of it's Speech Synthesizers,
            // it requests the next on the list
            delegate?.speechSynthesizer(self,
                                        didSpeak: instruction,
                                        with: SpeechError.noData(instruction: instruction,
                                                                 options: SpeechOptions(text: instruction.text)))
            return
        }
        speak(instruction, data: soundForInstruction)
    }
    
    func audio(for step: RouteStep) -> Data? {
        switch step.maneuverDirection {
        case .left:
            return turnLeft
        case .right:
            return turnRight
        default:
            return nil // this will force report that Custom View Controller is unable to handle this case
        }
    }
}

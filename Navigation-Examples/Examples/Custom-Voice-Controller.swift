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
                
                // `MultiplexedSpeechSynthesizer` will provide "a backup" functionality to cover cases, which
                // our custom implementation cannot handle.
                let speechSynthesizer = MultiplexedSpeechSynthesizer([CustomVoiceController(), SystemSpeechSynthesizer()] as? [SpeechSynthesizing])
                let routeController = RouteVoiceController(navigationService: navigationService, speechSynthesizer: speechSynthesizer)
                // Remember to pass our `Voice Controller` to `Navigation Options`!
                let navigationOptions = NavigationOptions(navigationService: navigationService, voiceController: routeController)
                
                let navigationViewController = NavigationViewController(for: route, routeOptions: routeOptions, navigationOptions: navigationOptions)
                navigationViewController.modalPresentationStyle = .fullScreen
                
                strongSelf.present(navigationViewController, animated: true, completion: nil)
            }
        }
    }
}

class CustomVoiceController: NSObject, SpeechSynthesizing {
    
    // MARK: - SpeechSynthesizing implementation
    
    var delegate: SpeechSynthesizingDelegate?
    
    public var muted: Bool = false {
        didSet {
            updatePlayerVolume(audioPlayer)
        }
    }
    public var volume: Float = 1.0 {
        didSet {
            audioPlayer?.volume = volume
        }
    }
    public var isSpeaking: Bool {
        return audioPlayer?.isPlaying ?? false
    }
    
    var locale: Locale?
    
    func prepareIncomingSpokenInstructions(_ instructions: [SpokenInstruction], locale: Locale?) {
        // do nothing as we don't have to prepare anything
    }
    
    func stopSpeaking() {
        audioPlayer?.stop()
    }
    
    func interruptSpeaking() {
        audioPlayer?.stop()
    }
    
    // You will need audio files for as many or few cases as you'd like to handle
    // This example just covers left and right. All other cases will fail the Custom Voice Controller and force a backup System Speech to kick in
    let turnLeft = NSDataAsset(name: "turnleft")!.data
    let turnRight = NSDataAsset(name: "turnright")!.data
    
    public var audioPlayer: AVAudioPlayer?
    private var previousInstruction: SpokenInstruction?
    
    func speak(_ instruction: SpokenInstruction, during legProgress: RouteLegProgress, locale: Locale? = nil) {

        guard let soundForInstruction = audio(for: legProgress.currentStep) else {
            // When `MultiplexedSpeechSynthesizer` receives an error from one of it's Speech Synthesizers,
            // it requests the next on the list
            delegate?.speechSynthesizer(self,
                                        didSpeak: instruction,
                                        with: SpeechError.noData(instruction: instruction,
                                                                 options: SpeechOptions(text: instruction.text)))
            return
        }
        speak(instruction: instruction, instructionData: soundForInstruction)
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
    
    // Method to play provided audio data with some edge cases handling
    func speak(instruction: SpokenInstruction, instructionData: Data) {
        
        if let audioPlayer = audioPlayer {
            if let previousInstruction = previousInstruction, audioPlayer.isPlaying {
                delegate?.speechSynthesizer(self,
                                            didInterrupt: previousInstruction,
                                            with: instruction)
            }
            
            deinitAudioPlayer()
        }
        
        switch safeInitializeAudioPlayer(data: instructionData,
                                         instruction: instruction) {
        case .success(let player):
            audioPlayer = player
            previousInstruction = instruction
            audioPlayer?.play()
        case .failure(let error):
            safeUnduckAudio(instruction: instruction)
            delegate?.speechSynthesizer(self,
                                        didSpeak: instruction,
                                        with: error)
        }
    }
    
    // MARK: - Audio control methods
    
    func safeDuckAudio(instruction: SpokenInstruction?){
        if let error = AVAudioSession.sharedInstance().tryDuckAudio() {
            delegate?.speechSynthesizer(self,
                                        encounteredError: SpeechError.unableToControlAudio(instruction: instruction,
                                                                                           action: .duck,
                                                                                           underlying: error))
        }
    }
    
    func safeUnduckAudio(instruction: SpokenInstruction?) {
        if let error = AVAudioSession.sharedInstance().tryUnduckAudio() {
            delegate?.speechSynthesizer(self,
                                        encounteredError: SpeechError.unableToControlAudio(instruction: instruction,
                                                                                           action: .unduck,
                                                                                           underlying: error))
        }
    }
    
    func updatePlayerVolume(_ player: AVAudioPlayer?) {
        player?.volume = muted ? 0.0 : volume
    }
    
    func safeInitializeAudioPlayer(data: Data, instruction: SpokenInstruction) -> Result<AVAudioPlayer, MapboxNavigation.SpeechError> {
        do {
            let player = try AVAudioPlayer(data: data)
            player.delegate = self
            updatePlayerVolume(player)
            
            return .success(player)
        } catch {
            return .failure(SpeechError.unableToInitializePlayer(playerType: AVAudioPlayer.self,
                                                                 instruction: instruction,
                                                                 synthesizer: nil,
                                                                 underlying: error))
        }
    }
    
    func deinitAudioPlayer() {
        audioPlayer?.stop()
        audioPlayer?.delegate = nil
    }
}

extension CustomVoiceController: AVAudioPlayerDelegate {
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        safeUnduckAudio(instruction: previousInstruction)
        
        guard let instruction = previousInstruction else {
            assert(false, "Speech Synthesizer finished speaking 'nil' instruction")
            return
        }
        
        delegate?.speechSynthesizer(self,
                                    didSpeak: instruction,
                                    with: nil)
    }
}


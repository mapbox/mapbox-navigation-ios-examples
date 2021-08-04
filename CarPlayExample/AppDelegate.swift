import UIKit
import CarPlay
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import MapboxMaps

@main
class AppDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    @available(iOS 12.0, *)
    lazy var carPlayManager: CarPlayManager = CarPlayManager(styles: [CustomStyle()])
}

// MARK: - UIApplicationDelegate methods

extension AppDelegate: UIApplicationDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }
    
    @available(iOS 13.0, *)
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        if connectingSceneSession.role == .carTemplateApplication {
            return UISceneConfiguration(name: "CarPlay Configuration",
                                        sessionRole: connectingSceneSession.role)
        }
        
        return UISceneConfiguration(name: "Default Configuration",
                                    sessionRole: connectingSceneSession.role)
    }
}

// MARK: - CPTemplateApplicationSceneDelegate methods

extension AppDelegate: CPTemplateApplicationSceneDelegate {
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didConnect interfaceController: CPInterfaceController,
                                  to window: CPWindow) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        appDelegate.carPlayManager.delegate = appDelegate
        
        appDelegate.carPlayManager.application(UIApplication.shared,
                                               didConnectCarInterfaceController: interfaceController,
                                               to: window)
        
        appDelegate.carPlayManager.templateApplicationScene(templateApplicationScene,
                                                            didConnectCarInterfaceController: interfaceController,
                                                            to: window)
    }
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didDisconnect interfaceController: CPInterfaceController,
                                  from window: CPWindow) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        appDelegate.carPlayManager.delegate = nil
        
        appDelegate.carPlayManager.application(UIApplication.shared,
                                               didDisconnectCarInterfaceController: interfaceController,
                                               from: window)
        
        appDelegate.carPlayManager.templateApplicationScene(templateApplicationScene,
                                                            didDisconnectCarInterfaceController: interfaceController,
                                                            from: window)
    }
}

// MARK: - CarPlayManagerDelegate methods

extension AppDelegate: CarPlayManagerDelegate {
    
    func carPlayManager(_ carPlayManager: CarPlayManager,
                        leadingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection,
                        in carPlayTemplate: CPTemplate,
                        for activity: CarPlayActivity) -> [CPBarButton]? {
        switch activity {
        
        case .browsing:
            break
            
        case .panningInBrowsingMode:
            break
            
        case .previewing:
            break
            
        case .navigating:
            break
        }
        
        return []
    }
    
    func carPlayManager(_ carPlayManager: CarPlayManager,
                        trailingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection,
                        in carPlayTemplate: CPTemplate,
                        for activity: CarPlayActivity) -> [CPBarButton]? {
        switch activity {
        
        case .browsing:
            break
            
        case .panningInBrowsingMode:
            break
            
        case .previewing:
            break
            
        case .navigating:
            return [carPlayManager.exitButton]
        }
        
        return []
    }
    
    func carPlayManager(_ carPlayManager: CarPlayManager,
                        mapButtonsCompatibleWith traitCollection: UITraitCollection,
                        in carPlayTemplate: CPTemplate,
                        for activity: CarPlayActivity) -> [CPMapButton]? {
        switch activity {
        
        case .browsing:
            break
            
        case .panningInBrowsingMode:
            break
            
        case .previewing:
            break
            
        case .navigating:
            break
        }
        
        return []
    }
    
    func carPlayManager(_ carPlayManager: CarPlayManager,
                        didFailToFetchRouteBetween waypoints: [Waypoint]?,
                        options: RouteOptions,
                        error: DirectionsError) -> CPNavigationAlert? {
        let alertAction = CPAlertAction(title: "Dismiss", style: .default, handler: { _ in })
        
        let navigationAlert = CPNavigationAlert(titleVariants: ["Failed to fetch"],
                                                subtitleVariants: nil,
                                                image: nil,
                                                primaryAction: alertAction,
                                                secondaryAction: nil,
                                                duration: 2.5)
        
        return navigationAlert
    }
    
    func carPlayManager(_ carPlayManager: CarPlayManager,
                        willPreview trip: CPTrip) -> CPTrip {
        return trip
    }
    
    func carPlayManager(_ carPlayManager: CarPlayManager,
                        willPreview trip: CPTrip,
                        with previewTextConfiguration: CPTripPreviewTextConfiguration) -> CPTripPreviewTextConfiguration {
        return previewTextConfiguration
    }
    
    func carPlayManager(_ carPlayManager: CarPlayManager,
                        selectedPreviewFor trip: CPTrip,
                        using routeChoice: CPRouteChoice) {
        
    }
    
    func carPlayManager(_ carPlayManager: CarPlayManager,
                        didBeginNavigationWith service: NavigationService) {
        
    }
    
    // Delegate method, which is called after ending active-guidance navigation session and dismissing
    // `CarPlayNavigationViewController`.
    func carPlayManagerDidEndNavigation(_ carPlayManager: CarPlayManager) {
        let alertAction = CPAlertAction(title: "OK",
                                        style: .default,
                                        handler: { [weak self] _ in
                                            self?.carPlayManager.interfaceController?.dismissTemplate(animated: true)
                                        })
        
        let alertTemplate = CPAlertTemplate(titleVariants: ["Did end active-guidance navigation."],
                                            actions: [alertAction])
        
        carPlayManager.interfaceController?.presentTemplate(alertTemplate, animated: true)
    }
    
    // Delegate method, which allows to show `CPActionSheetTemplate` or `CPAlertTemplate`
    // after arriving to the specific `Waypoint`.
    func carPlayManager(_ carPlayManager: CarPlayManager,
                        shouldPresentArrivalUIFor waypoint: Waypoint) -> Bool {
        return true
    }
    
    // Delegate method, which provides the ability to disable the idle timer to avert system sleep.
    func carPlayManagerShouldDisableIdleTimer(_ carPlayManager: CarPlayManager) -> Bool {
        return true
    }
    
    // Delegate method, which is called right after starting active-guidance navigation and presenting
    // `CarPlayNavigationViewController`.
    func carPlayManager(_ carPlayManager: CarPlayManager,
                        didPresent navigationViewController: CarPlayNavigationViewController) {
        let alertAction = CPAlertAction(title: "OK",
                                        style: .default,
                                        handler: { [weak self] _ in
                                            self?.carPlayManager.interfaceController?.dismissTemplate(animated: true)
                                        })
        
        let alertTemplate = CPAlertTemplate(titleVariants: ["Did present CarPlayNavigationViewController."],
                                            actions: [alertAction])
        
        carPlayManager.interfaceController?.presentTemplate(alertTemplate, animated: true)
    }
    
    // Delegate method, which allows to modify final destination annotation whenever its added to
    // `CarPlayMapViewController` or `CarPlayNavigationViewController`.
    func carPlayManager(_ carPlayManager: CarPlayManager,
                        didAdd finalDestinationAnnotation: PointAnnotation,
                        to parentViewController: UIViewController,
                        pointAnnotationManager: PointAnnotationManager) {
        var finalDestinationAnnotation = finalDestinationAnnotation
        if let image = UIImage(named: "marker") {
            finalDestinationAnnotation.image = PointAnnotation.Image.custom(image: image, name: "marker")
        } else {
            finalDestinationAnnotation.image = .default
        }
        
        pointAnnotationManager.syncAnnotations([finalDestinationAnnotation])
    }
}

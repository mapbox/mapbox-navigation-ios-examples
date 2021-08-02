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
    lazy var carPlayManager: CarPlayManager = CarPlayManager()
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
        carPlayManager.delegate = self
        carPlayManager.templateApplicationScene(templateApplicationScene,
                                                didConnectCarInterfaceController: interfaceController,
                                                to: window)
        
        carPlayManager.application(UIApplication.shared,
                                   didConnectCarInterfaceController: interfaceController,
                                   to: window)
    }
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didDisconnect interfaceController: CPInterfaceController,
                                  from window: CPWindow) {
        carPlayManager.delegate = nil
        carPlayManager.application(UIApplication.shared,
                                   didDisconnectCarInterfaceController: interfaceController,
                                   from: window)
        
        carPlayManager.templateApplicationScene(templateApplicationScene,
                                                didDisconnectCarInterfaceController: interfaceController,
                                                from: window)
    }
}

// MARK: - CarPlayManagerDelegate methods

extension AppDelegate: CarPlayManagerDelegate {
    
    func carPlayManager(_ carPlayManager: CarPlayManager,
                        leadingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection,
                        in carPlayTemplate: CPTemplate, for activity: CarPlayActivity) -> [CPBarButton]? {
        let barButton = CPBarButton(type: .text) { _ in
            
        }
        barButton.title = "Test"
        
        return [barButton]
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
            break
            
        }
        
        let barButton = CPBarButton(type: .text) { _ in
            
        }
        barButton.title = "Test"
        
        return [barButton]
    }
    
    func carPlayManager(_ carPlayManager: CarPlayManager,
                        mapButtonsCompatibleWith traitCollection: UITraitCollection,
                        in carPlayTemplate: CPTemplate,
                        for activity: CarPlayActivity) -> [CPMapButton] {
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
        
        let mapButton = CPMapButton { _ in
            
        }
        mapButton.image = UIImage.checkmark
        
        return [mapButton]
    }
    
    func carPlayManager(_ carPlayManager: CarPlayManager,
                        didFailToFetchRouteBetween waypoints: [Waypoint]?,
                        options: RouteOptions,
                        error: DirectionsError) -> CPNavigationAlert? {
        return nil
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
    
    func carPlayManagerDidEndNavigation(_ carPlayManager: CarPlayManager) {
        
    }
    
    func carPlayManager(_ carPlayManager: CarPlayManager,
                        shouldPresentArrivalUIFor waypoint: Waypoint) -> Bool {
        return false
    }
    
    func carPlayManagerShouldDisableIdleTimer(_ carPlayManager: CarPlayManager) -> Bool {
        return false
    }
    
    func carPlayManager(_ carPlayManager: CarPlayManager,
                        didPresent navigationViewController: CarPlayNavigationViewController) {

    }
    
    func carPlayManager(_ carPlayManager: CarPlayManager,
                        didAdd finalDestinationAnnotation: PointAnnotation,
                        to parentViewController: UIViewController,
                        pointAnnotationManager: PointAnnotationManager) {
        
    }
}

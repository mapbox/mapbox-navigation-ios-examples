import UIKit
import CarPlay

import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections

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
                        navigationServiceAlong route: Route,
                        routeIndex: Int,
                        routeOptions: RouteOptions,
                        desiredSimulationMode: SimulationMode) -> NavigationService {
        return MapboxNavigationService(route: route,
                                       routeIndex: routeIndex,
                                       routeOptions: routeOptions,
                                       simulating: desiredSimulationMode)
    }
}

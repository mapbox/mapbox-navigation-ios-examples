import UIKit
import CarPlay
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import MapboxMaps

@main
class AppDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    lazy var carPlayManager: CarPlayManager = CarPlayManager(styles: [CustomStyle()])
    
    lazy var carPlaySearchController: CarPlaySearchController = CarPlaySearchController()
    
    lazy var recentSearchItems: [CPListItem]? = []
    
    var recentItems: [RecentItem] = RecentItem.loadDefaults()
    
    var recentSearchText: String? = ""
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
            carPlaySearchController.delegate = self
            return UISceneConfiguration(name: "CarPlay Configuration",
                                        sessionRole: connectingSceneSession.role)
        }
        
        return UISceneConfiguration(name: "Default Configuration",
                                    sessionRole: connectingSceneSession.role)
    }
}

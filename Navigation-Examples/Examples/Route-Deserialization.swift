import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections

class RouteDeserializationViewController: UIViewController {
    
    // MARK: - UIViewController lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let origin = CLLocationCoordinate2DMake(37.776818, -122.399076)
        let destination = CLLocationCoordinate2DMake(37.777407, -122.399814)
        let routeOptions = NavigationRouteOptions(coordinates: [origin, destination])
        
        // Load previously serialized Route object in JSON format and deserialize it.
        let routeData = JSONFromFileNamed(name: "route")
        let decoder = JSONDecoder()
        decoder.userInfo[.options] = routeOptions
        let route: Route? = try? decoder.decode(Route.self, from: routeData)
        
        if let route = route {
            let navigationService = MapboxNavigationService(route: route, routeIndex: 0, routeOptions: routeOptions, simulating: simulationIsEnabled ? .always : .onPoorGPS)
            let navigationOptions = NavigationOptions(navigationService: navigationService)
            let navigationViewController = NavigationViewController(for: route, routeIndex: 0, routeOptions: routeOptions, navigationOptions: navigationOptions)
            navigationViewController.modalPresentationStyle = .fullScreen
            self.present(navigationViewController, animated: true, completion: nil)
        } else {
            print("Unable to deserialize Route.")
        }
    }
    
    // MARK: - Utility methods
    
    private func JSONFromFileNamed(name: String) -> Data {
        
        guard let path = Bundle.main.path(forResource: name, ofType: "json") else {
            preconditionFailure("File \(name) not found.")
        }
        
        guard let data = NSData(contentsOfFile: path) as Data? else {
            preconditionFailure("No data found at \(path).")
        }
        
        return data
    }
}

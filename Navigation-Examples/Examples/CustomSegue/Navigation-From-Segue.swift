import UIKit
import MapboxNavigation
import MapboxCoreNavigation
import CoreLocation
import MapboxDirections

class SegueViewController: UIViewController {
    
    var route: Route!
    
    var navigationRouteOptions: NavigationRouteOptions!
    
    var navigationOptions: NavigationOptions!
    
    @IBOutlet weak var presentNavigationButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupPresentNavigationButton()
        
        let origin = CLLocationCoordinate2DMake(37.77440680146262, -122.43539772352648)
        let destination = CLLocationCoordinate2DMake(37.76556957793795, -122.42409811526268)
        navigationRouteOptions = NavigationRouteOptions(coordinates: [origin, destination])
        
        Directions.shared.calculate(navigationRouteOptions) { [weak self] (session, result) in
            switch result {
            case .failure(let error):
                NSLog("Error occured: \(error.localizedDescription).")
            case .success(let response):
                guard let route = response.routes?.first, let self = self else { return }
                
                self.route = route
                
                let navigationService = MapboxNavigationService(route: route,
                                                                routeIndex: 0,
                                                                routeOptions: self.navigationRouteOptions,
                                                                simulating: .always)
                self.navigationOptions = NavigationOptions(navigationService: navigationService)
            }
        }
    }
    
    func setupPresentNavigationButton() {
        presentNavigationButton.titleLabel?.textAlignment = .center
        presentNavigationButton.titleLabel?.numberOfLines = 2
        presentNavigationButton.titleLabel?.lineBreakMode = .byTruncatingTail
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier ?? "" {
        case "NavigationSegue":
            if let navigationViewController = segue.destination as? NavigationViewController {
                navigationViewController.route = route
                navigationViewController.routeIndex = 0
                navigationViewController.routeOptions = navigationRouteOptions
                navigationViewController.navigationOptions = navigationOptions
            }
        default:
            break
        }
    }
}

import UIKit
import MapboxNavigation
import MapboxCoreNavigation
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
                                                                simulating: simulationIsEnabled ? .always : .onPoorGPS)
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
        // To create an instance of `NavigationViewController`
        // from `UIStoryboardSegue` `route`, `routeIndex` and `routeOptions`
        // properties of `NavigationViewController` must be pre-defined.
        switch segue.identifier ?? "" {
        case "NavigationSegue":
            if let navigationViewController = segue.destination as? NavigationViewController {
                navigationViewController.route = route
                navigationViewController.routeIndex = 0
                navigationViewController.routeOptions = navigationRouteOptions
                // `navigationOptions` property is optional.
                navigationViewController.navigationOptions = navigationOptions
                navigationViewController.delegate = self
                navigationViewController.modalPresentationStyle = .fullScreen
            }
        default:
            break
        }
    }
}

extension SegueViewController: NavigationViewControllerDelegate {
    
    func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool) {
        dismiss(animated: true)
    }
}

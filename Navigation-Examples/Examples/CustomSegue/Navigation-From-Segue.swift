/*
 This code example is part of the Mapbox Navigation SDK for iOS demo app,
 which you can build and run: https://github.com/mapbox/mapbox-navigation-ios-examples
 To learn more about each example in this app, including descriptions and links
 to documentation, see our docs: https://docs.mapbox.com/ios/navigation/examples/custom-segue
 */

import UIKit
import MapboxNavigation
import MapboxCoreNavigation
import MapboxDirections

class SegueViewController: UIViewController {
    
    var routeResponse: RouteResponse!
    
    var navigationRouteOptions: NavigationRouteOptions!
    
    var navigationOptions: NavigationOptions!
    
    @IBOutlet weak var presentNavigationButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupPresentNavigationButton()
        
        let origin = CLLocationCoordinate2DMake(37.77440680146262, -122.43539772352648)
        let destination = CLLocationCoordinate2DMake(37.76556957793795, -122.42409811526268)
        navigationRouteOptions = NavigationRouteOptions(coordinates: [origin, destination])
        
        Directions.shared.calculate(navigationRouteOptions) { [weak self] (_, result) in
            switch result {
            case .failure(let error):
                NSLog("Error occured: \(error.localizedDescription).")
            case .success(let response):
                guard let self = self else { return }
                
                self.routeResponse = response
                
                let navigationService = MapboxNavigationService(routeResponse: response,
                                                                routeIndex: 0,
                                                                routeOptions: self.navigationRouteOptions,
                                                                customRoutingProvider: NavigationSettings.shared.directions,
                                                                credentials: NavigationSettings.shared.directions.credentials,
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
                _ = navigationViewController.prepareViewLoading(routeResponse: routeResponse,
                                                                routeIndex: 0,
                                                                routeOptions: navigationRouteOptions)
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

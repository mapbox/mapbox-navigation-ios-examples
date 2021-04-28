import Foundation
import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import MapboxMaps

class CustomDestinationMarkerController: UIViewController {
    
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
                let navigationService = MapboxNavigationService(route: route, routeIndex: 0, routeOptions: routeOptions, simulating: simulationIsEnabled ? .always : .onPoorGPS)
                let navigationOptions = NavigationOptions(navigationService: navigationService)
                let navigationViewController = NavigationViewController(for: route, routeIndex: 0, routeOptions: routeOptions, navigationOptions: navigationOptions)
                navigationViewController.modalPresentationStyle = .fullScreen
                navigationViewController.routeLineTracksTraversal = true
                navigationViewController.delegate = self
                
                strongSelf.present(navigationViewController, animated: true)
            }
        }
    }
}

// MARK: - NavigationViewControllerDelegate methods

extension CustomDestinationMarkerController: NavigationViewControllerDelegate {
    
    func navigationViewController(_ navigationViewController: NavigationViewController, didAdd finalDestinationAnnotation: PointAnnotation) {
        var finalDestinationAnnotation = finalDestinationAnnotation
        finalDestinationAnnotation.image = UIImage(named: "marker")
        
        do {
            try navigationViewController.navigationMapView?.mapView.annotations.updateAnnotation(finalDestinationAnnotation)
        } catch {
            NSLog("Error occured: \(error.localizedDescription).")
        }
    }
    
    func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool) {
        dismiss(animated: true)
    }
}

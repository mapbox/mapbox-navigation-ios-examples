import Foundation
import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections

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
                navigationViewController.mapView?.delegate = strongSelf
                navigationViewController.routeLineTracksTraversal = true
                
                strongSelf.present(navigationViewController, animated: true, completion: nil)
            }
        }
    }
}

extension CustomDestinationMarkerController: MGLMapViewDelegate {

    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        var annotationImage = mapView.dequeueReusableAnnotationImage(withIdentifier: "marker")
        
        if annotationImage == nil {
            // Leaning Tower of Pisa by Stefan Spieler from the Noun Project.
            var image = UIImage(named: "marker")!
            
            // The anchor point of an annotation is currently always the center. To
            // shift the anchor point to the bottom of the annotation, the image
            // asset includes transparent bottom padding equal to the original image
            // height.
            //
            // To make this padding non-interactive, we create another image object
            // with a custom alignment rect that excludes the padding.
            image = image.withAlignmentRectInsets(UIEdgeInsets(top: 0, left: 0, bottom: image.size.height / 2, right: 0))
            
            // Initialize the ‘pisa’ annotation image with the UIImage we just loaded.
            annotationImage = MGLAnnotationImage(image: image, reuseIdentifier: "marker")
        }
        
        return annotationImage
    }
}

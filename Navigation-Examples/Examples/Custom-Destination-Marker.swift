import Foundation
import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections

class CustomDestinationMarkerController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let routeCoordinates = [
            CLLocationCoordinate2D(latitude: 59.3379254707993,  longitude: 18.0768391763866),
            CLLocationCoordinate2D(latitude: 59.3376613543215,  longitude: 18.0758977499228),
            CLLocationCoordinate2D(latitude: 59.3371292341531,  longitude: 18.0754779388695),
            CLLocationCoordinate2D(latitude: 59.3368658096911,  longitude: 18.0752713263541),
            CLLocationCoordinate2D(latitude: 59.3366161271274,  longitude: 18.0758013323718),
            CLLocationCoordinate2D(latitude: 59.3363847683606,  longitude: 18.0769377012062),
            CLLocationCoordinate2D(latitude: 59.3369299420601,  longitude: 18.0779707637829),
            CLLocationCoordinate2D(latitude: 59.3374784940673,  longitude: 18.0789771102838),
            CLLocationCoordinate2D(latitude: 59.3376624022706,  longitude: 18.0796752015449),
            CLLocationCoordinate2D(latitude: 59.3382345065107,  longitude: 18.0801207199294),
            CLLocationCoordinate2D(latitude:  59.338728497517,  longitude: 18.0793407846583),
            CLLocationCoordinate2D(latitude:  59.3390538588298, longitude:  18.0777368583247),
            CLLocationCoordinate2D(latitude:  59.3389021418961, longitude:  18.0769242264769),
            CLLocationCoordinate2D(latitude:  59.3383325439362, longitude:  18.0764655674924),
            CLLocationCoordinate2D(latitude:  59.3381526945276, longitude:  18.0757203959448),
            CLLocationCoordinate2D(latitude:  59.3383085323927, longitude:  18.0749662844197),
            CLLocationCoordinate2D(latitude:  59.3386507394432, longitude:  18.0749292910378),
            CLLocationCoordinate2D(latitude:  59.3396600470949, longitude:  18.0757133256584),
            CLLocationCoordinate2D(latitude:  59.3402031271014, longitude:  18.0770724776848),
            CLLocationCoordinate2D(latitude:  59.3399246668736, longitude:  18.0784376357593),
            CLLocationCoordinate2D(latitude:  59.3393711961939, longitude:  18.0786765675365),
            CLLocationCoordinate2D(latitude:  59.3383675368975, longitude:  18.0778982052741),
            CLLocationCoordinate2D(latitude:  59.3379254707993, longitude:  18.0768391763866),
            CLLocationCoordinate2D(latitude:  59.3376613543215, longitude:  18.0758977499228),
            CLLocationCoordinate2D(latitude:  59.3371292341531, longitude:  18.0754779388695),
            CLLocationCoordinate2D(latitude:  59.3368658096911, longitude:  18.0752713263541),
            CLLocationCoordinate2D(latitude:  59.3366161271274, longitude:  18.0758013323718),
            CLLocationCoordinate2D(latitude:  59.3363847683606, longitude:  18.0769377012062),
            CLLocationCoordinate2D(latitude:  59.3369299420601, longitude:  18.0779707637829),
            CLLocationCoordinate2D(latitude:  59.3374784940673, longitude:  18.0789771102838),
            CLLocationCoordinate2D(latitude:  59.3376624022706, longitude:  18.0796752015449),
            CLLocationCoordinate2D(latitude:  59.3382345065107, longitude:  18.0801207199294),
            CLLocationCoordinate2D(latitude:  59.338728497517,  longitude: 18.0793407846583),
            CLLocationCoordinate2D(latitude:  59.3390538588298, longitude:  18.0777368583247),
            CLLocationCoordinate2D(latitude:  59.3389021418961, longitude:  18.0769242264769),
            CLLocationCoordinate2D(latitude:  59.3383325439362, longitude:  18.0764655674924),
            CLLocationCoordinate2D(latitude:  59.3381526945276, longitude:  18.0757203959448),
            CLLocationCoordinate2D(latitude:  59.3383085323927, longitude:  18.0749662844197),
            CLLocationCoordinate2D(latitude:  59.3386507394432, longitude:  18.0749292910378),
            CLLocationCoordinate2D(latitude:  59.3396600470949, longitude:  18.0757133256584)
        ]

        let routeOptions = NavigationMatchOptions(coordinates: routeCoordinates, profileIdentifier: .automobile)
        routeOptions.waypointIndices = IndexSet([0, routeCoordinates.count - 1])
        routeOptions.includesSteps = true

        Directions.shared.calculateRoutes(matching: routeOptions) { (waypoints, routes, error) in
            guard let route = routes?.first, error == nil else {
                print(error!.localizedDescription)
                return
            }
            
            let navigationController = NavigationViewController(for: route)
            navigationController.delegate = self
            
            // This allows the developer to simulate the route.
            // Note: If copying and pasting this code in your own project,
            // comment out `simulationIsEnabled` as it is defined elsewhere in this project.
            if simulationIsEnabled {
                navigationController.routeController.locationManager = SimulatedLocationManager(route: route)
            }
            
            self.present(navigationController, animated: true, completion: nil)
        }
    }
}

extension CustomDestinationMarkerController: NavigationViewControllerDelegate {
    func navigationViewController(_ navigationViewController: NavigationViewController, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        var annotationImage = navigationViewController.mapView!.dequeueReusableAnnotationImage(withIdentifier: "marker")
        
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

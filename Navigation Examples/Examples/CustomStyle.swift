import Foundation
import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections

class CustomStyleViewController: UIViewController {
    override func viewDidLoad() {
        let origin = CLLocationCoordinate2DMake(37.77440680146262, -122.43539772352648)
        let destination = CLLocationCoordinate2DMake(37.76556957793795, -122.42409811526268)
        let options = NavigationRouteOptions(coordinates: [origin, destination])
        
        Directions.shared.calculate(options) { (waypoints, routes, error) in
            guard let route = routes?.first, error == nil else {
                print(error!.localizedDescription)
                return
            }
            
            // The third argument `locationManager` is optional
            let navigationController = NavigationViewController(for: route, styles: [CustomDayStyle(), CustomNightStyle()], locationManager: navigationLocationManager(for: route))
            self.present(navigationController, animated: true, completion: nil)
        }
    }
}



class CustomDayStyle: DayStyle {
    required init() {
        super.init()
        mapStyleURL = URL(string: "mapbox://styles/mapbox/satellite-streets-v9")!
        styleType = .dayStyle
    }
    
    override func apply() {
        super.apply()
        BottomBannerView.appearance().backgroundColor = .orange
    }
}


class CustomNightStyle: NightStyle {
    required init() {
        super.init()
        mapStyleURL = URL(string: "mapbox://styles/mapbox/satellite-streets-v9")!
        styleType = .nightStyle
    }
    
    override func apply() {
        super.apply()
        BottomBannerView.appearance().backgroundColor = .purple
    }
}

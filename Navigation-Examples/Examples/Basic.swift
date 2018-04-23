import UIKit
import Mapbox
import MapboxDirections
import MapboxCoreNavigation
import MapboxNavigation

class BasicViewController: UIViewController, CLLocationManagerDelegate {
    
    let locationManager = CLLocationManager()
    
    var navViewController: NavigationViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let origin = Waypoint(coordinate: (locationManager.location?.coordinate)!, name: "User location")
        let destination = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.342867, longitude: -121.893310), name: "Original destination")
        let options = NavigationRouteOptions(waypoints: [origin, destination])

        _ = Directions.shared.calculate(options) { (waypoints, routes, error) in
            
            let route = routes?.first
            self.navViewController = NavigationViewController(for: route!)
            
            let button = self.addButton()
            
            self.navViewController.view.addSubview(button)
            
            self.present(self.navViewController, animated: true, completion: nil)
            
            
        }
    
    }
    
    func addButton() -> UIButton{
        let button = UIButton(frame: CGRect(x: 20, y: 160, width: 120, height: 50))
        button.layer.masksToBounds = true
        button.backgroundColor = UIColor.red
        button.setTitleColor(UIColor.white, for: .normal)
        button.setTitle("Change Destination", for: .normal)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
        
        
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        
        self.view.addSubview(button)
        
        return button
        
    }
    
    @objc func buttonAction(sender: UIButton) {
        print("Button pressed")
        
        let origin = Waypoint(coordinate: (locationManager.location?.coordinate)!, name: "User location")
        let newDestination = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 36.962237, longitude: -122.022399), name: "New destination")
        let options = NavigationRouteOptions(waypoints: [origin, newDestination])
        
        Directions.shared.calculate(options) { (waypoints, routes, error) in
            guard let route = routes?.first, error == nil else {
                print(error!.localizedDescription)
                return
            }
            
            // User destination annotation should update after this
            // is called, but it does not.
            self.navViewController.route = route
        }
        
    }
    
}

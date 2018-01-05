import Foundation
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections

class EmbeddedExampleViewController: UIViewController  {
 
    var route: Route?
    @IBAction func beginPressed(_ sender: Any) {
        start()
    }
    func start() {
        let origin = CLLocationCoordinate2DMake(37.77440680146262, -122.43539772352648)
        let destination = CLLocationCoordinate2DMake(37.76556957793795, -122.42409811526268)
        let options = NavigationRouteOptions(coordinates: [origin, destination])
        
        Directions.shared.calculate(options) { (waypoints, routes, error) in
            guard let route = routes?.first, error == nil else {
                print(error!.localizedDescription)
                return
            }
            let nav = NavigationViewController(for: route)
            nav.title = "Navigation"
            let somethingElse = UIViewController()
            somethingElse.view.backgroundColor = .red
            somethingElse.title = "Something Else"
            let tab = UITabBarController()
            tab.title = "Yay, Embedded NVC!"
            tab.viewControllers = [nav, somethingElse]
            
            self.navigationController?.pushViewController(tab, animated: true)
        }
    }

}

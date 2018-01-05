import Foundation
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections

class EmbeddedExampleViewController: UIViewController  {
 
    @IBOutlet weak var loadButton: UIButton!
    @IBOutlet weak var container: UIView!
    var route: Route?

    lazy var options: NavigationRouteOptions = {
        let origin = CLLocationCoordinate2DMake(37.77440680146262, -122.43539772352648)
        let destination = CLLocationCoordinate2DMake(37.76556957793795, -122.42409811526268)
        return NavigationRouteOptions(coordinates: [origin, destination])
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        calculateDirections()
    }
    
    func calculateDirections() {
        Directions.shared.calculate(options) { (waypoints, routes, error) in
            guard let route = routes?.first, error == nil else {
                print(error!.localizedDescription)
                return
            }
            self.route = route
            self.loadButton.isEnabled = true
        }
    }
    
    @IBAction func startEmbeddedNavigation(_ sender: Any) {
        let nav = NavigationViewController(for: route!)
        addChildViewController(nav)
        container.addSubview(nav.view)
        nav.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            nav.view.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 0),
            nav.view.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: 0),
            nav.view.topAnchor.constraint(equalTo: container.topAnchor, constant: 0),
            nav.view.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: 0)
            ])
        self.didMove(toParentViewController: self)
    }

}


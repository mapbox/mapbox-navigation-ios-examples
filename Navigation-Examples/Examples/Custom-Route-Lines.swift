import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import MapboxMaps
import Turf

class CustomRouteLinesViewController: UIViewController {
    
    var navigationMapView: NavigationMapView!
    var route: Route!
    var navigationRouteOptions: NavigationRouteOptions!
    var startNavigationButton: UIButton!
    
    // MARK: - UIViewController lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationMapView()
        setupStartNavigationButton()
        requestRoute()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        startNavigationButton.layer.cornerRadius = startNavigationButton.bounds.midY
        startNavigationButton.clipsToBounds = true
        startNavigationButton.setNeedsDisplay()
    }
    
    // MARK: - Setting-up methods
    
    func setupNavigationMapView() {
        navigationMapView = NavigationMapView(frame: view.bounds)
        navigationMapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        navigationMapView.delegate = self
        navigationMapView.mapView.update {
            $0.location.puckType = .puck2D()
        }

        view.addSubview(navigationMapView)
    }
    
    func setupStartNavigationButton() {
        startNavigationButton = UIButton()
        startNavigationButton.setTitle("Start Navigation", for: .normal)
        startNavigationButton.translatesAutoresizingMaskIntoConstraints = false
        startNavigationButton.backgroundColor = .lightGray
        startNavigationButton.setTitleColor(.darkGray, for: .highlighted)
        startNavigationButton.setTitleColor(.white, for: .normal)
        startNavigationButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        startNavigationButton.addTarget(self, action: #selector(startNavigationButtonPressed(_:)), for: .touchUpInside)
        startNavigationButton.isHidden = true
        view.addSubview(startNavigationButton)

        startNavigationButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -20).isActive = true
        startNavigationButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
    }

    @objc func startNavigationButtonPressed(_ sender: UIButton) {
        let navigationService = MapboxNavigationService(route: route,
                                                        routeIndex: 0,
                                                        routeOptions: navigationRouteOptions,
                                                        simulating: simulationIsEnabled ? .always : .onPoorGPS)

        let navigationOptions = NavigationOptions(navigationService: navigationService)
        let navigationViewController = NavigationViewController(for: route,
                                                                routeIndex: 0,
                                                                routeOptions: navigationRouteOptions,
                                                                navigationOptions: navigationOptions)
        navigationViewController.navigationMapView?.delegate = self
        navigationViewController.modalPresentationStyle = .fullScreen
        
        navigationViewController.routeLineTracksTraversal = true

        present(navigationViewController, animated: true, completion: nil)
    }

    func requestRoute() {
        let origin = CLLocationCoordinate2DMake(37.773, -122.411)
        let destination = CLLocationCoordinate2DMake(37.763252389415186, -122.40061448679577)
        let navigationRouteOptions = NavigationRouteOptions(coordinates: [origin, destination])
        
        let cameraOptions = CameraOptions(center: origin, zoom: 13.0)
        self.navigationMapView.mapView.camera.setCamera(to: cameraOptions)
        
        Directions.shared.calculate(navigationRouteOptions) { [weak self] (session, result) in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let response):
                guard let routes = response.routes,
                      let currentRoute = routes.first,
                      let self = self else { return }
                
                self.route = currentRoute
                self.navigationRouteOptions = navigationRouteOptions
                self.startNavigationButton.isHidden = false
                self.navigationMapView.show(routes)
                self.navigationMapView.showWaypoints(on: currentRoute)
            }
        }
    }
    
    func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - NavigationMapViewDelegate methods

extension CustomRouteLinesViewController: NavigationMapViewDelegate {
    
    func navigationMapView(_ navigationMapView: NavigationMapView, shapeFor route: Route) -> LineString? {
        return route.shape
    }
    
    func navigationMapView(_ navigationMapView: NavigationMapView, casingShapeFor route: Route) -> LineString? {
        return route.shape
    }
    
    func navigationMapView(_ navigationMapView: NavigationMapView, routeLineLayerWithIdentifier identifier: String, sourceIdentifier: String) -> LineLayer? {
        var lineLayer = LineLayer(id: identifier)
        lineLayer.source = sourceIdentifier
        lineLayer.paint?.lineColor = .constant(.init(color: .red))
        lineLayer.paint?.lineWidth = .constant(10.0)
        lineLayer.layout?.lineJoin = .constant(.round)
        lineLayer.layout?.lineCap = .constant(.round)
        
        return lineLayer
    }
    
    func navigationMapView(_ navigationMapView: NavigationMapView, routeCasingLineLayerWithIdentifier identifier: String, sourceIdentifier: String) -> LineLayer? {
        var lineLayer = LineLayer(id: identifier)
        lineLayer.source = sourceIdentifier
        lineLayer.paint?.lineColor = .constant(.init(color: .green))
        lineLayer.paint?.lineWidth = .constant(14.0)
        lineLayer.layout?.lineJoin = .constant(.round)
        lineLayer.layout?.lineCap = .constant(.round)
        
        return lineLayer
    }
}

// MARK: - NavigationViewControllerDelegate methods

extension CustomRouteLinesViewController: NavigationViewControllerDelegate {
    
    func navigationViewController(_ navigationViewController: NavigationViewController, routeLineLayerWithIdentifier identifier: String, sourceIdentifier: String) -> LineLayer? {
        var lineLayer = LineLayer(id: identifier)
        lineLayer.source = sourceIdentifier
        lineLayer.paint?.lineColor = .constant(.init(color: .red))
        lineLayer.paint?.lineWidth = .constant(10.0)
        lineLayer.layout?.lineJoin = .constant(.round)
        lineLayer.layout?.lineCap = .constant(.round)
        
        return lineLayer
    }
    
    func navigationViewController(_ navigationViewController: NavigationViewController, routeCasingLineLayerWithIdentifier identifier: String, sourceIdentifier: String) -> LineLayer? {
        var lineLayer = LineLayer(id: identifier)
        lineLayer.source = sourceIdentifier
        lineLayer.paint?.lineColor = .constant(.init(color: .green))
        lineLayer.paint?.lineWidth = .constant(14.0)
        lineLayer.layout?.lineJoin = .constant(.round)
        lineLayer.layout?.lineCap = .constant(.round)
        
        return lineLayer
    }
}

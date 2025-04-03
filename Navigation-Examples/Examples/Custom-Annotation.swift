/*
 This code example is part of the Mapbox Navigation SDK for iOS demo app,
 which you can build and run: https://github.com/mapbox/mapbox-navigation-ios-examples
 To learn more about each example in this app, including descriptions and links
 to documentation, see our docs: https://docs.mapbox.com/ios/navigation/examples/advanced
 */

import MapboxCoreNavigation
import MapboxDirections
import MapboxMaps
import MapboxNavigation
import UIKit

class CustomRouteAnnotationViewController: UIViewController {
    private let routingProvider = MapboxRoutingProvider()

    private var mapRouteAnnotationManager: CustomRouteAnnotationManager?
    private var activeGuidanceRouteAnnotationManager: CustomRouteAnnotationManager?

    private var navigationMapView: NavigationMapView!
    private var indexedRouteResponse: IndexedRouteResponse? {
        didSet {
            guard indexedRouteResponse?.currentRoute != nil else {
                navigationMapView.removeRoutes()
                navigationMapView.removeWaypoints()
                return
            }
            showCurrentRoute()
        }
    }

    func showCurrentRoute() {
        guard let indexedRouteResponse else { return }

        navigationMapView.showcase(indexedRouteResponse)
        if let mainRoute = indexedRouteResponse.currentRoute {
            mapRouteAnnotationManager?.showRouteAnnotation(
                mainRoute: mainRoute,
                alternatives: indexedRouteResponse.parseAlternativeRoutes()
            )
        }
    }

    var startButton: UIButton!

    // MARK: - UIViewController lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureMapView()
        configureStartButton()
        view.setNeedsLayout()
    }

    private func configureMapView() {
        navigationMapView = NavigationMapView(frame: view.bounds)
        navigationMapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navigationMapView)
        NSLayoutConstraint.activate([
            navigationMapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationMapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navigationMapView.topAnchor.constraint(equalTo: view.topAnchor),
            navigationMapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        navigationMapView.delegate = self
        navigationMapView.userLocationStyle = .puck2D()

        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        navigationMapView.addGestureRecognizer(gesture)

        mapRouteAnnotationManager = CustomRouteAnnotationManager(navigationMapView: navigationMapView)
    }

    private func configureStartButton() {
        startButton = UIButton()
        startButton.setTitle("Start Navigation", for: .normal)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.backgroundColor = .blue
        startButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        startButton.addTarget(self, action: #selector(startButtonTapped(sender:)), for: .touchUpInside)
        startButton.isHidden = true
        startButton.layer.cornerRadius = 15
        startButton.clipsToBounds = true
        view.addSubview(startButton)

        startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20).isActive = true
        startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }

    @objc func startButtonTapped(sender: UIButton) {
        guard let indexedRouteResponse else { return }

        // For demonstration purposes, simulate locations if the Simulate Navigation option is on.
        let navigationService = MapboxNavigationService(indexedRouteResponse: indexedRouteResponse,
                                                        customRoutingProvider: routingProvider,
                                                        credentials: NavigationSettings.shared.directions.credentials,
                                                        simulating: simulationIsEnabled ? .always : .onPoorGPS)
        let navigationOptions = NavigationOptions(navigationService: navigationService)
        let navigationViewController = NavigationViewController(for: indexedRouteResponse,
                                                                navigationOptions: navigationOptions)
        navigationViewController.delegate = self
        navigationViewController.modalPresentationStyle = .fullScreen
        navigationViewController.navigationMapView?.showsRelativeDurationOnContinuousAlternativeRoutes = false
        if let view = navigationViewController.navigationMapView {
            activeGuidanceRouteAnnotationManager = CustomRouteAnnotationManager(navigationMapView: view)
        }

        startButton.isHidden = true
        present(navigationViewController, animated: true, completion: nil)
    }

    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .ended else { return }
        let location = navigationMapView.mapView.mapboxMap.coordinate(for: gesture.location(in: navigationMapView.mapView))

        requestRoute(destination: location)
    }

    func requestRoute(destination: CLLocationCoordinate2D) {
        guard let userLocation = navigationMapView.mapView.location.latestLocation else { return }

        let location = CLLocation(latitude: userLocation.coordinate.latitude,
                                  longitude: userLocation.coordinate.longitude)

        let userWaypoint = Waypoint(location: location, heading: userLocation.heading)
        let destinationWaypoint = Waypoint(coordinate: destination)
        let navigationRouteOptions = NavigationRouteOptions(waypoints: [userWaypoint, destinationWaypoint])

        routingProvider.calculateRoutes(options: navigationRouteOptions) { [weak self] result in
            switch result {
            case let .failure(error):
                print(error.localizedDescription)
            case let .success(indexedRouteResponse):
                guard let self else { return }

                self.indexedRouteResponse = indexedRouteResponse
                self.startButton?.isHidden = false
            }
        }
    }
}

extension CustomRouteAnnotationViewController: NavigationMapViewDelegate {
    func navigationMapView(_: NavigationMapView, didSelect alternative: AlternativeRoute) {
        indexedRouteResponse = alternative.indexedRouteResponse
    }
}

extension CustomRouteAnnotationViewController: NavigationViewControllerDelegate {
    func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling _: Bool) {
        navigationViewController.dismiss(animated: true)
        startButton.isHidden = false
        showCurrentRoute()
    }

    func navigationViewController(
        _ navigationViewController: NavigationViewController,
        didUpdateAlternatives updatedAlternatives: [AlternativeRoute],
        removedAlternatives: [AlternativeRoute]
    ) {
        let mainRoute = navigationViewController.navigationService.routeProgress.route
        activeGuidanceRouteAnnotationManager?.showRouteAnnotation(
            mainRoute: mainRoute,
            alternatives: updatedAlternatives
        )
    }

    func navigationViewController(
        _ navigationViewController: NavigationViewController,
        didRerouteAlong route: Route
    ) {
        activeGuidanceRouteAnnotationManager?.showRouteAnnotation(
            mainRoute: route,
            alternatives: navigationViewController.continuousAlternatives
        )
    }

    func navigationViewController(
        _ navigationViewController: NavigationViewController,
        didRefresh routeProgress: RouteProgress
    ) {
        activeGuidanceRouteAnnotationManager?.showRouteAnnotation(
            mainRoute: routeProgress.route,
            alternatives: navigationViewController.continuousAlternatives
        )
    }
}

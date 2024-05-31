/*
 This code example is part of the Mapbox Navigation SDK for iOS demo app,
 which you can build and run: https://github.com/mapbox/mapbox-navigation-ios-examples
 To learn more about each example in this app, including descriptions and links
 to documentation, see our docs: https://docs.mapbox.com/ios/navigation/examples
 */

import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import MapboxMaps

class ZoneAvoidanceViewController: UIViewController, NavigationMapViewDelegate, NavigationViewControllerDelegate {

    var navigationMapView: NavigationMapView!
    
    var routeResponse: RouteResponse? {
        didSet {
            guard let routes = routeResponse?.routes, let currentRoute = routes.first else {
                navigationMapView.removeRoutes()
                return
            }
            navigationMapView.show(routes)
            navigationMapView.showWaypoints(on: currentRoute)
        }
    }
    
    var startButton: UIButton!
    var recipeNameTextField: UITextField!

    // MARK: - UIViewController lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationMapView = NavigationMapView(frame: view.bounds)
        navigationMapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        navigationMapView.delegate = self
        navigationMapView.userLocationStyle = .puck2D()
        
        let navigationViewportDataSource = NavigationViewportDataSource(navigationMapView.mapView, viewportDataSourceType: .raw)
        navigationViewportDataSource.options.followingCameraOptions.zoomUpdatesAllowed = false
        navigationViewportDataSource.followingMobileCamera.zoom = 13.0
        navigationMapView.navigationCamera.viewportDataSource = navigationViewportDataSource
        
        view.addSubview(navigationMapView)

        startButton = UIButton()
        startButton.setTitle("Start Navigation", for: .normal)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.backgroundColor = .blue
        startButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        startButton.addTarget(self, action: #selector(tappedStartButton(sender:)), for: .touchUpInside)
        startButton.isHidden = true
        view.addSubview(startButton)
        
        startButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -20).isActive = true
        startButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        view.setNeedsLayout()

        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        navigationMapView.addGestureRecognizer(gesture)

        setupRecipeTextField()
    }

    func setupRecipeTextField() {
        recipeNameTextField = UITextField(frame: CGRect(x: 75, y: 100, width: 300, height: 35))
        recipeNameTextField.placeholder = "Recipe name"
        recipeNameTextField.borderStyle = .roundedRect
        recipeNameTextField.center.x = view.center.x
        recipeNameTextField.isHidden = false
        view.addSubview(recipeNameTextField)
    }

    // Override layout lifecycle callback to be able to style the start button.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        startButton.layer.cornerRadius = startButton.bounds.midY
        startButton.clipsToBounds = true
        startButton.setNeedsDisplay()
    }
    
    @objc func tappedStartButton(sender: UIButton) {
        guard let routeResponse = routeResponse else { return }

        // For demonstration purposes, simulate locations if the Simulate Navigation option is on.
        let indexedRouteResponse = IndexedRouteResponse(routeResponse: routeResponse, routeIndex: 0)
        let navigationService = MapboxNavigationService(indexedRouteResponse: indexedRouteResponse,
                                                        customRoutingProvider: NavigationSettings.shared.directions,
                                                        credentials: NavigationSettings.shared.directions.credentials,
                                                        simulating: simulationIsEnabled ? .always : .onPoorGPS)
        let navigationOptions = NavigationOptions(navigationService: navigationService)
        let navigationViewController = NavigationViewController(for: indexedRouteResponse,
                                                                navigationOptions: navigationOptions)
        navigationViewController.delegate = self

        present(navigationViewController, animated: true, completion: nil)
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .ended else { return }
        let location = navigationMapView.mapView.mapboxMap.coordinate(for: gesture.location(in: navigationMapView.mapView))
        
        requestRoute(destination: location)
    }

    func requestRoute(destination: CLLocationCoordinate2D) {
        guard let userLocation = navigationMapView.mapView.location.latestLocation else { return }
        guard let recipeName = recipeNameTextField.text, !recipeName.isEmpty else {
            let alert = UIAlertController(
                title: "Error",
                message: "Please type BYOND recipe name first",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        let location = CLLocation(latitude: userLocation.coordinate.latitude,
                                  longitude: userLocation.coordinate.longitude)
        
        let userWaypoint = Waypoint(location: location,
                                    heading: userLocation.heading,
                                    name: "user")
        
        let destinationWaypoint = Waypoint(coordinate: destination)
        let navigationRouteOptions = ZoneAvoidanceRouteOptions(
            waypoints: [userWaypoint, destinationWaypoint],
            byondRecipeName: recipeName
        )

        Directions.shared.calculate(navigationRouteOptions) { [weak self] (_, result) in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let response):
                guard let routes = response.routes,
                      let currentRoute = routes.first,
                      let self = self else { return }

                // As an example we are cheking only the first leg on the main route
                checkLegForViolations(currentRoute.legs.first!)
                self.routeResponse = response
                self.startButton?.isHidden = false
                self.recipeNameTextField?.isHidden = true
                self.navigationMapView.show(routes)
                self.navigationMapView.showWaypoints(on: currentRoute)
            }
        }
    }

    func checkLegForViolations(_ leg: RouteLeg) {
        // Documentation on notifications: https://docs.mapbox.com/api/navigation/directions/#notification-object
        // BYOND violation has subtype "byondExcludeRouting"

        guard let notificationsJsonObj = leg.foreignMembers["notifications"] else { return }
        guard case let .array(notifications) = notificationsJsonObj else { return }

        let notificationSubtypes = notifications
            .compactMap { $0 }
            .compactMap { (notification: JSONValue) -> JSONValue?? in
                if case let .object(properties) = notification {
                    return properties["subtype"]
                } else {
                    return nil
                }
            }
            .compactMap { $0 }

        guard notificationSubtypes.contains(where: { subtypeJSONValue in
            if case let .string(subtype) = subtypeJSONValue {
                return subtype == "byondExcludeRouting"
            } else {
                return false
            }
        }) else { return }

        let alert = UIAlertController(
            title: "Violation",
            message: "The built route contains a BYOND violation",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool) {
        dismiss(animated: true, completion: nil)
    }
}

class ZoneAvoidanceRouteOptions: NavigationRouteOptions {
    var byondRecipeName: String!

    // add byond_recipe_name to URLQueryItems
    override var urlQueryItems: [URLQueryItem] {
        var items = super.urlQueryItems
        items.append(URLQueryItem(name: "byond_recipe_name", value: byondRecipeName))
        return items
    }
    
    // create initializer to take in the byond_recipe_name
    public init(waypoints: [Waypoint], byondRecipeName: String) {
        self.byondRecipeName = byondRecipeName
        super.init(waypoints: waypoints)
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    required init(waypoints: [Waypoint], profileIdentifier: ProfileIdentifier? = .automobileAvoidingTraffic) {
        fatalError("init(waypoints:profileIdentifier:) has not been implemented")
    }
    
    required init(waypoints: [Waypoint], profileIdentifier: ProfileIdentifier? = .automobileAvoidingTraffic, queryItems: [URLQueryItem]? = nil) {
        fatalError("init(waypoints:profileIdentifier:queryItems:) has not been implemented")
    }
}

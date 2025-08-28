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

class BetaQueryViewController: UIViewController, NavigationMapViewDelegate, NavigationViewControllerDelegate {
    private let routingProvider = MapboxRoutingProvider()
    
    var navigationMapView: NavigationMapView!
    
    var indexedRouteResponse: IndexedRouteResponse? {
        didSet {
            guard let routes = indexedRouteResponse?.routeResponse.routes,
                  let currentRoute = indexedRouteResponse?.currentRoute else {
                navigationMapView.removeRoutes()
                return
            }
            navigationMapView.show(routes)
            navigationMapView.showWaypoints(on: currentRoute)
        }
    }
    
    var startButton: UIButton!
    var datePicker: UIDatePicker!
    var dateTextField: UITextField!
    var departureTime: Date!
    
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
        
        setupDateProperties()
    }
    
    // Override layout lifecycle callback to be able to style the start button.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        startButton.layer.cornerRadius = startButton.bounds.midY
        startButton.clipsToBounds = true
        startButton.setNeedsDisplay()
    }
    
    func setupDateProperties() {
        dateTextField = UITextField(frame: CGRect(x: 75, y: 100, width: 200, height: 35))
        dateTextField.placeholder = "Select departure time"
        dateTextField.backgroundColor = UIColor.white
        dateTextField.borderStyle = .roundedRect
        dateTextField.center.x = view.center.x
        dateTextField.isHidden = false
        showDatePicker()
        view.addSubview(dateTextField)
    }

    func showDatePicker() {
        datePicker = UIDatePicker()
        datePicker.datePickerMode = .time
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }
        datePicker.minimumDate = Date()

        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: #selector(doneButtonPressed))
        toolbar.setItems([doneButton], animated: true)

        dateTextField?.inputAccessoryView = toolbar
        dateTextField?.inputView = datePicker
    }
    
    @objc func doneButtonPressed() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm" // format date correctly
        dateTextField.text = dateFormatter.string(from: datePicker.date)
        self.view.endEditing(true)
        
        // only allow user to request route after selecting departure time
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        navigationMapView.addGestureRecognizer(gesture)
    }
    
    @objc func tappedStartButton(sender: UIButton) {
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
        
        let userWaypoint = Waypoint(location: location,
                                    heading: userLocation.heading,
                                    name: "user")
        
        let destinationWaypoint = Waypoint(coordinate: destination)
        let navigationRouteOptions = MopedRouteOptions(waypoints: [userWaypoint, destinationWaypoint], departTime: dateTextField.text!)
                
        routingProvider.calculateRoutes(options: navigationRouteOptions) { [weak self] result in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let indexedRouteResponse):
                    guard let routes = indexedRouteResponse.routeResponse.routes,
                      let currentRoute = indexedRouteResponse.currentRoute,
                      let self else { return }

                self.indexedRouteResponse = indexedRouteResponse
                self.startButton?.isHidden = false
                self.dateTextField?.isHidden = true
                self.navigationMapView.show(routes)
                self.navigationMapView.showWaypoints(on: currentRoute)
            }
        }
    }
    
    func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool) {
        dismiss(animated: true, completion: nil)
    }
}

class MopedRouteOptions: NavigationRouteOptions {
    enum CodingKeys: String, CodingKey {
        case departureTime = "depart_at"
    }
    var departureTime: String?

    // Add departureTime to URLQueryItems
    override var urlQueryItems: [URLQueryItem] {
        var items = super.urlQueryItems
        let parameter = URLQueryItem(name: CodingKeys.departureTime.rawValue, value: departureTime)
        items.append(parameter)
        return items
    }
    
    // Create initializer to take in the departure time
    public init(waypoints: [Waypoint], departTime: String) {
        departureTime = departTime
        super.init(waypoints: waypoints)
    }

    // Implement decoding, so the custom parameter is preserved when copying the options
    required init(from decoder: any Decoder) throws {
        try super.init(from: decoder)

        let container = try decoder.container(keyedBy: CodingKeys.self)
        departureTime = try container.decodeIfPresent(String.self, forKey: .departureTime)
    }

    // Implement decoding, so the custom parameter is preserved when copying the options
    override func encode(to encoder: any Encoder) throws {
        try super.encode(to: encoder)

        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(departureTime, forKey: .departureTime)
    }

    // Set the custom parameter value from the queryItems parameter, so it is preserved on reroute requests
    required init(
        waypoints: [Waypoint],
        profileIdentifier: ProfileIdentifier? = .automobileAvoidingTraffic,
        queryItems: [URLQueryItem]? = nil) {
            let mappedUrlItem = queryItems?.first(where: { $0.name == CodingKeys.departureTime.stringValue })
            self.departureTime = mappedUrlItem?.value

            super.init(waypoints: waypoints, profileIdentifier: profileIdentifier, queryItems: queryItems)
    }
}

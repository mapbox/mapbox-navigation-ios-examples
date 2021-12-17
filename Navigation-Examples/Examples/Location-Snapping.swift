/*
 This code example is part of the Mapbox Navigation SDK for iOS demo app,
 which you can build and run: https://github.com/mapbox/mapbox-navigation-ios-examples
 To learn more about each example in this app, including descriptions and links
 to documentation, see our docs: https://docs.mapbox.com/ios/navigation/examples/location-snapping
 */

import UIKit
import MapboxNavigation
import MapboxCoreNavigation
import MapboxMaps

class LocationSnappingViewController: UIViewController {
    
    private lazy var navigationMapView = NavigationMapView(frame: view.bounds)
    private let toggleButton = UIButton()
    private let passiveLocationManager = PassiveLocationManager()
    private lazy var passiveLocationProvider = PassiveLocationProvider(locationManager: passiveLocationManager)
    
    private var isSnappingEnabled: Bool = false {
        didSet {
            toggleButton.backgroundColor = isSnappingEnabled ? .blue : .darkGray
            let locationProvider: LocationProvider = isSnappingEnabled ? passiveLocationProvider : AppleLocationProvider()
            navigationMapView.mapView.location.overrideLocationProvider(with: locationProvider)
            passiveLocationProvider.startUpdatingLocation()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationMapView()
        setupSnappingToggle()
    }
    
    private func setupNavigationMapView() {
        navigationMapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        navigationMapView.userLocationStyle = .puck2D()
        
        let navigationViewportDataSource = NavigationViewportDataSource(navigationMapView.mapView)
        navigationViewportDataSource.options.followingCameraOptions.zoomUpdatesAllowed = false
        navigationViewportDataSource.followingMobileCamera.zoom = 17.0
        navigationMapView.navigationCamera.viewportDataSource = navigationViewportDataSource
        
        view.addSubview(navigationMapView)
    }
    
    private func setupSnappingToggle() {
        toggleButton.setTitle("Snap to Roads", for: .normal)
        toggleButton.layer.cornerRadius = 5
        toggleButton.translatesAutoresizingMaskIntoConstraints = false
        isSnappingEnabled = false
        toggleButton.addTarget(self, action: #selector(toggleSnapping), for: .touchUpInside)
        view.addSubview(toggleButton)
        toggleButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50).isActive = true
        toggleButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        toggleButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        toggleButton.sizeToFit()
        toggleButton.titleLabel?.font = UIFont.systemFont(ofSize: 25)
    }
    
    @objc private func toggleSnapping() {
        isSnappingEnabled.toggle()
    }
}

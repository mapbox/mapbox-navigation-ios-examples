import UIKit
import MapboxNavigation
import MapboxCoreNavigation
import MapboxMaps

class LocationSnappingViewController: UIViewController {
    private lazy var navigationMapView = NavigationMapView(frame: view.bounds)
    private let toggleButton = UIButton()
    private let passiveLocationProvider = PassiveLocationManager(dataSource: PassiveLocationDataSource())
    
    private var isSnappingEnabled: Bool = false {
        didSet {
            let title = isSnappingEnabled ? "Disable snapping" : "Enable snapping"
            toggleButton.setTitle(title, for: .normal)
            let locationProvider: LocationProvider = isSnappingEnabled ? passiveLocationProvider : AppleLocationProvider()
            navigationMapView.mapView.locationManager.overrideLocationProvider(with: locationProvider)
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
        navigationMapView.mapView.update {
            $0.location.puckType = .puck2D()
        }
        
        // TODO: Provide a reliable way of setting camera to current coordinate.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if let coordinate = self.navigationMapView.mapView.locationManager.latestLocation?.coordinate {
                // To make sure that buildings are rendered increase zoomLevel to value which is higher than 16.0.
                // More details can be found here: https://docs.mapbox.com/vector-tiles/reference/mapbox-streets-v8/#building
                self.navigationMapView.mapView.cameraManager.setCamera(centerCoordinate: coordinate, zoom: 17.0)
            }
        }
        
        view.addSubview(navigationMapView)
    }
    
    private func setupSnappingToggle() {
        toggleButton.layer.cornerRadius = 5
        toggleButton.translatesAutoresizingMaskIntoConstraints = false
        isSnappingEnabled = false
        toggleButton.addTarget(self, action: #selector(toggleSnapping), for: .touchUpInside)
        view.addSubview(toggleButton)
        toggleButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50).isActive = true
        toggleButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        toggleButton.backgroundColor = .blue
        toggleButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        toggleButton.sizeToFit()
        toggleButton.titleLabel?.font = UIFont.systemFont(ofSize: 25)
    }
    
    @objc private func toggleSnapping() {
        isSnappingEnabled.toggle()
    }
}

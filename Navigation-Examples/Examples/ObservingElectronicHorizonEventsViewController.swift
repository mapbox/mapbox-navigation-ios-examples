import UIKit
import MapboxNavigation
import MapboxCoreNavigation
import MapboxMaps

class ObservingElectronicHorizonEventsViewController: UIViewController {
    private lazy var navigationMapView = NavigationMapView(frame: view.bounds)

    private let upcomingIntersectionLabel = UILabel()
    private let passiveLocationManager = PassiveLocationManager(dataSource: PassiveLocationDataSource())

    private var currentEdgeIdentifier: ElectronicHorizon.Edge.Identifier?
    private var nextEdgeIdentifier: ElectronicHorizon.Edge.Identifier?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationMapView()
        setupUpcomingIntersectionLabel()
        subscribeToElectronicHorizonUpdates()
    }

    func setupNavigationMapView() {
        navigationMapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        navigationMapView.mapView.locationManager.overrideLocationProvider(with: passiveLocationManager)
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

    private func setupUpcomingIntersectionLabel() {
        view.addSubview(upcomingIntersectionLabel)
        upcomingIntersectionLabel.widthAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.9).isActive = true
        upcomingIntersectionLabel.translatesAutoresizingMaskIntoConstraints = false
        upcomingIntersectionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10).isActive = true
        upcomingIntersectionLabel.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        upcomingIntersectionLabel.backgroundColor = .white
        upcomingIntersectionLabel.layer.cornerRadius = 5
        upcomingIntersectionLabel.numberOfLines = 0
    }

    private func subscribeToElectronicHorizonUpdates() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didUpdateElectronicHorizonPosition),
                                               name: .electronicHorizonDidUpdatePosition,
                                               object: nil)
    }

    @objc private func didUpdateElectronicHorizonPosition(_ notification: Notification) {
        guard let horizonTree = notification.userInfo?[ElectronicHorizon.NotificationUserInfoKey.treeKey] as? ElectronicHorizon else {
            return
        }
        
        // Avoid repeating edges that have already been shown.
        guard currentEdgeIdentifier != horizonTree.start.identifier ||
                nextEdgeIdentifier != horizonTree.start.outletEdges.first?.identifier else {
            return
        }
        currentEdgeIdentifier = horizonTree.start.identifier
        nextEdgeIdentifier = horizonTree.start.outletEdges.first?.identifier
        guard let currentEdgeIdentifier = currentEdgeIdentifier,
              let nextEdgeIdentifier = nextEdgeIdentifier else {
            return
        }

        guard let currentRoadName = edgeName(identifier: currentEdgeIdentifier),
              let nextRoadName = edgeName(identifier: nextEdgeIdentifier) else {
            return
        }
        var statusString = "\(currentRoadName)\napproaching "
        
        // If there is an upcoming intersection, include the names of the cross street.
        if horizonTree.start.outletEdges.count > 1,
           let branchEdgeName = edgeName(identifier: horizonTree.start.outletEdges[1].identifier),
           branchEdgeName != currentRoadName {
            statusString += "intersection with:\n\(branchEdgeName)\nand\n"
        }
        statusString += "\(nextRoadName)"
        DispatchQueue.main.async {
            self.upcomingIntersectionLabel.text = statusString
            self.upcomingIntersectionLabel.sizeToFit()
        }
    }

    private func edgeName(identifier: ElectronicHorizon.Edge.Identifier) -> String? {
        guard let roadName = passiveLocationManager.dataSource.roadGraph.edgeMetadata(edgeIdentifier: identifier)?.names.first else {
            return nil
        }
        switch roadName {
        case .name(let name):
            return name
        case .code(let code):
            return "(\(code))"
        }
    }
}

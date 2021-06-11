import UIKit
import MapboxNavigation
import MapboxCoreNavigation
import MapboxMaps
import Turf

class ObservingElectronicHorizonEventsViewController: UIViewController {

    private lazy var navigationMapView = NavigationMapView(frame: view.bounds)

    private let upcomingIntersectionLabel = UILabel()
    private let passiveLocationManager = PassiveLocationManager(dataSource: PassiveLocationDataSource())

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationMapView()
        setupUpcomingIntersectionLabel()
        subscribeToElectronicHorizonUpdates()
    }

    func setupNavigationMapView() {
        navigationMapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        navigationMapView.mapView.location.overrideLocationProvider(with: passiveLocationManager)
        navigationMapView.userLocationStyle = .puck2D()
        navigationMapView.mapView.mapboxMap.onNext(.styleLoaded, handler: { [weak self] _ in
            self?.setupMostProbablePathStyle()
        })
        
        view.addSubview(navigationMapView)
    }

    private func setupUpcomingIntersectionLabel() {
        upcomingIntersectionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(upcomingIntersectionLabel)

        let safeAreaWidthAnchor = view.safeAreaLayoutGuide.widthAnchor
        NSLayoutConstraint.activate([
            upcomingIntersectionLabel.widthAnchor.constraint(lessThanOrEqualTo: safeAreaWidthAnchor, multiplier: 0.9),
            upcomingIntersectionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            upcomingIntersectionLabel.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor)
        ])
        upcomingIntersectionLabel.backgroundColor = #colorLiteral(red: 0.9568627477, green: 0.6588235497, blue: 0.5450980663, alpha: 1)
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
        let horizonTreeKey = RoadGraph.NotificationUserInfoKey.treeKey
        guard let horizonTree = notification.userInfo?[horizonTreeKey] as? RoadGraph.Edge else {
            return
        }

        let currentStreetName = streetName(for: horizonTree)
        let upcomingCrossStreet = nearestCrossStreetName(from: horizonTree)
        updateLabel(currentStreetName: currentStreetName, predictedCrossStreet: upcomingCrossStreet)

        // Drawing the most probable path
        let mostProbablePath = routeLine(from: horizonTree, roadGraph: passiveLocationManager.dataSource.roadGraph)
        updateMostProbablePath(with: mostProbablePath)
    }

    private func streetName(for edge: RoadGraph.Edge) -> String? {
        let edgeMetadata = passiveLocationManager.dataSource.roadGraph.edgeMetadata(edgeIdentifier: edge.identifier)
        return edgeMetadata?.names.first.map { roadName in
            switch roadName {
            case .name(let name):
                return name
            case .code(let code):
                return "\(code)"
            }
        }
    }

    private func nearestCrossStreetName(from edge: RoadGraph.Edge) -> String? {
        let initialStreetName = streetName(for: edge)
        var currentEdge: RoadGraph.Edge? = edge
        while let nextEdge = currentEdge?.outletEdges.max(by: { $0.probability < $1.probability }) {
            if let nextStreetName = streetName(for: nextEdge), nextStreetName != initialStreetName {
                return nextStreetName
            }
            currentEdge = nextEdge
        }
        return nil
    }

    private func updateLabel(currentStreetName: String?, predictedCrossStreet: String?) {
        var statusString = ""
        if let currentStreetName = currentStreetName {
            statusString = "Currently on:\n\(currentStreetName)"
            if let predictedCrossStreet = predictedCrossStreet {
                statusString += "\nUpcoming intersection with:\n\(predictedCrossStreet)"
            } else {
                statusString += "\nNo upcoming intersections"
            }
        }

        DispatchQueue.main.async {
            self.upcomingIntersectionLabel.text = statusString
            self.upcomingIntersectionLabel.sizeToFit()
        }
    }

    // MARK: - Drawing the most probable path
    private let sourceIdentifier = "mpp-source"
    private let layerIdentifier = "mpp-layer"

    private func routeLine(from edge: RoadGraph.Edge, roadGraph: RoadGraph) -> [LocationCoordinate2D] {
        var coordinates = [LocationCoordinate2D]()
        var edge: RoadGraph.Edge? = edge
        while let currentEdge = edge {
            if let shape = roadGraph.edgeShape(edgeIdentifier: currentEdge.identifier) {
                coordinates.append(contentsOf: shape.coordinates.dropFirst(coordinates.isEmpty ? 0 : 1))
            }
            edge = currentEdge.outletEdges.max(by: { $0.probability < $1.probability })
        }
        return coordinates
    }

    private func updateMostProbablePath(with mostProbablePath: [CLLocationCoordinate2D]) {
        let feature = Feature(geometry: .lineString(LineString(mostProbablePath)))
        try? navigationMapView.mapView.mapboxMap.style.updateGeoJSONSource(withId: sourceIdentifier, geoJSON: feature)
    }
    
    private func setupMostProbablePathStyle() {
        var source = GeoJSONSource()
        source.data = .geometry(Geometry.lineString(LineString([])))
        try? navigationMapView.mapView.mapboxMap.style.addSource(source, id: sourceIdentifier)
        
        var layer = LineLayer(id: layerIdentifier)
        layer.source = sourceIdentifier
        layer.lineWidth = .expression(
            Exp(.interpolate) {
                Exp(.linear)
                Exp(.zoom)
                RouteLineWidthByZoomLevel.mapValues { $0 * 0.5 }
            }
        )
        layer.lineColor = .constant(.init(color: UIColor.green.withAlphaComponent(0.9)))
        layer.lineCap = .constant(.round)
        layer.lineJoin = .constant(.miter)
        layer.minZoom = 9
        try? navigationMapView.mapView.mapboxMap.style.addLayer(layer)
    }
}

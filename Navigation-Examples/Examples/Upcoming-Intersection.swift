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
        navigationMapView.mapView.locationManager.overrideLocationProvider(with: passiveLocationManager)
        navigationMapView.mapView.update {
            $0.location.puckType = .puck2D()
        }
        navigationMapView.mapView.on(.styleLoaded) { _ in
            self.setupMostProbablePathStyle()
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
        let horizonTreeKey = ElectronicHorizon.NotificationUserInfoKey.treeKey
        guard let horizonTree = notification.userInfo?[horizonTreeKey] as? ElectronicHorizon else {
            return
        }

        let currentStreetName = streetName(for: horizonTree.start)
        let upcomingCrossStreet = nearestCrossStreetName(from: horizonTree.start)
        updateLabel(currentStreetName: currentStreetName, predictedCrossStreet: upcomingCrossStreet)

        // Drawing the most probable path
        let mostProbablePath = routeLine(from: horizonTree.start, roadGraph: passiveLocationManager.dataSource.roadGraph)
        updateMostProbablePath(with: mostProbablePath)
    }

    private func streetName(for edge: ElectronicHorizon.Edge) -> String? {
        let edgeMetadata = passiveLocationManager.dataSource.roadGraph.edgeMetadata(edgeIdentifier: edge.identifier)
        return edgeMetadata?.names.first.flatMap { roadName in
            switch roadName {
            case .name(let name):
                return name
            case .code(let code):
                return "\(code)"
            }
        }
    }

    private func nearestCrossStreetName(from edge: ElectronicHorizon.Edge) -> String? {
        let initialStreetName = streetName(for: edge)
        var currentEdge: ElectronicHorizon.Edge? = edge
        while let nextEdge = currentEdge?.outletEdges.max(by: { $0.probability < $1.probability }) {
            let nextStreetName = streetName(for: nextEdge)
            if nextStreetName != nil && nextStreetName != initialStreetName {
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

    private func routeLine(from edge: ElectronicHorizon.Edge, roadGraph: RoadGraph) -> [LocationCoordinate2D] {
        var coordinates = [LocationCoordinate2D]()
        var edge: ElectronicHorizon.Edge? = edge
        while let currentEdge = edge {
            if let shape = roadGraph.edgeShape(edgeIdentifier: currentEdge.identifier) {
                coordinates.append(contentsOf: shape.coordinates.dropFirst(coordinates.isEmpty ? 0 : 1))
            }
            edge = currentEdge.outletEdges.max(by: { $0.probability < $1.probability })
        }
        return coordinates
    }

    private func updateMostProbablePath(with mostProbablePath: [CLLocationCoordinate2D]) {
        let feature = Feature(geometry: .multiLineString(MultiLineString([mostProbablePath])))
        _ = navigationMapView.mapView.style.updateGeoJSON(for: sourceIdentifier, with: feature)
    }

    private func setupMostProbablePathStyle() {
        var source = GeoJSONSource()
        source.data = .geometry(Geometry.multiLineString(MultiLineString([[]])))
        _ = navigationMapView.mapView.style.addSource(source: source, identifier: sourceIdentifier)

        var layer = LineLayer(id: layerIdentifier)
        layer.source = sourceIdentifier
        layer.paint?.lineWidth = .expression(
            Exp(.interpolate) {
                Exp(.linear)
                Exp(.zoom)
                RouteLineWidthByZoomLevel.mapValues { $0 * 0.5 }
            }
        )
        layer.paint?.lineColor = .constant(.init(color: UIColor.green.withAlphaComponent(0.9)))
        layer.layout?.lineCap = .constant(.round)
        layer.layout?.lineJoin = .constant(.miter)
        layer.minZoom = 9
        _ = navigationMapView.mapView.style.addLayer(layer: layer)
    }
}

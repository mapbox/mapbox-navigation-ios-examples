/*
 This code example is part of the Mapbox Navigation SDK for iOS demo app,
 which you can build and run: https://github.com/mapbox/mapbox-navigation-ios-examples
 To learn more about each example in this app, including descriptions and links
 to documentation, see our docs: https://docs.mapbox.com/ios/navigation/examples
 */

import UIKit
import MapboxCoreNavigation
import MapboxNavigationNative
import MapboxMaps
import MapboxNavigation
import MapboxDirections

class OfflineRegionsViewController: UIViewController {
    // MARK: Setup variables for Tile Management
    let styleURI: StyleURI = .streets
    var region: Region?
    let zoomMin: UInt8 = 0
    let zoomMax: UInt8 = 16
    let offlineManager = OfflineManager(resourceOptions: .init(accessToken: NavigationSettings.shared.directions.credentials.accessToken ?? ""))
    let tileStoreConfiguration: TileStoreConfiguration = .default
    let tileStoreLocation: TileStoreConfiguration.Location = .default
    var tileStore: TileStore {
        tileStoreLocation.tileStore
    }
    
    var downloadButton = UIButton()
    var startButton = UIButton()
    var navigationMapView: NavigationMapView?
    var passiveLocationManager: PassiveLocationManager?
    var options: NavigationRouteOptions?
    
    var routeResponse: RouteResponse? {
        didSet {
            showRoutes()
            showStartNavigationAlert()
        }
    }
    
    var routeIndex: Int = 0 {
        didSet {
            showRoutes()
        }
    }
    
    struct Region {
        var bbox: [CLLocationCoordinate2D]
        var identifier: String
    }

    // MARK: Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationMapView()
        addDownloadButton()
        addStartButton()
    }
    
    func setupNavigationMapView() {
        navigationMapView = NavigationMapView(frame: view.bounds)
        navigationMapView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        navigationMapView?.userLocationStyle = .puck2D()
        navigationMapView?.delegate = self
        view.addSubview(navigationMapView!)
        
        setupGestureRecognizers()
        
        passiveLocationManager = PassiveLocationManager()
        let passiveLocationProvider = PassiveLocationProvider(locationManager: passiveLocationManager!)
        navigationMapView?.mapView.location.overrideLocationProvider(with: passiveLocationProvider)
        
        navigationMapView?.mapView.mapboxMap.onNext(event: .styleLoaded) { _ in
            self.createRegion()
        }
    }
    
    func addDownloadButton() {
        downloadButton.setTitle("Download Offline Region", for: .normal)
        downloadButton.backgroundColor = .blue
        downloadButton.layer.cornerRadius = 5
        downloadButton.translatesAutoresizingMaskIntoConstraints = false
        downloadButton.addTarget(self, action: #selector(tappedDownloadButton(sender:)), for: .touchUpInside)
        view.addSubview(downloadButton)
        
        downloadButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50).isActive = true
        downloadButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        downloadButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        downloadButton.sizeToFit()
        downloadButton.titleLabel?.font = UIFont.systemFont(ofSize: 25)
    }
    
    func addStartButton() {
        startButton.setTitle("Start Offline Navigation", for: .normal)
        startButton.backgroundColor = .blue
        startButton.layer.cornerRadius = 5
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.addTarget(self, action: #selector(tappedStartButton(sender:)), for: .touchUpInside)
        showStartButton(false)
        view.addSubview(startButton)
        
        startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50).isActive = true
        startButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        startButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        startButton.sizeToFit()
        startButton.titleLabel?.font = UIFont.systemFont(ofSize: 25)
    }
    
    func showStartButton(_ show: Bool = true) {
        startButton.isHidden = !show
        startButton.isEnabled = show
    }
    
    func setupGestureRecognizers() {
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        navigationMapView?.gestureRecognizers?.filter({ $0 is UILongPressGestureRecognizer }).forEach(longPressGestureRecognizer.require(toFail:))
        navigationMapView?.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        let gestureLocation = gesture.location(in: navigationMapView)
        guard gesture.state == .began,
              downloadButton.isHidden == true,
              let currentCoordinate = passiveLocationManager?.location?.coordinate,
              let destinationCoordinate = navigationMapView?.mapView.mapboxMap.coordinate(for: gestureLocation) else { return }
    
        options = NavigationRouteOptions(coordinates: [currentCoordinate, destinationCoordinate])
        requestRoute()
    }
    
    @objc func tappedDownloadButton(sender: UIButton) {
        downloadButton.isHidden = true
        downloadTileRegion()
    }

    @objc func tappedStartButton(sender: UIButton) {
        showStartButton(false)
        startNavigation()
    }
    
    // MARK: Offline navigation
    
    func showRoutes() {
        guard var routes = routeResponse?.routes, !routes.isEmpty else { return }
        routes.insert(routes.remove(at: routeIndex), at: 0)
        navigationMapView?.showsCongestionForAlternativeRoutes = true
        navigationMapView?.showsRestrictedAreasOnRoute = true
        navigationMapView?.showcase(routes)
        navigationMapView?.showRouteDurations(along: routes)
    }
    
    func showStartNavigationAlert() {
        let alertController = UIAlertController(title: "Start navigation",
                                                message: "Turn off network access to start active navigation",
                                                preferredStyle: .alert)
        let approveAction = UIAlertAction(title: "OK", style: .default, handler: {_ in self.showStartButton()})
        alertController.addAction(approveAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func requestRoute() {
        guard let options = options else { return }
        Directions.shared.calculate(options) { [weak self] (_, result) in
            switch result {
            case .failure(let error):
                print("Failed to request route with error: \(error.localizedDescription)")
            case .success(let response):
                guard let strongSelf = self else { return }
                strongSelf.routeResponse = response
            }
        }
    }
    
    func startNavigation() {
        guard let response = routeResponse else { return }
        let indexedRouteResponse = IndexedRouteResponse(routeResponse: response, routeIndex: routeIndex)
        let navigationService = MapboxNavigationService(indexedRouteResponse: indexedRouteResponse,
                                                        customRoutingProvider: NavigationSettings.shared.directions,
                                                        credentials: NavigationSettings.shared.directions.credentials,
                                                        simulating: .always)
        let navigationOptions = NavigationOptions(navigationService: navigationService)
        let navigationViewController = NavigationViewController(for: indexedRouteResponse,
                                                                navigationOptions: navigationOptions)
        navigationViewController.delegate = self
        navigationViewController.modalPresentationStyle = .fullScreen
        
        present(navigationViewController, animated: true) {
            self.navigationMapView = nil
            self.passiveLocationManager = nil
        }
    }
    
    // MARK: Create regions
    
    func createRegion() {
        guard let location = passiveLocationManager?.location?.coordinate else { return }
        if region == nil {
            // Generate a rectangle based on current user location
            let distance: CLLocationDistance = 1e4
            let directions: [CLLocationDegrees] = [45, 135, 225, 315, 45]
            let coordinates = directions.map { location.coordinate(at: distance, facing: $0) }
            region = Region(bbox: coordinates, identifier: "Current location")
        }
        addRegionBoxLine()
    }
    
    func addRegionBoxLine() {
        guard let style = navigationMapView?.mapView.mapboxMap.style,
              let coordinates = region?.bbox else { return }
        do {
            let identifier = "regionBox"
            var source = GeoJSONSource()
            source.data = .geometry(.lineString(.init(coordinates)))
            try style.addSource(source, id: identifier)
            
            var layer = LineLayer(id: identifier)
            layer.source = identifier
            layer.lineWidth = .constant(3.0)
            layer.lineColor = .constant(.init(.red))
            try style.addPersistentLayer(layer)
        } catch {
            print("Error \(error.localizedDescription) occured while adding box for region boundary.")
        }
    }
    
    // MARK: Download offline Regions
    
    func downloadTileRegion() {
        // Create style package
        guard let region = region,
              let stylePackLoadOptions = StylePackLoadOptions(glyphsRasterizationMode: .ideographsRasterizedLocally, metadata: nil) else { return }
        _ = offlineManager.loadStylePack(for: styleURI, loadOptions: stylePackLoadOptions, completion: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let stylePack):
                print("Style pack \(stylePack.styleURI) downloaded!")
                self.download(region: region)
            case .failure(let error):
                print("Error while downloading style pack: \(error).")
            }
        })
    }
    
    func download(region: Region) {
        tileRegionLoadOptions(for: region) { [weak self] loadOptions in
            guard let self = self, let loadOptions = loadOptions else { return }
            // loadTileRegions returns a Cancelable that allows developers to cancel downloading a region
            _ = self.tileStore.loadTileRegion(forId: region.identifier, loadOptions: loadOptions, progress: { progress in
                print(progress)
            }, completion: { result in
                switch result {
                case .success(let region):
                    print("\(region.id) downloaded!")
                    self.showDownloadCompletionAlert()
                case .failure(let error):
                    print("Error while downloading region: \(error)")
                }
            })
        }
    }
    
    // Helper method for creating TileRegionLoadOptions that are needed to download regions
    func tileRegionLoadOptions(for region: Region, completion: @escaping (TileRegionLoadOptions?) -> Void) {
        let tilesetDescriptorOptions = TilesetDescriptorOptions(styleURI: styleURI,
                                                                zoomRange: zoomMin...zoomMax)
        let mapsDescriptor = offlineManager.createTilesetDescriptor(for: tilesetDescriptorOptions)
        TilesetDescriptorFactory.getLatest { navigationDescriptor in
            completion(
                TileRegionLoadOptions(
                    geometry: Polygon([region.bbox]).geometry,
                    descriptors: [ mapsDescriptor, navigationDescriptor ],
                    metadata: nil,
                    acceptExpired: true,
                    networkRestriction: .none
                )
            )
        }
    }
    
    func showDownloadCompletionAlert() {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "Downloading completed",
                                                    message: "Long press location inside the box to get directions",
                                                    preferredStyle: .alert)
            let approveAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(approveAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
}

extension OfflineRegionsViewController: NavigationMapViewDelegate {
    func navigationMapView(_ navigationMapView: NavigationMapView, didSelect route: Route) {
        guard let index = routeResponse?.routes?.firstIndex(where: { $0 === route }),
              index != routeIndex else { return }
        routeIndex = index
    }
}

extension OfflineRegionsViewController: NavigationViewControllerDelegate {
    func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool) {
        navigationViewController.dismiss(animated: false) {
            self.setupNavigationMapView()
            self.addStartButton()
        }
    }
}

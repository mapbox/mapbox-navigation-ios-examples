import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections

class OfflineNavigationViewController: UIViewController {

    var navigationDirections: NavigationDirections!
    var mapView: NavigationMapView!
    var startButton: UIButton!
    
    lazy var faroeIslandsBounds: MGLCoordinateBounds = {
        let southWest = CLLocationCoordinate2DMake(61.9529495, -7.2900167)
        let northEast = CLLocationCoordinate2DMake(62.3424485, -6.7180647)
        
        return MGLCoordinateBounds(sw: southWest, ne: northEast)
    }()
    
    lazy var navigationCoordinateBounds: MGLCoordinateBounds = {
        let southWest = CLLocationCoordinate2DMake(61.9304, -7.0082)
        let northEast = CLLocationCoordinate2DMake(62.0552, -6.6046 )
        
        return MGLCoordinateBounds(sw: southWest, ne: northEast)
    }()
    
    var currentRoute: Route? {
        get {
            return routes?.first
        }
        set {
            guard let selected = newValue else { routes?.remove(at: 0); return }
            guard let routes = routes else { self.routes = [selected]; return }
            self.routes = [selected] + routes.filter { $0 != selected }
        }
    }
    var routes: [Route]? {
        didSet {
            guard let routes = routes, let current = routes.first else { mapView?.removeRoutes(); return }
            mapView?.showRoutes(routes)
            mapView?.showWaypoints(current)
        }
    }
    var hasDownloadedMapTiles = false {
        didSet {
            if hasDownloadedRoutingTiles {
                startNavigating()
            }
        }
    }
    var hasDownloadedRoutingTiles = false {
        didSet {
            if hasDownloadedMapTiles {
                startNavigating()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(offlinePackProgressDidChange), name: NSNotification.Name.MGLOfflinePackProgressChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(offlinePackDidReceiveError), name: NSNotification.Name.MGLOfflinePackError, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(offlinePackDidReceiveMaximumAllowedMapboxTiles), name: NSNotification.Name.MGLOfflinePackMaximumMapboxTilesReached, object: nil)
        
        mapView = NavigationMapView(frame: view.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.delegate = self
        
        mapView.setVisibleCoordinateBounds(faroeIslandsBounds, edgePadding: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10), animated: false, completionHandler: nil)
        
        view.addSubview(mapView)
        
        startButton = UIButton()
        startButton.setTitle("Start Navigation", for: .normal)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.backgroundColor = .blue
        startButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        startButton.addTarget(self, action: #selector(tappedButton(sender:)), for: .touchUpInside)
        startButton.isHidden = true
        
        view.addSubview(startButton!)
        
        startButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -20).isActive = true
        startButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        startButton.layoutIfNeeded()
        startButton.layer.cornerRadius = startButton.bounds.midY
        
        navigationDirections = NavigationDirections(accessToken: Directions.shared.accessToken, host: Directions.shared.apiEndpoint.host)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func downloadMapTilesIfNecessary() {
        if let packs = MGLOfflineStorage.shared.packs, packs.count > 0 {
            for pack in packs {
                pack.requestProgress()
            }
        } else {
            downloadMapTiles(inCoordinateBounds: navigationCoordinateBounds)
        }
    }
    
    private func downloadRoutingTilesIfNecessary() {
        guard let url = Bundle.mapboxCoreNavigation.suggestedTileURL else {
            print("Invalid Tile URL");
            return
        }
        
        if let routingTilesDirectories = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) {
            if let downloadedVersionURL = routingTilesDirectories.first {
                let version = downloadedVersionURL.lastPathComponent
                
                if let tilePathURL = Bundle.mapboxCoreNavigation.suggestedTileURL(version: version) {
                    navigationDirections.configureRouter(tilesURL: tilePathURL) { [weak self] _ in
                        self?.hasDownloadedRoutingTiles = true
                    }
                }
            }
        } else {
            let coordinateBounds = CoordinateBounds(coordinates: [self.navigationCoordinateBounds.sw, self.navigationCoordinateBounds.ne])
            downloadRoutingTiles(inCoordinateBounds: coordinateBounds) { [weak self] in
                self?.hasDownloadedRoutingTiles = true
            }
        }
    }
    
    private func downloadMapTiles(inCoordinateBounds coordinateBounds: MGLCoordinateBounds) {
        let offlineRegion = MGLTilePyramidOfflineRegion(styleURL: MGLStyle.navigationGuidanceDayStyleURL, bounds: coordinateBounds, fromZoomLevel: 14, toZoomLevel: 16)
        let context = NSKeyedArchiver.archivedData(withRootObject: [MGLOfflinePack.ContextNameKey: "Faroe Islands"])
        MGLOfflineStorage.shared.addPack(for: offlineRegion, withContext: context) { (pack, error) in
            if error != nil {
                print("Unable to add offline pack to the map’s storage: \(error!.localizedDescription)")
            } else {
                pack?.resume()
            }
        }
    }
    
    private func downloadRoutingTiles(inCoordinateBounds coordinateBounds: CoordinateBounds, completion: @escaping () -> Void) {
        print("Fetching versions…")
    
        navigationDirections.fetchAvailableOfflineVersions { [weak self] (versions, error) in
            guard let version = versions?.first else {
                print("No routing tile versions are available for download. Please try again later.")
                return
            }
            
            print("Downloading tiles…")
            
            self?.navigationDirections.downloadTiles(in: coordinateBounds, version: version) { (url, response, error) in
                guard let url = url else {
                    print("Unable to locate temporary file.")
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("No response from server.")
                    return
                }
                guard httpResponse.statusCode != 402 else {
                    print("Before you can fetch routing tiles you must obtain an enterprise access token.")
                    return
                }
                guard httpResponse.statusCode != 422 else {
                    print("The bounding box you have specified is too large. Please select a smaller box and try again.")
                    return
                }
                
                if let outputDirectoryURL = Bundle.mapboxCoreNavigation.suggestedTileURL(version: version) {
                    outputDirectoryURL.ensureDirectoryExists()
                    
                    NavigationDirections.unpackTilePack(at: url, outputDirectoryURL: outputDirectoryURL, progressHandler: { (totalBytes, bytesRemaining) in
                        let progress = Double(bytesRemaining) / Double(totalBytes)
                        let formattedProgress = NumberFormatter.localizedString(from: NSNumber(value: progress), number: .percent)
                        print("Unpacking… (\(formattedProgress))")
                    }, completionHandler: { [weak self] (result, error) in
                        self?.navigationDirections.configureRouter(tilesURL: outputDirectoryURL, completionHandler: { (numberOfTiles) in
                            print("Router configured with \(numberOfTiles) tile(s).")
                            
                            completion()
                        })
                    })
                }
            }.resume()
        }.resume()
    }
    
    private func navigateBetweenWaypoints(waypoints: [Waypoint]) {
        let routeOptions = NavigationRouteOptions(waypoints: waypoints)
    
        navigationDirections.calculate(routeOptions, offline: true) { [weak self] (waypoints, routes, error) in
            guard routes != nil else {
                print("No routes found.")
                return
            }
            
            self?.routes = routes
            self?.startButton.isHidden = false
        }
    }
    
    private func startNavigating() {
        let unionTerminal = Waypoint(coordinate: CLLocationCoordinate2DMake(62.009410, -6.760557), coordinateAccuracy: -1, name: "Hotel Streym")
        let airport = Waypoint(coordinate: CLLocationCoordinate2DMake(61.951824, -6.792390), coordinateAccuracy: -1, name: "Magnus Cathedral")
        navigateBetweenWaypoints(waypoints: [unionTerminal, airport])
    }
    
    private func updateStatus(forPack pack: MGLOfflinePack) {
        let progress = pack.progress
        var completedString = NumberFormatter.localizedString(from: NSNumber(value: progress.countOfResourcesCompleted), number: .decimal)
        var expectedString = NumberFormatter.localizedString(from: NSNumber(value: progress.countOfResourcesExpected), number: .decimal)
        let byteCountString = ByteCountFormatter.string(fromByteCount: Int64(progress.countOfBytesCompleted),
                                                        countStyle: ByteCountFormatter.CountStyle.file)
        
        var statusString = ""
        switch pack.state {
        case .unknown:
            statusString = "Calculating progress…"
        case .inactive:
            statusString = String(format: "%@ of %@ resources (%@)", completedString, expectedString, byteCountString)
            pack.resume()
        case .complete:
            statusString = String(format: "Offline pack “%@” completed: %@, %@ resources", pack.name, byteCountString, completedString)
            
            offlinePackDidComplete(pack)
        case .active:
            if progress.countOfResourcesExpected > 0 {
                completedString = NumberFormatter.localizedString(from: NSNumber(value: progress.countOfResourcesCompleted + 1), number: .decimal)
            }
            if progress.maximumResourcesExpected > progress.countOfResourcesExpected {
                expectedString = String(format: "at least %@", expectedString)
            }
            statusString = String(format: "Offline pack “%@” has %@ of %@ resources (%@ so far)…", pack.name, completedString, expectedString, byteCountString)
        case .invalid:
            assert(false, String(format: "Invalid offline pack"))
        @unknown default:
            statusString = "unsupported MGLOfflinePackState: \(pack.state.rawValue); please update Mapbox-iOS-SDK"
        }
        
        print(statusString)
    }
    
    private func offlinePackDidComplete(_ pack: MGLOfflinePack) {
        hasDownloadedMapTiles = true
    }
    
    @objc private func offlinePackProgressDidChange(notification: Notification) {
        if let pack = notification.object as? MGLOfflinePack {
            updateStatus(forPack: pack)
        }
    }
    
    @objc private func offlinePackDidReceiveError(notification: Notification) {
        if let pack = notification.object as? MGLOfflinePack, let error = notification.userInfo?[MGLOfflinePackUserInfoKey.error] as? NSError {
            print("Offline pack “\(pack.name)” received error: \(error.localizedFailureReason ?? "")")
        }
    }
    
    @objc private func offlinePackDidReceiveMaximumAllowedMapboxTiles(notification: NSNotification) {
        if let pack = notification.object as? MGLOfflinePack,
            let maximumCount = (notification.userInfo?[MGLOfflinePackUserInfoKey.maximumCount] as AnyObject).uint64Value {
            print("Offline pack “\(pack.name)” reached limit of \(maximumCount) tiles.")
        }
    }
    
    @objc func tappedButton(sender: UIButton) {
        guard let route = currentRoute else { return }
        // For demonstration purposes, simulate locations if the Simulate Navigation option is on.
        let navigationService = MapboxNavigationService(route: route, simulating: simulationIsEnabled ? .always : .onPoorGPS)
        let navigationOptions = NavigationOptions(navigationService: navigationService)
        let navigationViewController = NavigationViewController(for: route, options: navigationOptions)
//        navigationViewController.delegate = self
        
        present(navigationViewController, animated: true, completion: nil)
    }
}

extension OfflineNavigationViewController: MGLMapViewDelegate {
    func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
        downloadMapTilesIfNecessary()
        downloadRoutingTilesIfNecessary()
    }
}

extension MGLOfflinePack {
    static let ContextNameKey = "Name"
    
    var name: String {
        if let userInfo = NSKeyedUnarchiver.unarchiveObject(with: self.context) as? [String: String] {
            return userInfo[MGLOfflinePack.ContextNameKey] ?? "unknown"
        }
        
        return "unknown"
    }
}

extension URL {
    func ensureDirectoryExists() {
        try? FileManager.default.createDirectory(at: self, withIntermediateDirectories: true, attributes: nil)
    }
}

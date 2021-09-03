import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import MapboxMaps

class OfflineRegionsViewController: UITableViewController {

    var tileStore: TileStore!
    var resourceOptions: ResourceOptions!
    var tilesetDescriptor: TilesetDescriptor!
    
    // Transition button, progress view
    var stateButton: UIButton!
    var stylePackProgressView: UIProgressView!
    var tileRegionProgressView: UIProgressView!
    var downloadRegionsView: UIView!
    
    // Tile region and style pack
    var downloads: [Cancelable] = []
    
    // Create some hard-coded regions
    let tileZoom: CGFloat = 12
    let tileAreas: [ToBeTileRegion] = [
        ToBeTileRegion(coordinates: CLLocationCoordinate2D(latitude: 38.907, longitude: -77.036), identifier: "Washington DC Tile Region"),
        ToBeTileRegion(coordinates: CLLocationCoordinate2D(latitude: 38.997, longitude: -77.027), identifier: "Silver Spring Tile Region"),
        ToBeTileRegion(coordinates: CLLocationCoordinate2D(latitude: 38.805, longitude: -77.046), identifier: "Alexandria Tile Region")
    ]
    let washingtonDCCoord = CLLocationCoordinate2D(latitude: 38.907, longitude: -77.036)
    let dcRegionIdentifier = "Washington DC Tile Region"
    
    var offlineManager: OfflineManager!
    var mapInitOptions: MapInitOptions!
    
    struct ToBeTileRegion {
        var coordinates: CLLocationCoordinate2D
        var identifier: String
    }
    
    enum State {
        case beforeExampleSelected
        case initial
        case downloaded
        case finished
        case showingNavigationMapView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        initialSetup()
        state = .initial
    }
    
    func initialSetup() {
        resourceOptions = createCustomTileStore()
        offlineManager = OfflineManager(resourceOptions: resourceOptions)
        mapInitOptions = MapInitOptions(resourceOptions: resourceOptions, cameraOptions: CameraOptions(center: washingtonDCCoord, zoom: tileZoom), styleURI: .streets)
        
        downloadRegionsView = UIView(frame: self.view.bounds)
        downloadRegionsView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(downloadRegionsView)
        downloadRegionsView.backgroundColor = UIColor.white
        
        setupStateButton()
        setupProgressViews()
    }
    
    func setupStateButton() {
        stateButton = UIButton()
        stateButton.setTitle("Start Downloads", for: .normal)
        stateButton.translatesAutoresizingMaskIntoConstraints = false
        stateButton.backgroundColor = .blue
        stateButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        stateButton.isHidden = false
        stateButton.addTarget(self, action: #selector(didTapStateButton(_:)), for: .touchUpInside)
        view.addSubview(stateButton)
        
        stateButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -20).isActive = true
        stateButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        view.setNeedsLayout()
    }
    
    func setupProgressViews() {
        stylePackProgressView = UIProgressView(frame: CGRect(x: 10, y: 200, width: view.frame.size.width-20, height: 20))
        let stylePackProgressLabel = UILabel(frame: CGRect(x: 10, y: 150, width: view.frame.size.width-20, height: 20))
        stylePackProgressLabel.text = "Style Pack"
        view.addSubview(stylePackProgressView)
        view.addSubview(stylePackProgressLabel)
        stylePackProgressView.progress = 0.0
        
        tileRegionProgressView = UIProgressView(frame: CGRect(x: 10, y: 300, width: view.frame.size.width-20, height: 20))
        let tileRegionProgressLabel = UILabel(frame: CGRect(x: 10, y: 250, width: view.frame.size.width-20, height: 20))
        tileRegionProgressLabel.text = "Tile Region"
        view.addSubview(tileRegionProgressView)
        view.addSubview(tileRegionProgressLabel)
        tileRegionProgressView.progress = 0.0
    }
    
    func setupRefreshRegionsBarButtonItem() {
        let refreshRegionsBarButtonItem = UIBarButtonItem(title: NSString(string: "\u{1F5FA}") as String,
                                                    style: .plain,
                                                    target: self,
                                                    action: #selector(performAction(_:)))
        refreshRegionsBarButtonItem.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 30)], for: .normal)
        refreshRegionsBarButtonItem.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 30)], for: .highlighted)
        navigationItem.rightBarButtonItem = refreshRegionsBarButtonItem
    }
    
    @objc func performAction(_ sender: Any) {
        let alertController = UIAlertController(title: "Perform action",
                                                message: "Select specific action to perform it. \n Note: You cannot refresh DC Region after removing it.", preferredStyle: .actionSheet)
        
        typealias ActionHandler = (UIAlertAction) -> Void
        
        let listRegions: ActionHandler = { _ in self.listDownloadedRegions() }
        let refreshDCRegion: ActionHandler = { _ in self.updateRegions() }
        let removeDCRegion: ActionHandler = { _ in self.removeOfflineRegion()}
        
        let actions: [(String, UIAlertAction.Style, ActionHandler?)] = [
            ("List Regions", .default, listRegions),
            ("Refresh DC Region", .default, refreshDCRegion),
            ("Remove DC Region", .default, removeDCRegion),
            ("Cancel", .cancel, nil)
        ]
        
        actions
            .map({ payload in UIAlertAction(title: payload.0, style: payload.1, handler: payload.2) })
            .forEach(alertController.addAction(_:))
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.barButtonItem = navigationItem.rightBarButtonItem
        }
        
        present(alertController, animated: true, completion: nil)
    }
    
// MARK: Offline Regions
    func updateRegions() {
        // Updating a region is done by the same scenario as downloading a new one
        let tileRegionLoadOptions = TileRegionLoadOptions(
            geometry: MBXGeometry(coordinate: washingtonDCCoord), descriptors: [tilesetDescriptor])!

            tileStore.loadTileRegion(forId: dcRegionIdentifier, loadOptions: tileRegionLoadOptions, completion: { result in
                switch result {
                case .success(let region):
                    print("\(region.id) updated!")
                case .failure(let error):
                    print("Error while updating outdated regions: \(error).")
                }
            })
    }

    func createCustomTileStore() -> ResourceOptions {
        // get access token
        guard let accessToken = CredentialsManager.default.accessToken else {
            fatalError("Access token was not set.")
        }

        // Create a TileStore instance at the default location
        tileStore = TileStore.__getInstance()
        return ResourceOptions(accessToken: accessToken,
                                              tileStore: tileStore)
    }

    func downloadOfflineRegions() {
        // Create style package
        let stylePackLoadOptions = StylePackLoadOptions(glyphsRasterizationMode: .ideographsRasterizedLocally, metadata: nil)!
        
        let stylePackDownload = offlineManager.loadStylePack(for: .streets, loadOptions: stylePackLoadOptions) { [weak self] progress in
            // update UI
            DispatchQueue.main.async {
                guard let progress = progress,
                      let stylePackProgressView = self?.stylePackProgressView
                else {
                    return
                }
                // Update style pack progress bar
                stylePackProgressView.progress = Float(progress.completedResourceCount)/Float(progress.requiredResourceCount)
            }
        } completion: { result in
            // Confirm successful download
            switch result {
            case .success(let stylePack):
                print("Style pack \(stylePack.styleURI) downloaded!")
            case .failure(let error):
                print("Error while downloading style pack: \(error).")
            }
        }
        downloads = [stylePackDownload]
        
        // Create offline regions with tiles
        let navigationOptions = TilesetDescriptorOptions(styleURI: .streets, zoomRange: 0...10)
        tilesetDescriptor = offlineManager.createTilesetDescriptor(for: navigationOptions)
        
        // Load tile region
        tileAreas.forEach { region in
            let tileRegionLoadOptions = TileRegionLoadOptions(
                geometry: MBXGeometry(coordinate: region.coordinates),
                descriptors: [tilesetDescriptor],
                metadata: nil,
                averageBytesPerSecond: nil)!
                    
            let tileRegionDownload = tileStore.loadTileRegion(forId: region.identifier, loadOptions: tileRegionLoadOptions) { [weak self] progress in
                // Closure gets called from the TileStore thread, so we need to dispatch to the main queue to update the UI.
                DispatchQueue.main.async {
                    guard let progress = progress,
                          let tileRegionProgressView = self?.tileRegionProgressView
                    else {
                        return
                    }
                    // Update tile region progress bar
                    tileRegionProgressView.progress = Float(progress.completedResourceCount)/Float(progress.requiredResourceCount)
                }
            } completion: { result in
                // Confirm successful download.
                switch result {
                case .success(let region):
                    print("\(region.id) downloaded!")
                case .failure(let error):
                    print("Error while updating outdated regions: \(error).")
                }
            }
            downloads.append(tileRegionDownload)
        }
        self.state = .downloaded
    }
    
    func listOfflineRegions() -> [TileRegion] {
        var tiles: [TileRegion] = []
        
        tileStore.allTileRegions(completion: { result in
            do {
                tiles = try result.get()
            } catch {
                print("Error listing offline regions: \(error).")
            }
        })
        
        return tiles
    }

    func removeOfflineRegion() {
        tileStore.removeTileRegion(forId: dcRegionIdentifier)
        print("DC Region removed!")
    }
    
    func listDownloadedRegions() {
        tileStore.allTileRegions(completion: { result in
            do {
                let tiles = try result.get()
                tiles.forEach { tile in
                    print("Region: \(tile.id)")
                }
            } catch {
                print("Error listing offline regions: \(error).")
            }
        })
    }
    
    
// MARK: Handle State Changes
    var state: State = .beforeExampleSelected {
        didSet {
            switch(oldValue, state) {
            case(_, .initial):
             print("Example started!")
            case (.initial, .downloaded):
                enableShowNavigationMapView()
            case (.downloaded, .showingNavigationMapView):
                showNavigationMapView()
            case (.showingNavigationMapView, .finished):
                print("Example finished!")
            default:
                fatalError("Invalid transition from \(oldValue) to \(state).")
            }
        }
    }
    
    @objc func didTapStateButton(_ button: UIButton) {
        switch state {
        case .beforeExampleSelected:
            state = .initial
        case .initial:
            downloadOfflineRegions()
        case .downloaded:
            state = .showingNavigationMapView
        case .showingNavigationMapView:
            print("Select action")
        case .finished:
            state = .initial
        }
    }
}

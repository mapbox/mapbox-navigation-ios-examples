import UIKit
import MapboxCoreNavigation
import MapboxNavigationNative
import MapboxMaps

class OfflineRegionsViewController: UITableViewController {
    // MARK: Setup variables for Tile Management
    let styleURI: StyleURI = .streets
    let offlineManager = OfflineManager(resourceOptions: .init(accessToken: ""))
    var tileStoreConfiguration: TileStoreConfiguration {
        .default
    }
    var tileStoreLocation: TileStoreConfiguration.Location {
        .default
    }
    var tileStore: TileStore {
        tileStoreLocation.tileStore
    }
    
    struct Region {
        var coordinate: CLLocationCoordinate2D
        var identifier: String
    }
    
    // Create some hard-coded regions
    let regions: [Region] = [
        Region(coordinate: CLLocationCoordinate2D(latitude: 38.907, longitude: -77.036), identifier: "Washington DC"),
        Region(coordinate: CLLocationCoordinate2D(latitude: 40.697, longitude: -74.259), identifier: "New York"),
        Region(coordinate: CLLocationCoordinate2D(latitude: 37.757, longitude: -122.507), identifier: "San Francisco"),
        Region(coordinate: CLLocationCoordinate2D(latitude: 47.612, longitude: -122.482), identifier: "Seattle")
    ]

    // MARK: Setup TableView
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        displayDownloadPopup()
    }
    
    func displayDownloadPopup() {
        let alert = UIAlertController(title: "Download Regions?", message: "To proceed, you must download tile regions.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in self.downloadTileRegions() }))
        self.present(alert, animated: true, completion: nil)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Regions"
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.regions.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = self.regions[indexPath.row].identifier
        return cell
    }

    override func tableView(_ tableView: UITableView,
                            leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // Refresh action
        let action = UIContextualAction(style: .normal,
                                        title: "Refresh") { [weak self] (_, _, completionHandler) in
                                            self?.handleRefresh(for: indexPath.row)
                                            completionHandler(true)
        }
        action.backgroundColor = .systemGreen
        return UISwipeActionsConfiguration(actions: [action])
    }
    
    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // Delete action
        let action = UIContextualAction(style: .normal,
                                        title: "Delete") { [weak self] (_, _, completionHandler) in
                                            self?.handleDelete(for: indexPath.row)
                                            completionHandler(true)
        }
        action.backgroundColor = .systemRed
        return UISwipeActionsConfiguration(actions: [action])
    }
    
    // Swipe actions for refreshing and deleting regions
    func handleRefresh(for index: Int) {
        update(region: regions[index])
        print("Refreshed region.")
    }
    
    func handleDelete(for index: Int) {
        remove(region: regions[index])
        print("Deleted region.")
    }
    
    // MARK: Offline Regions
    func downloadTileRegions() {
        // Create style package
        guard let stylePackLoadOptions = StylePackLoadOptions(glyphsRasterizationMode: .ideographsRasterizedLocally, metadata: nil) else { return }
        _ = offlineManager.loadStylePack(for: .streets, loadOptions: stylePackLoadOptions, completion: { result in
            // Confirm successful download
            switch result {
            case .success(let stylePack):
                print("Style pack \(stylePack.styleURI) downloaded!")
            case .failure(let error):
                print("Error while downloading style pack: \(error).")
            }
        })

        // Load tile region
        regions.forEach { region in
            download(region: region)
        }
    }
    
    func download(region: Region) {
        tileRegionLoadOptions(for: region) { [weak self] loadOptions in
            guard let self = self, let loadOptions = loadOptions else { return }
            _ = self.tileStore.loadTileRegion(forId: region.identifier, loadOptions: loadOptions, completion: { result in
                switch result {
                case .success(let region):
                    print("\(region.id) downloaded!")
                case .failure(let error):
                    print("Error while downloading region: \(error).")
                }
            })
        }
    }
    
    func update(region: Region) {
        // Updating a region is done by the same scenario as downloading a new one
        download(region: region)
    }
    
    func remove(region: Region) {
        tileStore.removeTileRegion(forId: region.identifier)
    }
    
    func tileRegionLoadOptions(for region: Region, completion: @escaping (TileRegionLoadOptions?) -> Void) {
        let mapsDescriptor = offlineManager.createTilesetDescriptor(for: .init(
            styleURI: styleURI,
            zoomRange: UInt8(0)...UInt8(16)
        ))
        TilesetDescriptorFactory.getLatest { navigationDescriptor in
            completion(
                TileRegionLoadOptions(
                    geometry: .init(coordinate: region.coordinate),
                    descriptors: [ mapsDescriptor, navigationDescriptor ],
                    metadata: nil,
                    acceptExpired: true,
                    networkRestriction: .none
                )
            )
        }
    }
}

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

class OfflineRegionsViewController: UITableViewController {
    // MARK: Setup variables for Tile Management
    let styleURI: StyleURI = .streets
    let zoomMin: UInt8 = 0
    let zoomMax: UInt8 = 16
    let offlineManager = OfflineManager(resourceOptions: .init(accessToken: ""))
    let tileStoreConfiguration: TileStoreConfiguration = .default
    let tileStoreLocation: TileStoreConfiguration.Location = .default
    var tileStore: TileStore {
        tileStoreLocation.tileStore
    }
    
    struct Region {
        var bbox: [CLLocationCoordinate2D]
        var identifier: String
    }
    
    // Create some hard-coded regions
    let regions: [Region] = [
        Region(bbox: [CLLocationCoordinate2DMake(38.7727560655, -77.0424720699),
                      CLLocationCoordinate2DMake(38.8899646447, -77.1908975165),
                      CLLocationCoordinate2DMake(39.0083989651, -77.0365213968),
                      CLLocationCoordinate2DMake(38.8913858126, -76.8880959502),
                      CLLocationCoordinate2DMake(38.7727560655, -77.0424720699)], identifier: "Washington DC"),
        
        Region(bbox: [CLLocationCoordinate2DMake(40.6815166955, -73.9802146272),
                      CLLocationCoordinate2DMake(40.7032444267, -74.0405682483),
                      CLLocationCoordinate2DMake(40.8496846662, -73.9487500055),
                      CLLocationCoordinate2DMake(40.8280047669, -73.8883963845),
                      CLLocationCoordinate2DMake(40.6815166955, -73.9802146272)], identifier: "New York"),
        
        Region(bbox: [CLLocationCoordinate2DMake(37.7055506911, -122.5211407756),
                      CLLocationCoordinate2DMake(37.7055506911, -122.3500083596),
                      CLLocationCoordinate2DMake(37.8141659838, -122.3500083596),
                      CLLocationCoordinate2DMake(37.8141659838, -122.5211407756),
                      CLLocationCoordinate2DMake(37.7055506911, -122.5211407756)], identifier: "San Francisco"),
        
        Region(bbox: [CLLocationCoordinate2DMake(47.5097685046, -122.4384838738),
                      CLLocationCoordinate2DMake(47.5097685046, -122.2394838301),
                      CLLocationCoordinate2DMake(47.7405633331, -122.2394838301),
                      CLLocationCoordinate2DMake(47.7405633331, -122.4384838738),
                      CLLocationCoordinate2DMake(47.5097685046, -122.4384838738)], identifier: "Seattle")
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
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
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
        return regions.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = regions[indexPath.row].identifier
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
        print("Refreshed \(regions[index].identifier) region.")
    }
    
    func handleDelete(for index: Int) {
        remove(region: regions[index])
        print("Deleted \(regions[index].identifier) region.")
    }
    
    // MARK: Offline Regions
    func downloadTileRegions() {
        // Create style package
        guard let stylePackLoadOptions = StylePackLoadOptions(glyphsRasterizationMode: .ideographsRasterizedLocally, metadata: nil) else { return }
        _ = offlineManager.loadStylePack(for: styleURI, loadOptions: stylePackLoadOptions, completion: { result in
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
            // loadTileRegions returns a Cancelable that allows developers to cancel downloading a region
            _ = self.tileStore.loadTileRegion(forId: region.identifier, loadOptions: loadOptions, progress: { progress in
                print(progress)
            }, completion: { result in
                switch result {
                case .success(let region):
                    print("\(region.id) downloaded!")
                case .failure(let error):
                    print("Error while downloading region: \(error)")
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
    
    // Helper method for creating TileRegionLoadOptions that are needed to download regions
    func tileRegionLoadOptions(for region: Region, completion: @escaping (TileRegionLoadOptions?) -> Void) {
        let mapsDescriptor = offlineManager.createTilesetDescriptor(for: .init(
            styleURI: styleURI,
            zoomRange: zoomMin...zoomMax
        ))
        
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
}

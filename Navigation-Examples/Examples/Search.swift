import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import MapboxMaps
import MapboxSearch

class SearchViewController: UIViewController, NavigationMapViewDelegate, NavigationViewControllerDelegate, UISearchResultsUpdating, UITableViewDataSource {
    
    var navigationMapView: NavigationMapView!
    var navigationRouteOptions: NavigationRouteOptions!

    let searchEngine = SearchEngine()
    var searchController: UISearchController!
    var tableView: UITableView!

    var searchSuggestions: [SearchSuggestion] = []

    var isSearchBarEmpty: Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }

    // MARK: - UIViewController lifecycle methods

    override func viewDidLoad() {
        super.viewDidLoad()

        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = "Where to?"
        self.definesPresentationContext = true
        searchController.searchBar.sizeToFit()
        
        tableView = UITableView()
        tableView.dataSource = self
        tableView.tableHeaderView = searchController.searchBar
        view.addSubview(tableView)

        searchEngine.delegate = self

//        view.addSubview(navigationMapView)
//        view.setNeedsLayout()
    }

//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        searchController.searchBar.becomeFirstResponder()
//    }

    // Override layout lifecycle callback to be able to style the start button.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableCell", for: indexPath) as UITableViewCell
        cell.textLabel?.text = searchSuggestions[indexPath.row].name
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchSuggestions.count
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text {
            searchEngine.query = searchText
            tableView.reloadData()
            searchEngine.reverseGeocoding(options: <#T##ReverseGeocodingOptions#>, completion: <#T##(Result<[SearchResult], SearchError>) -> Void#>)
        }
    }

    // Send search results to Nav SDK
//    func handleSearchResultSelection(_ searchResult: SearchResult) {
//        let coordinate = searchResult.routablePoints?.first?.point ?? searchResult.coordinate
//        let destinationWaypoint = Waypoint(coordinate: coordinate, name: "\(searchResult.name)")
//        let navigationRouteOptions = NavigationRouteOptions(waypoints: [userWaypoint, destinationWaypoint])
//        Directions.calculateRoutes(navigationRouteOptions) { [weak self (session, result) in
//            switch result {
//            case .failure(let error):
//                print(error)
//            case .success(let response):
//                // Handle RouteResponse
//            }
//        }
//    }
}

extension SearchViewController: SearchEngineDelegate {
    func resultResolved(result: SearchResult, searchEngine: SearchEngine) {
        print("FIX ME!")
    }

    func searchErrorHappened(searchError: SearchError, searchEngine: SearchEngine) {
        print("Error during search: \(searchError)")
    }

    func suggestionsUpdated(suggestions: [SearchSuggestion], searchEngine: SearchEngine) {
        // Handle suggestions
        searchSuggestions = suggestions
        updateSearchResults(for: searchController)
    }
}

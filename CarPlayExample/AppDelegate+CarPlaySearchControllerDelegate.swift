import CarPlay
import MapboxNavigation
import MapboxDirections
import MapboxGeocoder

// MARK: - CarPlaySearchControllerDelegate methods

extension AppDelegate: CarPlaySearchControllerDelegate {
    
    func previewRoutes(to waypoint: Waypoint, completionHandler: @escaping () -> Void) {
        carPlayManager.previewRoutes(to: waypoint, completionHandler: completionHandler)
    }
    
    func resetPanButtons(_ mapTemplate: CPMapTemplate) {
        carPlayManager.resetPanButtons(mapTemplate)
    }
    
    func pushTemplate(_ template: CPTemplate, animated: Bool) {
        if let listTemplate = template as? CPListTemplate {
            listTemplate.delegate = carPlaySearchController
        }
        carPlayManager.interfaceController?.pushTemplate(template, animated: animated)
    }
    
    func popTemplate(animated: Bool) {
        carPlayManager.interfaceController?.popTemplate(animated: animated)
    }
    
    func recentSearches(with searchText: String) -> [CPListItem] {
        if searchText.isEmpty {
            return recentItems.map { $0.navigationGeocodedPlacemark.listItem() }
        }
        
        return recentItems.filter {
            $0.matches(searchText)
        }.map {
            $0.navigationGeocodedPlacemark.listItem()
        }
    }
    
    func searchResults(with items: [CPListItem], limit: UInt?) -> [CPListItem] {
        recentSearchItems = items
        
        if items.count > 0 {
            if let limit = limit {
                return Array<CPListItem>(items.prefix(Int(limit)))
            }
            
            return items
        } else {
            let noResultListItem = CPListItem(text: "No results",
                                              detailText: nil,
                                              image: nil,
                                              showsDisclosureIndicator: false)
            
            return [noResultListItem]
        }
    }
    
    func searchTemplate(_ searchTemplate: CPSearchTemplate,
                        updatedSearchText searchText: String,
                        completionHandler: @escaping ([CPListItem]) -> Void) {
        recentSearchText = searchText
        
        var items = recentSearches(with: searchText)
        let limit: UInt = 2
        
        if searchText.count > 2 {
            
            let forwardGeocodeOptions = ForwardGeocodeOptions(query: searchText)
            forwardGeocodeOptions.locale = Locale.autoupdatingCurrent.languageCode == "en" ? nil : .autoupdatingCurrent
            
            var allowedScopes: PlacemarkScope = .all
            allowedScopes.remove(.postalCode)
            
            forwardGeocodeOptions.allowedScopes = allowedScopes
            forwardGeocodeOptions.maximumResultCount = 10
            forwardGeocodeOptions.includesRoutableLocations = true
            
            Geocoder.shared.geocode(forwardGeocodeOptions,
                                    completionHandler: { [weak self] (placemarks, attribution, error) in
                                        guard let self = self else {
                                            completionHandler([])
                                            return
                                        }
                                        
                                        guard let placemarks = placemarks else {
                                            completionHandler(self.searchResults(with: items, limit: limit))
                                            return
                                        }
                                        
                                        let navigationGeocodedPlacemarks = placemarks.map {
                                            NavigationGeocodedPlacemark(title: $0.formattedName,
                                                                        subtitle: $0.address,
                                                                        location: $0.location,
                                                                        routableLocations: $0.routableLocations)
                                        }
                                        
                                        let results = navigationGeocodedPlacemarks.map { $0.listItem() }
                                        items.append(contentsOf: results)
                                        completionHandler(self.searchResults(with: results, limit: limit))
                                    })
        } else {
            completionHandler(self.searchResults(with: items, limit: limit))
        }
    }
    
    func searchTemplate(_ searchTemplate: CPSearchTemplate,
                        selectedResult item: CPListItem,
                        completionHandler: @escaping () -> Void) {
        guard let userInfo = item.userInfo as? [String: Any],
              let placemark = userInfo[CarPlaySearchController.CarPlayGeocodedPlacemarkKey] as? NavigationGeocodedPlacemark,
              let location = placemark.routableLocations?.first ?? placemark.location else {
            completionHandler()
            return
        }
        
        recentItems.add(RecentItem(placemark))
        recentItems.save()
        
        let destinationWaypoint = Waypoint(location: location,
                                           heading: nil,
                                           name: placemark.title)
        previewRoutes(to: destinationWaypoint, completionHandler: completionHandler)
    }
}

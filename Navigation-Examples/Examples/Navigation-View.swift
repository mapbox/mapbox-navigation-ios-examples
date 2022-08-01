import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections

class NavigationViewViewController: UIViewController {
    
    var navigationView: NavigationView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationView = NavigationView(frame: view.bounds)
        navigationView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let navigationViewportDataSource = NavigationViewportDataSource(navigationView.navigationMapView.mapView,
                                                                        viewportDataSourceType: .raw)
        navigationView.navigationMapView.navigationCamera.viewportDataSource = navigationViewportDataSource
        navigationView.navigationMapView.navigationCamera.follow()
        
        view.addSubview(navigationView)
        
        navigationView.bottomBannerContainerView.isHidden = false
        navigationView.bottomBannerContainerView.heightAnchor.constraint(equalToConstant: 150.0).isActive = true
        navigationView.bottomBannerContainerView.backgroundColor = .white
        // TODO: Make public.
//        navigationView.bottomBannerContainerView.isExpandable = true
//        navigationView.bottomBannerContainerView.expansionOffset = 50.0
        
        navigationView.topBannerContainerView.isHidden = false
        navigationView.topBannerContainerView.heightAnchor.constraint(equalToConstant: 50.0).isActive = true
        navigationView.topBannerContainerView.backgroundColor = .white
    }
}

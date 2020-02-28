import Foundation
import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections

class CustomBarsViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let origin = CLLocationCoordinate2DMake(37.77440680146262, -122.43539772352648)
        let destination = CLLocationCoordinate2DMake(37.76556957793795, -122.42409811526268)
        let options = NavigationRouteOptions(coordinates: [origin, destination])
        
        Directions.shared.calculate(options) { (waypoints, routes, error) in
            guard let route = routes?.first, error == nil else {
                print(error!.localizedDescription)
                return
            }
            
            // For demonstration purposes, simulate locations if the Simulate Navigation option is on.
            let navigationService = MapboxNavigationService(route: route, simulating: simulationIsEnabled ? .always : .onPoorGPS)
            
            // Pass your custom implementations of `topBanner` and/or `bottomBanner` to `NavigationOptions`
            // If you do not specify them explicitly, `TopBannerViewController` and `BottomBannerViewController` will be used by default.
            // Those are `Open`, so you can also check thier source for more examples of using standard UI controls!
            let bottomBanner = CustomBottomBarViewController()
            let navigationOptions = NavigationOptions(navigationService: navigationService,
                                                      topBanner: CustomTopBarViewController(),
                                                      bottomBanner:  bottomBanner
            )
            let navigationViewController = NavigationViewController(for: route, options: navigationOptions)
            
            bottomBanner.navigationViewController = navigationViewController
            navigationOptions.bottomBanner = bottomBanner
            
            navigationViewController.modalPresentationStyle = .fullScreen
            
            self.present(navigationViewController, animated: true, completion: nil)
        }
    }
}

class CustomTopBarViewController: ContainerViewController {
    let totallyLegitDesignerProvidedOffset: CGFloat = 42

    // You can Include one of the existing Views to display route-specific info
    lazy var instructionsBannerView: InstructionsBannerView = {
        let banner = InstructionsBannerView()
        banner.translatesAutoresizingMaskIntoConstraints = false
        banner.heightAnchor.constraint(equalToConstant: 100.0).isActive = true
        banner.layer.cornerRadius = 25
        banner.layer.opacity = 0.75
        return banner
    }()
    
    override func viewDidLoad() {
        view.addSubview(instructionsBannerView)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        instructionsBannerView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
        instructionsBannerView.topAnchor.constraint(equalTo: view.topAnchor, constant: totallyLegitDesignerProvidedOffset - view.safeAreaInsets.top).isActive = true
    }
    
    // MARK: - NavigationServiceDelegate implementation
    
    public func navigationService(_ service: NavigationService, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
        // pass updated data to sub-views which also implement `NavigationServiceDelegate`
        instructionsBannerView.updateDistance(for: progress.currentLegProgress.currentStepProgress)
    }
    
    public func navigationService(_ service: NavigationService, didPassVisualInstructionPoint instruction: VisualInstructionBanner, routeProgress: RouteProgress) {
        instructionsBannerView.update(for: instruction)
    }
    
    public func navigationService(_ service: NavigationService, didRerouteAlong route: Route, at location: CLLocation?, proactive: Bool) {
        instructionsBannerView.updateDistance(for: service.routeProgress.currentLegProgress.currentStepProgress)
    }
    
}

class CustomBottomBarViewController: ContainerViewController, CustomBottomBannerViewDelegate {
    
    weak var navigationViewController: NavigationViewController?
    
    // Or you can implement your own UI elements
    lazy var bannerView: CustomBottomBannerView = {
        let banner = CustomBottomBannerView()
        banner.translatesAutoresizingMaskIntoConstraints = false
        banner.delegate = self
        return banner
    }()
    
    override func viewDidLoad() {
        view.addSubview(bannerView)
        setupConstraints()
    }
    
    private func setupConstraints() {
        view.heightAnchor.constraint(equalToConstant: 80).isActive = true
        bannerView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        bannerView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        bannerView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: 0).isActive = true
        bannerView.heightAnchor.constraint(equalTo: view.heightAnchor, constant: 0).isActive = true
    }
    
    // MARK: - NavigationServiceDelegate implementation
    
    func navigationService(_ service: NavigationService, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
        // Update your controls manually
        bannerView.progress = Float(progress.fractionTraveled)
        bannerView.eta = "~\(Int(round(progress.durationRemaining / 60))) min"
    }
    
    // MARK: - CustomBottomBannerViewDelegate implementation
    
    func customBottomBannerDidCancel(_ banner: CustomBottomBannerView) {
        navigationViewController?.dismiss(animated: true,
                                          completion: nil)
    }
}

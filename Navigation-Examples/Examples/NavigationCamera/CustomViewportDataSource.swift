import MapboxMaps
import MapboxNavigation
import MapboxCoreNavigation

class CustomViewportDataSource: ViewportDataSource {
    
    public var delegate: ViewportDataSourceDelegate?
    
    public var followingMobileCamera: CameraOptions = CameraOptions()
    
    public var followingCarPlayCamera: CameraOptions = CameraOptions()

    public var overviewMobileCamera: CameraOptions = CameraOptions()
    
    public var overviewCarPlayCamera: CameraOptions = CameraOptions()
    
    weak var mapView: MapView?
    
    // MARK: - Initializer methods
    
    public required init(_ mapView: MapView) {
        self.mapView = mapView
        self.mapView?.location.addLocationConsumer(newConsumer: self)
        
        subscribeForNotifications()
    }
    
    deinit {
        unsubscribeFromNotifications()
    }
    
    // MARK: - Notifications observer methods
    
    func subscribeForNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(progressDidChange(_:)),
                                               name: .routeControllerProgressDidChange,
                                               object: nil)
    }
    
    func unsubscribeFromNotifications() {
        NotificationCenter.default.removeObserver(self,
                                                  name: .routeControllerProgressDidChange,
                                                  object: nil)
    }
    
    @objc func progressDidChange(_ notification: NSNotification) {
        let location = notification.userInfo?[RouteController.NotificationUserInfoKey.locationKey] as? CLLocation
        let routeProgress = notification.userInfo?[RouteController.NotificationUserInfoKey.routeProgressKey] as? RouteProgress
        let cameraOptions = self.cameraOptions(location, routeProgress: routeProgress)
        
        delegate?.viewportDataSource(self, didUpdate: cameraOptions)
    }
    
    func cameraOptions(_ location: CLLocation?, routeProgress: RouteProgress? = nil) -> [String: CameraOptions] {
        followingMobileCamera.center = location?.coordinate
        followingMobileCamera.bearing = location?.course
        followingMobileCamera.padding = .zero
        followingMobileCamera.zoom = 15.0
        followingMobileCamera.pitch = 45.0
        
        if let shape = routeProgress?.route.shape,
           let camera = mapView?.camera.camera(fitting: .lineString(shape)) {
            overviewMobileCamera = camera
            overviewMobileCamera.padding = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            overviewMobileCamera.center = location?.coordinate
        }
        
        let cameraOptions = [
            CameraOptions.followingMobileCamera: followingMobileCamera,
            CameraOptions.overviewMobileCamera: overviewMobileCamera
        ]
        
        return cameraOptions
    }
}

// MARK: - LocationConsumer delegate

extension CustomViewportDataSource: LocationConsumer {
    
    var shouldTrackLocation: Bool {
        get {
            return true
        }
        set(newValue) {
            // No-op
        }
    }

    func locationUpdate(newLocation: Location) {
        let cameraOptions = self.cameraOptions(newLocation.internalLocation)
        delegate?.viewportDataSource(self, didUpdate: cameraOptions)
    }
}

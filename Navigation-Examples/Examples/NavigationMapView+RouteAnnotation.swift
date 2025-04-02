import MapboxCoreNavigation
import MapboxDirections
import MapboxMaps
import MapboxNavigation
import Turf

final class CustomRouteAnnotationManager {
    let navigationMapView: NavigationMapView
    var viewAnnotations: [ETAView]?

    init(navigationMapView: NavigationMapView) {
        self.navigationMapView = navigationMapView
    }

    var viewAnnotationManager: ViewAnnotationManager? {
        navigationMapView.mapView.viewAnnotations
    }

    func showRouteAnnotation(mainRoute: Route, alternatives: [AlternativeRoute]) {
        removeRouteAnnotation()

        let annotations = makeRouteAnnotation(mainRoute: mainRoute, alternatives: alternatives)
        for (view, annotationOptions) in annotations {
            try? viewAnnotationManager?.add(view, options: annotationOptions)
        }
        viewAnnotations = annotations.map(\.0)
    }

    func removeRouteAnnotation() {
        viewAnnotations?.forEach {
            viewAnnotationManager?.remove($0)
        }
        viewAnnotations = nil
    }

    private func makeRouteAnnotation(
        mainRoute: Route,
        alternatives: [AlternativeRoute]
    ) -> [(ETAView, ViewAnnotationOptions)] {
        var annotations = alternatives.compactMap { alternativeRoute -> (ETAView, ViewAnnotationOptions)? in
            guard let routeShape = alternativeRoute.indexedRouteResponse.currentRoute?.shape,
                  let annotationCoordinate = routeShape.trimmed(from: alternativeRoute.alternativeRouteIntersection.location,
                                                                distance: 100)?.coordinates.last
            else {
                return nil
            }
            let view = ETAView(etaDiff: alternativeRoute.expectedTravelTimeDelta)
            let size = view.intrinsicContentSize
            let viewAnnotationOptions = ViewAnnotationOptions(
                geometry: Point(annotationCoordinate),
                width: size.width,
                height: size.height,
                allowOverlap: true,
                anchor: .top
            )
            return (view, viewAnnotationOptions)
        }

        // Calculate the position for the main route line annotation
        if let shape = mainRoute.shape,
           let annotationShape = shape.trimmed(from: mainRoute.distance / 2, to: mainRoute.distance / 2 + 1),
           let annotationCoordinate = annotationShape.coordinates.first {
            let mainRouteAnnotationView = ETAView(eta: mainRoute.expectedTravelTime)
            let size = mainRouteAnnotationView.intrinsicContentSize
            let viewAnnotationOptions = ViewAnnotationOptions(
                geometry: Point(annotationCoordinate),
                width: size.width,
                height: size.height,
                allowOverlap: false,
                anchor: .center
            )
            annotations.append((mainRouteAnnotationView, viewAnnotationOptions))
        }

        return annotations
    }
}

final class ETAView: UIView {
    private let label: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = .white
        label.numberOfLines = 1
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }()

    convenience init(etaDiff: TimeInterval) {
        let timeString = Self.formattedTimeDiff(etaDiff)
        self.init(etaText: timeString)
    }

    convenience init(eta: TimeInterval) {
        let timeString = Self.formatter.string(from: eta) ?? ""
        self.init(etaText: timeString)
    }

    init(etaText: String) {
        super.init(frame: .zero)
        label.text = etaText
        setupView()
    }

    static func formattedTimeDiff(_ timeInterval: TimeInterval) -> String {
        if abs(timeInterval) < 60 {
            return "similar ETA"
        }
        guard let formattedTime = formatter.string(from: timeInterval) else {
            return ""
        }

        return timeInterval > 0 ? "+\(formattedTime)" : formattedTime
    }

    static var formatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .short
        return formatter
    }()

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor.black.withAlphaComponent(0.7)
        layer.cornerRadius = Self.padding
        layer.masksToBounds = true

        addSubview(label)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .vertical)

        let padding = Self.padding
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding)
        ])

        invalidateIntrinsicContentSize()
        sizeToFit()
    }

    override var intrinsicContentSize: CGSize {
        let labelSize = label.intrinsicContentSize
        return CGSize(width: labelSize.width + Self.padding * 2, height: labelSize.height + Self.padding * 2)
    }

    private static let padding: CGFloat = 8
}

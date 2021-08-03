import Foundation
import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxMaps
import Turf

class FlagsViewController: UIViewController, NavigationMapViewDelegate {
    var navigationMapView: NavigationMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationMapView = NavigationMapView(frame: view.bounds)
        
        navigationMapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        navigationMapView.delegate = self
        navigationMapView.userLocationStyle = .puck2D()
        view = navigationMapView
        
        navigationMapView.mapView.mapboxMap.onNext(.styleLoaded, handler: { [weak self] _ in
            guard let self = self else { return }
            
            let style = self.navigationMapView.mapView.mapboxMap.style
            
            var demSource = RasterDemSource()
            demSource.url = "mapbox://mapbox.mapbox-terrain-dem-v1"
            demSource.tileSize = 512
            demSource.maxzoom = 14.0
            
            try! style.addSource(demSource, id: "mapbox-dem")
            
            let terrain = Terrain(sourceId: "mapbox-dem")
            try! style.setTerrain(terrain)
            
            var skyLayer = SkyLayer(id: "sky-layer")
            skyLayer.skyType = .constant(.atmosphere)
            skyLayer.skyAtmosphereSun = .constant([0, 0])
            skyLayer.skyAtmosphereSunIntensity = .constant(15.0)
            
            try! style.addLayer(skyLayer)
            
            // Re-use terrain source for hillshade
            let properties = [
                "id": "terrain_hillshade",
                "type": "hillshade",
                "source": "mapbox-dem",
                "hillshade-illumination-anchor": "map"
            ] as [ String: Any ]
            
            try! style.addLayer(with: properties, layerPosition: .below("water"))
            
            var layer = FillExtrusionLayer(id: "3d-buildings")
            
            layer.source                      = "composite"
            layer.minZoom                     = 15
            layer.sourceLayer                 = "building"
            layer.fillExtrusionColor   = .constant(ColorRepresentable(color: .lightGray))
            layer.fillExtrusionOpacity = .constant(0.6)
            
            layer.filter = Exp(.eq) {
                Exp(.get) {
                    "extrude"
                }
                "true"
            }
            
            layer.fillExtrusionHeight = .expression(
                Exp(.interpolate) {
                    Exp(.linear)
                    Exp(.zoom)
                    15
                    0
                    15.05
                    Exp(.get) {
                        "height"
                    }
                }
            )
            
            layer.fillExtrusionBase = .expression(
                Exp(.interpolate) {
                    Exp(.linear)
                    Exp(.zoom)
                    15
                    0
                    15.05
                    Exp(.get) { "min_height"}
                }
            )
            
            try! style.addLayer(layer)
            
            
            
            let data = try! Data(contentsOf: Bundle.main.url(forResource: "flagpoles", withExtension: "geojson")!)
            let flagpoles = try! JSONDecoder().decode(FeatureCollection.self, from: data)
            var source = GeoJSONSource()
            source.data = .featureCollection(flagpoles)
            try! style.addSource(source, id: "flagpoles")
            
            let flagIdentifiers = flagpoles.features
                .compactMap { $0.properties?["flag:wikidata"] as? String }
                .flatMap { $0.split(separator: ";") }
            for flagIdentifier in Set(flagIdentifiers) {
                guard let image = UIImage(named: "flags/\(flagIdentifier)") else { continue }
                try? style.addImage(image, id: String(flagIdentifier))
            }
            
            var symbolLayer = SymbolLayer(id: "flags")
            symbolLayer.source = "flagpoles"
            symbolLayer.iconImage = .expression(Exp(.get) { "flag:wikidata" })
            symbolLayer.iconSize = .constant(0.1)
            symbolLayer.iconAllowOverlap = .constant(true)
            try! style.addLayer(symbolLayer)
        })
    }
}

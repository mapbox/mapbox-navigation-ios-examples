import MapboxNavigation
import MapboxMaps

class CustomStyle: NightStyle {
    
    required init() {
        super.init()
        
        mapStyleURL = URL(string: StyleURI.dark.rawValue)!
    }
    
    override func apply() {
        super.apply()
    }
}

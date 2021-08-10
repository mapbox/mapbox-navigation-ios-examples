import CarPlay

// MARK: - CPTemplateApplicationSceneDelegate methods

extension AppDelegate: CPTemplateApplicationSceneDelegate {
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didConnect interfaceController: CPInterfaceController,
                                  to window: CPWindow) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        appDelegate.carPlayManager.delegate = appDelegate
        
        appDelegate.carPlayManager.application(UIApplication.shared,
                                               didConnectCarInterfaceController: interfaceController,
                                               to: window)
        
        appDelegate.carPlayManager.templateApplicationScene(templateApplicationScene,
                                                            didConnectCarInterfaceController: interfaceController,
                                                            to: window)
    }
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didDisconnect interfaceController: CPInterfaceController,
                                  from window: CPWindow) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        appDelegate.carPlayManager.delegate = nil
        
        appDelegate.carPlayManager.application(UIApplication.shared,
                                               didDisconnectCarInterfaceController: interfaceController,
                                               from: window)
        
        appDelegate.carPlayManager.templateApplicationScene(templateApplicationScene,
                                                            didDisconnectCarInterfaceController: interfaceController,
                                                            from: window)
    }
}

import Foundation
import UIKit

var simulationIsEnabled = true

class ExampleContainerViewController: UITableViewController {
    
    @IBOutlet weak var beginNavigation: UIButton!
    @IBOutlet weak var simulateNavigation: UISwitch!
    
    var exampleClass: UIViewController.Type?
    var exampleName: String?
    var exampleDescription: String?
    var hasEnteredExample = false
    var pushExampleToViewController = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = exampleName
        
        if exampleClass == nil {
            beginNavigation.setTitle("Example Not Found", for: .normal)
            beginNavigation.isEnabled = false
            simulateNavigation.isEnabled = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if hasEnteredExample {
            if let last = view.subviews.last {
                last.removeFromSuperview()
                hasEnteredExample = false
            }
        }
    }
    
    @IBAction func didTapBeginNavigation(_ sender: Any) {
        if let exampleClass = exampleClass {
            let viewController = exampleClass.init()
            self.addChildViewController(viewController)
            self.view.addSubview(viewController.view)
            viewController.didMove(toParentViewController: self)
            if pushExampleToViewController {
                self.navigationController?.pushViewController(viewController, animated: true)
            }
            hasEnteredExample = true
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard let exampleDescription = exampleDescription else { return nil }
        return section == tableView.numberOfSections - 1  ? exampleDescription : nil
    }
    
    @IBAction func didToggleSimulateNavigation(_ sender: Any) {
        simulationIsEnabled = simulateNavigation.isOn
    }
}

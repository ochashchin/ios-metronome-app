import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var on_off: UIView!
    @IBOutlet weak var power_on: UIView!
    @IBOutlet weak var switch_press: UIView!
    @IBOutlet weak var switch_slider: UIView!
    
    @IBOutlet weak var customLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var customRightConstraint: NSLayoutConstraint!
   
    var switchTap: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        on_off = R.findViewById(controller: self, id: R.on_off)
        on_off.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(powerTap(sender:))))
        
        power_on = R.findViewById(controller: self, id: R.power_on)
        
        switch_press = R.findViewById(controller: self, id: R.switch_press)
        switch_press.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(switchTap(sender:))))
        
        switch_slider = R.findViewById(controller: self, id: R.switch_slider)
        
        
    }
    
    @objc func powerTap(sender: UITapGestureRecognizer) {
        print("tap")
        
        UIView.animate(withDuration: 0.2, delay: 0, options: UIView.AnimationOptions.transitionCrossDissolve, animations: {
            if(self.power_on.alpha == 0){
                self.power_on.alpha = 1
            } else {
                self.power_on.alpha = 0
            }
        })
    }
    
    @objc func switchTap(sender: UITapGestureRecognizer) {
        print("switchTap")
        
        switchTap = !switchTap
                
        if(self.customLeftConstraint == nil){
            self.customLeftConstraint = self.switch_slider.leftAnchor.constraint(equalTo: self.switch_press.leftAnchor)
        }
        
        if(self.customRightConstraint == nil){
            self.customRightConstraint = self.switch_slider.rightAnchor.constraint(equalTo: self.switch_press.rightAnchor)
        }
        
        UIView.animate(withDuration: 0.2, delay: 0.0, options: [], animations: {
            
            if(self.switchTap){
                self.customLeftConstraint.isActive = false
                self.customRightConstraint.isActive = true
            } else {
                self.customLeftConstraint.isActive = true
                self.customRightConstraint.isActive = false
            }
            
            self.view.layoutIfNeeded()
        })
        
    }
    
}


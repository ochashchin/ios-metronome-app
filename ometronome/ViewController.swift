import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var on_off: UIView!
    @IBOutlet weak var power_on: UIView!
    @IBOutlet weak var switch_press: UIView!
    @IBOutlet weak var switch_slider: UIView!
    
    @IBOutlet weak var customLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var customRightConstraint: NSLayoutConstraint!
    @IBOutlet weak var customTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var customBottomConstraint: NSLayoutConstraint!
    
    var switchTap: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        on_off = R.findViewById(controller: self, id: R.on_off)
        on_off.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onOffTap(sender:))))
        
        power_on = R.findViewById(controller: self, id: R.power_on)
        
        switch_press = R.findViewById(controller: self, id: R.switch_press)
        switch_press.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(switchTap(sender:))))
        
        switch_slider = R.findViewById(controller: self, id: R.switch_slider)
        
        self.customTopConstraint = self.switch_slider.topAnchor.constraint(equalTo: self.switch_press.topAnchor)
        
        self.customBottomConstraint = self.switch_slider.bottomAnchor.constraint(equalTo: self.switch_press.bottomAnchor)
        
        self.customLeftConstraint = self.switch_slider.leftAnchor.constraint(equalTo: self.switch_press.leftAnchor)
        
        self.customRightConstraint = self.switch_slider.rightAnchor.constraint(equalTo: self.switch_press.rightAnchor)
    }
    
    @objc func onOffTap(sender: UITapGestureRecognizer) {
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
        
        self.switchTap != self.switchTap
        
        var customConstraint: [NSLayoutConstraint] = self.switch_slider.constraints

        UIView.animate(withDuration: 3.0, delay: 0.0, options: [], animations: {
        
            self.switch_slider.removeConstraints(self.switch_slider.constraints)

            self.customTopConstraint.isActive = true
            self.customBottomConstraint.isActive = true
            
            if(self.switchTap){
                self.customRightConstraint.isActive = true
            } else {
                self.customLeftConstraint.isActive = true
            }
            
            self.view.layoutIfNeeded()
        })
        
    }
    
}


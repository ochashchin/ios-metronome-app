import Foundation
import UIKit

class R {
    
    static let
    on_off = 100,
    power_on = 101,
    power_off = 102,
    cursor_on = 201,
    cursor_off = 202,
    switch_press = 300,
    switch_slider = 301,
    switch_on = 302,
    switch_off = 303,
    switch_on_flash = 304,
    switch_off_flash = 305,
    switch_on_sound = 306,
    switch_off_sound = 307,
    bpm = 308
    
    static func findViewById(controller: UIViewController, id: Int) -> UIView {
        let c = controller.view.window
        let v = c?.viewWithTag(id)
        return v!
    }
    
}

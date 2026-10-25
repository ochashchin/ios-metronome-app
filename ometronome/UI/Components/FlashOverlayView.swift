//
//  FlashOverlayView.swift
//  ometronome
//

import UIKit

public final class FlashOverlayView: UIView {
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        backgroundColor = .white
        alpha = 0.0
        isHidden = true
        isUserInteractionEnabled = false
    }
    
    public func setPlaying(_ isPlaying: Bool, mode: Mode) {
        if !isPlaying || mode != .flash {
            reset()
        }
    }
    
    public func blink() {
        let action = { [weak self] in
            guard let self = self else { return }
            self.isHidden = false
            self.layer.removeAllAnimations()
            self.alpha = 0.8
            UIView.animate(withDuration: 0.08, delay: 0, options: [.curveLinear], animations: {
                self.alpha = 0.0
            }) { _ in
                self.isHidden = true
            }
        }
        
        if Thread.isMainThread {
            action()
        } else {
            DispatchQueue.main.async(execute: action)
        }
    }
    
    public func reset() {
        let action = { [weak self] in
            guard let self = self else { return }
            self.layer.removeAllAnimations()
            self.alpha = 0.0
            self.isHidden = true
        }
        
        if Thread.isMainThread {
            action()
        } else {
            DispatchQueue.main.async(execute: action)
        }
    }
}

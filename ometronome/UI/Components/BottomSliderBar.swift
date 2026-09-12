//
//  BottomSliderBar.swift
//  ometronome
//

import UIKit

@IBDesignable
public class BottomSliderBar: UIView {
    
    // Callback
    public var onModeSelected: ((Mode) -> Void)?
    
    // State
    public private(set) var activeMode: Mode = .sound
    public private(set) var isPlaying: Bool = false
    
    // UI Elements
    private let trackImageView = UIImageView()
    private let iconsImageView = UIImageView()
    private let knobView = UIView()
    private let knobOn = UIImageView()
    private let knobOff = UIImageView()
    
    // Mode Icon Overlays inside the knob
    private let soundOn = UIImageView()
    private let soundOff = UIImageView()
    private let flashOn = UIImageView()
    private let flashOff = UIImageView()
    private let pulseOn = UIImageView()
    private let pulseOff = UIImageView()
    
    private var isDragging = false
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        // Clear any static preview placeholder subviews from storyboard
        subviews.forEach { $0.removeFromSuperview() }
        setupViews()
    }
    
    public override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        subviews.forEach { $0.removeFromSuperview() }
        setupViews()
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    private func setupViews() {
        backgroundColor = .clear
        clipsToBounds = false
        
        // 1. Track Background
        trackImageView.image = imageNamed("bottom_slider")
        trackImageView.contentMode = .scaleAspectFit
        addSubview(trackImageView)
        
        // 2. Icons Layer
        iconsImageView.image = imageNamed("bottom_slider_icons")
        iconsImageView.contentMode = .scaleAspectFit
        addSubview(iconsImageView)
        
        // 3. Knob
        knobView.clipsToBounds = false
        addSubview(knobView)
        
        // Base layer (on): always visible underneath with shadow effect
        knobOn.image = imageNamed("slider_button_on")
        knobOn.contentMode = .scaleAspectFit
        knobOn.alpha = 1.0
        knobView.addSubview(knobOn)
        
        // Top layer (off): transitions alpha
        knobOff.image = imageNamed("slider_button_off")
        knobOff.contentMode = .scaleAspectFit
        knobOff.alpha = 1.0
        knobView.addSubview(knobOff)
        
        // 4. Mode Overlays inside knob (on layers under off layers)
        soundOn.image = imageNamed("sound_on")
        flashOn.image = imageNamed("flash_on")
        pulseOn.image = imageNamed("pulse_on")
        soundOff.image = imageNamed("sound_off")
        flashOff.image = imageNamed("flash_off")
        pulseOff.image = imageNamed("pulse_off")
        
        let allOverlays = [soundOn, flashOn, pulseOn, soundOff, flashOff, pulseOff]
        for overlay in allOverlays {
            overlay.contentMode = .scaleAspectFit
            knobView.addSubview(overlay)
        }
        
        // Gestures
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
        
        updateKnobAppearance()
    }
    
    private func imageNamed(_ name: String) -> UIImage? {
        return UIImage(named: name, in: Bundle(for: type(of: self)), compatibleWith: nil) ?? UIImage(named: name)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        trackImageView.frame = bounds
        
        // Icons aspect ratio is 387:158 centered
        let iconsW = bounds.height * (387.0 / 158.0)
        let iconsX = (bounds.width - iconsW) / 2
        iconsImageView.frame = CGRect(x: iconsX, y: 0, width: iconsW, height: bounds.height)
        
        let knobSize = bounds.height * 1.00
        knobView.bounds = CGRect(x: 0, y: 0, width: knobSize, height: knobSize)
        knobOn.frame = knobView.bounds
        knobOff.frame = knobView.bounds
        
        for sub in [soundOn, flashOn, pulseOn, soundOff, flashOff, pulseOff] {
            sub.frame = knobView.bounds
        }
        
        if !isDragging {
            knobView.center = targetCenter(for: activeMode)
        }
    }
    
    private func targetCenter(for mode: Mode) -> CGPoint {
        let iconsW = bounds.height * (387.0 / 158.0)
        let iconsX = (bounds.width - iconsW) / 2
        let y = bounds.height / 2
        switch mode {
        case .sound:
            return CGPoint(x: iconsX + bounds.height * 0.5, y: y)
        case .flash:
            return CGPoint(x: bounds.width / 2, y: y)
        case .pulse:
            return CGPoint(x: iconsX + iconsW - bounds.height * 0.5, y: y)
        }
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard isPlaying else { return }
        
        let loc = gesture.location(in: self)
        let w = bounds.width
        let newMode: Mode
        if loc.x < w * 0.35 {
            newMode = .sound
        } else if loc.x > w * 0.65 {
            newMode = .pulse
        } else {
            newMode = .flash
        }
        
        if newMode != activeMode {
            setMode(newMode, animated: true)
        }
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard isPlaying else { return }
        
        let loc = gesture.location(in: self)
        let iconsW = bounds.height * (387.0 / 158.0)
        let iconsX = (bounds.width - iconsW) / 2
        let minX = iconsX + bounds.height * 0.5
        let maxX = iconsX + iconsW - bounds.height * 0.5
        
        switch gesture.state {
        case .began:
            isDragging = true
        case .changed:
            let clampedX = Swift.max(minX, Swift.min(maxX, loc.x))
            knobView.center = CGPoint(x: clampedX, y: bounds.height / 2)
            
            // Check crossed regions dynamically
            let currentX = knobView.center.x
            let w = bounds.width
            let detectedMode: Mode
            if currentX < w * 0.38 {
                detectedMode = .sound
            } else if currentX > w * 0.62 {
                detectedMode = .pulse
            } else {
                detectedMode = .flash
            }
            
            if detectedMode != activeMode {
                activeMode = detectedMode
                let selection = UISelectionFeedbackGenerator()
                selection.selectionChanged()
                updateKnobAppearance()
                onModeSelected?(detectedMode)
            }
        case .ended, .cancelled:
            isDragging = false
            let currentX = knobView.center.x
            let w = bounds.width
            let finalMode: Mode
            if currentX < w * 0.38 {
                finalMode = .sound
            } else if currentX > w * 0.62 {
                finalMode = .pulse
            } else {
                finalMode = .flash
            }
            setMode(finalMode, animated: true)
        default:
            isDragging = false
        }
    }
    
    public func setMode(_ mode: Mode, animated: Bool = true) {
        let modeChanged = (mode != activeMode)
        self.activeMode = mode
        
        if modeChanged {
            let selection = UISelectionFeedbackGenerator()
            selection.selectionChanged()
            onModeSelected?(mode)
        }
        
        updateKnobAppearance()
        
        let target = targetCenter(for: mode)
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0.5, options: [.curveEaseInOut]) {
                self.knobView.center = target
            }
        } else {
            self.knobView.center = target
        }
    }
    
    public func setPlaying(_ playing: Bool) {
        self.isPlaying = playing
        UIView.animate(withDuration: 0.1, delay: 0, options: [.curveLinear]) {
            self.knobOff.alpha = playing ? 0.0 : 1.0
            self.updateKnobAppearance()
        }
    }
    
    private func updateKnobAppearance() {
        // Mode 'on' icons are always visible underneath when active
        soundOn.alpha = (activeMode == .sound) ? 1.0 : 0.0
        flashOn.alpha = (activeMode == .flash) ? 1.0 : 0.0
        pulseOn.alpha = (activeMode == .pulse) ? 1.0 : 0.0
        
        // Mode 'off' icons sit on top and transition alpha
        soundOff.alpha = (activeMode == .sound && !isPlaying) ? 1.0 : 0.0
        flashOff.alpha = (activeMode == .flash && !isPlaying) ? 1.0 : 0.0
        pulseOff.alpha = (activeMode == .pulse && !isPlaying) ? 1.0 : 0.0
    }
}

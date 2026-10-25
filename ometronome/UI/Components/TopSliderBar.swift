//
//  TopSliderBar.swift
//  ometronome
//

import UIKit

@IBDesignable
public class TopSliderBar: UIView {
    
    // Callbacks
    public var onProgressChanged: ((Float, Int) -> Void)?
    public var onCenterButtonTapped: (() -> Void)?
    
    // State
    public private(set) var progress: Float = 15.56 // Default 68 BPM (68 - 40) / 1.8 ≈ 15.56%
    public private(set) var isPlaying: Bool = false
    public private(set) var tooltipVisible: Bool = true
    
    private let maxTotalRotation: CGFloat = 270.0 // -45° to +225°
    private var tooltipDismissWorkItem: DispatchWorkItem?
    
    // UI Elements
    private let containerView = UIView()
    private let emptyTrackImageView = UIImageView()
    private let wedgesContainer = UIView()
    private let baseWedge = UIImageView()
    private let d45 = UIImageView()
    private let d90 = UIImageView()
    private let d135 = UIImageView()
    private let d180 = UIImageView()
    private let d225 = UIImageView()
    private let d270 = UIImageView()
    private let surfaceImageView = UIImageView()
    private let aoImageView = UIImageView()
    
    // Center Button
    private let centerButton = UIView()
    private let centerButtonOn = UIImageView()
    private let centerButtonOff = UIImageView()
    
    // Rotary Knob Thumb
    private let knobView = UIView()
    private let knobOn = UIImageView()
    private let knobOff = UIImageView()
    
    // Tooltip
    private let tooltipContainer = UIView()
    private let tooltipLabel = UILabel()
    
    private var isDraggingKnob = false
    
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
        
        addSubview(containerView)
        containerView.backgroundColor = .clear
        containerView.clipsToBounds = false
        
        // 1. Empty Track
        emptyTrackImageView.image = imageNamed("top_slider_progress_empty")
        emptyTrackImageView.contentMode = .scaleAspectFit
        containerView.addSubview(emptyTrackImageView)
        
        // 2. Wedges Container
        wedgesContainer.backgroundColor = .clear
        wedgesContainer.clipsToBounds = false
        containerView.addSubview(wedgesContainer)
        
        let wedges = [baseWedge, d45, d90, d135, d180, d225, d270]
        for wedge in wedges {
            wedge.image = imageNamed("top_slider_progress_filled")
            wedge.contentMode = .scaleAspectFit
            wedgesContainer.addSubview(wedge)
        }
        
        // 3. Surface Bezel Ring
        surfaceImageView.image = imageNamed("top_slider_surface")
        surfaceImageView.contentMode = .scaleAspectFit
        containerView.addSubview(surfaceImageView)
        
        // 4. Ambient Occlusion Overlay
        aoImageView.image = imageNamed("top_slider_ao")
        aoImageView.contentMode = .scaleAspectFit
        containerView.addSubview(aoImageView)
        
        // 5. Rotary Knob
        knobView.clipsToBounds = false
        containerView.addSubview(knobView)
        
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
        
        // 6. Center Button
        centerButton.clipsToBounds = false
        containerView.addSubview(centerButton)
        
        // Base layer (on): always visible underneath with shadow effect
        centerButtonOn.image = imageNamed("center_button_on")
        centerButtonOn.contentMode = .scaleAspectFit
        centerButtonOn.alpha = 1.0
        centerButton.addSubview(centerButtonOn)
        
        // Top layer (off): transitions alpha
        centerButtonOff.image = imageNamed("center_button_off")
        centerButtonOff.contentMode = .scaleAspectFit
        centerButtonOff.alpha = 1.0
        centerButton.addSubview(centerButtonOff)
        
        let centerTap = UITapGestureRecognizer(target: self, action: #selector(handleCenterTap))
        centerButton.addGestureRecognizer(centerTap)
        centerButton.isUserInteractionEnabled = true
        
        // 7. Tooltip "Press to Start"
        tooltipContainer.backgroundColor = UIColor(white: 0.25, alpha: 0.95)
        tooltipContainer.layer.cornerRadius = 4
        tooltipContainer.layer.masksToBounds = true
        tooltipContainer.isUserInteractionEnabled = false
        containerView.addSubview(tooltipContainer)
        
        tooltipLabel.text = NSLocalizedString("press_to_start", comment: "Press to Start")
        tooltipLabel.font = UIFont(name: "Rubik-Regular", size: 12) ?? UIFont.systemFont(ofSize: 12, weight: .regular)
        tooltipLabel.textColor = .white
        tooltipLabel.textAlignment = .center
        tooltipContainer.addSubview(tooltipLabel)
        
        // Auto-dismiss tooltip after 3000ms timeout matching Android showTooltip(3000L)
        scheduleTooltipDismiss()
        
        // Drag Gesture for rotary control
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
    }
    
    private func scheduleTooltipDismiss() {
        tooltipDismissWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.hideTooltip()
        }
        tooltipDismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.6, execute: workItem)
    }
    
    private func imageNamed(_ name: String) -> UIImage? {
        return UIImage(named: name, in: Bundle(for: type(of: self)), compatibleWith: nil) ?? UIImage(named: name)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        let size = min(bounds.width, bounds.height)
        let containerFrame = CGRect(x: (bounds.width - size) / 2, y: (bounds.height - size) / 2, width: size, height: size)
        containerView.frame = containerFrame
        
        let fullRect = CGRect(origin: .zero, size: CGSize(width: size, height: size))
        emptyTrackImageView.frame = fullRect
        wedgesContainer.frame = fullRect
        
        let wedges = [baseWedge, d45, d90, d135, d180, d225, d270]
        for wedge in wedges {
            wedge.bounds = fullRect
            wedge.center = CGPoint(x: size / 2, y: size / 2)
        }
        
        surfaceImageView.frame = fullRect
        aoImageView.frame = fullRect
        
        // Center Button: diameter = size * (241 / 675)
        let centerBtnSize = size * (241.0 / 675.0)
        let centerBtnFrame = CGRect(
            x: (size - centerBtnSize) / 2,
            y: (size - centerBtnSize) / 2,
            width: centerBtnSize,
            height: centerBtnSize
        )
        centerButton.frame = centerBtnFrame
        centerButtonOff.frame = centerButton.bounds
        centerButtonOn.frame = centerButton.bounds
        
        // Tooltip: below center button
        tooltipLabel.sizeToFit()
        let padH: CGFloat = 8
        let padV: CGFloat = 4
        let tooltipW = tooltipLabel.bounds.width + padH * 2
        let tooltipH = tooltipLabel.bounds.height + padV * 2
        let tooltipX = (size - tooltipW) / 2
        let tooltipY = centerBtnFrame.maxY + (centerBtnSize * 0.128)
        tooltipContainer.frame = CGRect(x: tooltipX, y: tooltipY, width: tooltipW, height: tooltipH)
        tooltipLabel.frame = tooltipContainer.bounds
        
        // Knob size: size * 0.235
        let knobDiameter = size * 0.235
        knobView.bounds = CGRect(x: 0, y: 0, width: knobDiameter, height: knobDiameter)
        knobOn.frame = knobView.bounds
        knobOff.frame = knobView.bounds
        
        positionKnob(size: size)
        updateProgressWedges(progress)
    }
    
    private func positionKnob(size: CGFloat) {
        let center = CGPoint(x: size / 2, y: size / 2)
        let orbitRadius = (size / 2) * 0.76
        
        // Progress 0% -> 135° (South-West / 7:30)
        // Progress 100% -> 405° = 45° (South-East / 4:30)
        let totalDeg = Double(progress) * Double(maxTotalRotation) / 100.0
        let currentAngleDeg = 135.0 + totalDeg
        let mathAngleRad = currentAngleDeg * .pi / 180.0
        
        let knobX = center.x + CGFloat(cos(mathAngleRad)) * orbitRadius
        let knobY = center.y + CGFloat(sin(mathAngleRad)) * orbitRadius
        
        knobView.center = CGPoint(x: knobX, y: knobY)
        // Keep knob upright so lighting/shadow matches Android
        knobView.transform = .identity
    }
    
    private func updateProgressWedges(_ percent: Float) {
        let totalRotation = CGFloat(percent) * maxTotalRotation / 100.0
        
        d45.transform = CGAffineTransform(rotationAngle: clamp(totalRotation, min: 0, max: 45) * .pi / 180.0)
        d90.transform = CGAffineTransform(rotationAngle: clamp(totalRotation, min: 0, max: 90) * .pi / 180.0)
        d135.transform = CGAffineTransform(rotationAngle: clamp(totalRotation, min: 0, max: 135) * .pi / 180.0)
        d180.transform = CGAffineTransform(rotationAngle: clamp(totalRotation, min: 0, max: 180) * .pi / 180.0)
        d225.transform = CGAffineTransform(rotationAngle: clamp(totalRotation, min: 0, max: 225) * .pi / 180.0)
        d270.transform = CGAffineTransform(rotationAngle: clamp(totalRotation, min: 0, max: 270) * .pi / 180.0)
    }
    
    private func clamp(_ val: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
        return Swift.max(min, Swift.min(max, val))
    }
    
    @objc private func handleCenterTap() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        if tooltipVisible {
            hideTooltip()
        }
        onCenterButtonTapped?()
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard isPlaying else { return }
        
        let loc = gesture.location(in: containerView)
        let size = min(bounds.width, bounds.height)
        let center = CGPoint(x: size / 2, y: size / 2)
        
        let dx = loc.x - center.x
        let dy = loc.y - center.y
        
        // Check if inside center button on start: don't drag if starting inside center button
        if gesture.state == .began {
            let distFromCenter = sqrt(dx * dx + dy * dy)
            let centerBtnRadius = (size * (241.0 / 675.0)) / 2
            if distFromCenter < centerBtnRadius {
                isDraggingKnob = false
                return
            }
            isDraggingKnob = true
            if tooltipVisible {
                hideTooltip()
            }
        }
        
        guard isDraggingKnob else { return }
        
        // In screen coordinates (0° East, 90° South, 180° West, 270° North):
        var degrees = Double(atan2(dy, dx)) * 180.0 / .pi
        if degrees < 0 { degrees += 360.0 }
        
        // Arc starts at 135° (progress 0%) and sweeps clockwise by 270° to 45° (progress 100%).
        // Gap is between 45° and 135° (the bottom 90° opening).
        var sweep: Double
        if degrees >= 135.0 {
            sweep = degrees - 135.0
        } else if degrees <= 45.0 {
            sweep = degrees + 225.0
        } else {
            // In the bottom gap (45° < degrees < 135°):
            if degrees < 90.0 {
                sweep = 270.0
            } else {
                sweep = 0.0
            }
        }
        
        let newProgress = Float(Swift.max(0.0, Swift.min(100.0, (sweep / 270.0) * 100.0)))
        let rawBpm = Int(round(Double(newProgress) * 1.8 + 40.0))
        let evenBpm = (rawBpm % 2 == 0) ? rawBpm : rawBpm + 1
        let clampedBpm = Swift.max(40, Swift.min(220, evenBpm))
        
        setProgress(newProgress)
        onProgressChanged?(newProgress, clampedBpm)
    }
    
    // Public Controls
    public func setProgress(_ newProgress: Float) {
        self.progress = Swift.max(0.0, Swift.min(100.0, newProgress))
        let size = min(bounds.width, bounds.height)
        positionKnob(size: size)
        updateProgressWedges(self.progress)
    }
    
    public func setBpm(_ bpm: Int) {
        let clamped = Swift.max(40, Swift.min(220, bpm))
        let calculatedProgress = Float(clamped - 40) / 1.8
        setProgress(calculatedProgress)
    }
    
    public func setPlaying(_ playing: Bool) {
        self.isPlaying = playing
        UIView.animate(withDuration: 0.1, delay: 0, options: [.curveLinear]) {
            self.centerButtonOff.alpha = playing ? 0.0 : 1.0
            self.knobOff.alpha = playing ? 0.0 : 1.0
        }
        if playing && tooltipVisible {
            hideTooltip()
        }
    }
    
    public func hideTooltip() {
        tooltipDismissWorkItem?.cancel()
        tooltipDismissWorkItem = nil
        guard tooltipVisible else { return }
        tooltipVisible = false
        UIView.animate(withDuration: 0.3) {
            self.tooltipContainer.alpha = 0
            self.tooltipContainer.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        } completion: { _ in
            self.tooltipContainer.isHidden = true
        }
    }
}

//
//  HapticsEngine.swift
//  ometronome
//

import Foundation
import UIKit

public protocol HapticsControlling: AnyObject {
    func vibrate()
    func lightClick()
    var onVibrateSimulated: (() -> Void)? { get set }
}

public final class HapticsEngine: HapticsControlling {
    private var beatGenerator: UIImpactFeedbackGenerator?
    private var clickGenerator: UIImpactFeedbackGenerator?
    public var onVibrateSimulated: (() -> Void)?
    
    public init() {
        DispatchQueue.main.async { [weak self] in
            self?.beatGenerator = UIImpactFeedbackGenerator(style: .heavy)
            self?.beatGenerator?.prepare()
            self?.clickGenerator = UIImpactFeedbackGenerator(style: .light)
            self?.clickGenerator?.prepare()
        }
    }
    
    public func vibrate() {
        DispatchQueue.main.async { [weak self] in
            self?.beatGenerator?.impactOccurred()
            self?.beatGenerator?.prepare()
            self?.onVibrateSimulated?()
        }
    }
    
    public func lightClick() {
        DispatchQueue.main.async { [weak self] in
            self?.clickGenerator?.impactOccurred()
            self?.clickGenerator?.prepare()
        }
    }
}

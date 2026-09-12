//
//  FlashController.swift
//  ometronome
//

import Foundation
import AVFoundation

public protocol FlashControlling: AnyObject {
    var hasTorch: Bool { get }
    func blink()
    func off()
    var onBlinkSimulated: (() -> Void)? { get set }
}

public final class FlashController: FlashControlling {
    private var device: AVCaptureDevice? {
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) ?? AVCaptureDevice.default(for: .video)
    }
    public var onBlinkSimulated: (() -> Void)?
    private let queue = DispatchQueue(label: "com.ometronome.flash", qos: .userInteractive)
    
    public var hasTorch: Bool {
        guard let dev = device else { return false }
        return dev.hasTorch && dev.isTorchAvailable
    }
    
    public init() {}
    
    public func blink() {
        // Notify simulator/debug observer so user can visually verify beat pulse in simulator
        DispatchQueue.main.async { [weak self] in
            self?.onBlinkSimulated?()
        }
        
        guard let device = device, device.hasTorch, device.isTorchAvailable else {
            return
        }
        
        queue.async {
            do {
                try device.lockForConfiguration()
                if device.torchMode != .on {
                    try device.setTorchModeOn(level: AVCaptureDevice.maxAvailableTorchLevel)
                }
                device.unlockForConfiguration()
                
                // Keep torch on for 30ms (matching Android FlashController)
                DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + 0.030) {
                    guard device.hasTorch else { return }
                    do {
                        try device.lockForConfiguration()
                        device.torchMode = .off
                        device.unlockForConfiguration()
                    } catch {}
                }
            } catch {
                print("[FlashController] Error controlling torch: \(error)")
            }
        }
    }
    
    public func off() {
        guard let device = device, device.hasTorch else { return }
        queue.async {
            do {
                try device.lockForConfiguration()
                device.torchMode = .off
                device.unlockForConfiguration()
            } catch {}
        }
    }
}

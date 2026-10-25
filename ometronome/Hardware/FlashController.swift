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
    
    // Latency compensation: delay torch onset slightly (~20ms) so it turns on
    // in exact unison with the UI display pipeline frame rendering
    private let torchOnDelaySeconds: Double = 0.020
    private let torchDurationSeconds: Double = 0.040
    
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
        
        queue.asyncAfter(deadline: .now() + torchOnDelaySeconds) { [weak self] in
            guard let self = self, let dev = self.device, dev.hasTorch, dev.isTorchAvailable else { return }
            do {
                try dev.lockForConfiguration()
                if dev.torchMode != .on {
                    try dev.setTorchModeOn(level: AVCaptureDevice.maxAvailableTorchLevel)
                }
                dev.unlockForConfiguration()
                
                self.queue.asyncAfter(deadline: .now() + self.torchDurationSeconds) {
                    guard let activeDev = self.device, activeDev.hasTorch else { return }
                    do {
                        try activeDev.lockForConfiguration()
                        activeDev.torchMode = .off
                        activeDev.unlockForConfiguration()
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

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
    private let device: AVCaptureDevice? = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) ?? AVCaptureDevice.default(for: .video)
    public var onBlinkSimulated: (() -> Void)?
    private let queue = DispatchQueue(label: "com.ometronome.flash", qos: .userInteractive)
    
    // Middle ground: 0ms delay before onset, 25ms pulse duration for snappy high-BPM strobe
    private let torchDurationSeconds: Double = 0.025
    
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
        
        guard let dev = device, dev.hasTorch, dev.isTorchAvailable else {
            return
        }
        
        // Atomic single-pulse execution: turns on immediately (0ms delay), holds for 25ms, turns off.
        // Serial execution prevents overlapping queue backlog at high tempos (140-220 BPM).
        queue.async { [weak self, weak dev] in
            guard let self = self, let device = dev, device.hasTorch, device.isTorchAvailable else { return }
            do {
                try device.lockForConfiguration()
                if device.torchMode != .on {
                    try device.setTorchModeOn(level: AVCaptureDevice.maxAvailableTorchLevel)
                }
                device.unlockForConfiguration()
                
                usleep(UInt32(self.torchDurationSeconds * 1_000_000))
                
                try device.lockForConfiguration()
                device.torchMode = .off
                device.unlockForConfiguration()
            } catch {
                print("[FlashController] Error controlling torch: \(error)")
            }
        }
    }
    
    public func off() {
        guard let dev = device, dev.hasTorch else { return }
        queue.async { [weak dev] in
            guard let device = dev else { return }
            do {
                try device.lockForConfiguration()
                device.torchMode = .off
                device.unlockForConfiguration()
            } catch {}
        }
    }
}

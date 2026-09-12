//
//  MetronomeEngine.swift
//  ometronome
//

import Foundation

public protocol MetronomeEngineDelegate: AnyObject {
    func metronomeEngineDidTick(state: HomeState)
    func metronomeEngineStateDidChange(state: HomeState)
}

public final class MetronomeEngine {
    private let sound: SoundEngineProtocol
    private let flash: FlashControlling
    private let vibrator: HapticsControlling
    
    private let queue = DispatchQueue(label: "com.ometronome.engine", qos: .userInteractive)
    private var timer: DispatchSourceTimer?
    
    public weak var delegate: MetronomeEngineDelegate?
    
    private(set) public var state: HomeState {
        didSet {
            let updatedState = state
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.metronomeEngineStateDidChange(state: updatedState)
            }
        }
    }
    
    public init(
        sound: SoundEngineProtocol = SoundEngine(),
        flash: FlashControlling = FlashController(),
        vibrator: HapticsControlling = HapticsEngine()
    ) {
        self.sound = sound
        self.flash = flash
        self.vibrator = vibrator
        self.state = HomeState(isPlaying: false, mode: .sound, progress: 15.56)
    }
    
    public func start() {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.stopInternal()
            
            self.state.isPlaying = true
            self.state.tooltip = false
            
            // Fire the first tick immediately on start, then pace subsequent ticks
            self.scheduleNextTick(deadline: .now())
        }
    }
    
    public func stop() {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.stopInternal()
            self.state.isPlaying = false
        }
    }
    
    public func toggle() {
        if state.isPlaying {
            stop()
        } else {
            start()
        }
    }
    
    public func setMode(_ mode: Mode) {
        queue.async { [weak self] in
            guard let self = self else { return }
            let oldMode = self.state.mode
            self.state.mode = mode
            if !self.state.isPlaying {
                self.sound.stop()
                self.flash.off()
            } else {
                if oldMode == .sound && mode != .sound {
                    self.sound.stop()
                } else if oldMode == .flash && mode != .flash {
                    self.flash.off()
                }
            }
        }
    }
    
    public func setProgress(_ progress: Float) {
        queue.async { [weak self] in
            guard let self = self else { return }
            let clamped = max(0.0, min(100.0, progress))
            self.state.progress = clamped
            // Do NOT re-trigger or cancel the current beat.
            // The ongoing beat completes its natural interval, and scheduleNextTick
            // will automatically apply the new BPM value for subsequent ticks.
        }
    }
    
    public func setTooltip(_ show: Bool) {
        queue.async { [weak self] in
            self?.state.tooltip = show
        }
    }
    
    // MARK: - Internal Timing
    
    private func scheduleNextTick(deadline: DispatchTime) {
        timer?.cancel()
        timer = nil
        
        guard state.isPlaying else { return }
        
        let newTimer = DispatchSource.makeTimerSource(flags: .strict, queue: queue)
        newTimer.schedule(deadline: deadline, leeway: .nanoseconds(500_000)) // 0.5ms precision
        
        newTimer.setEventHandler { [weak self] in
            guard let self = self, self.state.isPlaying else { return }
            
            // 1. Execute hardware action for currently active mode (.sound, .flash, .pulse)
            self.executeHardwareAction(mode: self.state.mode)
            
            let currentState = self.state
            DispatchQueue.main.async {
                self.delegate?.metronomeEngineDidTick(state: currentState)
            }
            
            // 2. Calculate next beat deadline using the latest user-selected BPM
            let bpm = self.state.bpm
            let intervalNanos = UInt64(60_000_000_000.0 / Double(bpm))
            let nextDeadline = DispatchTime.now() + .nanoseconds(Int(intervalNanos))
            
            // 3. Schedule next tick
            self.scheduleNextTick(deadline: nextDeadline)
        }
        
        newTimer.resume()
        self.timer = newTimer
    }
    
    private func executeHardwareAction(mode: Mode) {
        switch mode {
        case .sound:
            sound.tick()
        case .flash:
            flash.blink()
        case .pulse:
            vibrator.vibrate()
        }
    }
    
    private func stopInternal() {
        timer?.cancel()
        timer = nil
        
        sound.stop()
        flash.off()
    }
    
    deinit {
        timer?.cancel()
        timer = nil
    }
}

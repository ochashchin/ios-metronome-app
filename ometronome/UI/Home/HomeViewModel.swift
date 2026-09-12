//
//  HomeViewModel.swift
//  ometronome
//

import Foundation
import Combine
import SwiftUI

public final class HomeViewModel: ObservableObject, MetronomeEngineDelegate {
    public let engine: MetronomeEngine
    private let soundEngine: SoundEngine
    private let flashController: FlashController
    private let hapticsEngine: HapticsEngine
    
    @Published public var state: HomeState
    @Published public var flashSimulatedBlink: Bool = false
    @Published public var pulseSimulatedBounce: Bool = false
    
    public init(engine: MetronomeEngine? = nil) {
        let sound = SoundEngine()
        let flash = FlashController()
        let haptics = HapticsEngine()
        
        self.soundEngine = sound
        self.flashController = flash
        self.hapticsEngine = haptics
        
        let metronome = engine ?? MetronomeEngine(sound: sound, flash: flash, vibrator: haptics)
        self.engine = metronome
        self.state = metronome.state
        
        metronome.delegate = self
        
        // Attach simulator visual feedback callbacks
        flash.onBlinkSimulated = { [weak self] in
            guard let self = self, self.state.isPlaying, self.state.mode == .flash else { return }
            self.triggerFlashSimulation()
        }
        
        haptics.onVibrateSimulated = { [weak self] in
            guard let self = self, self.state.isPlaying, self.state.mode == .pulse else { return }
            self.triggerPulseSimulation()
        }
    }
    
    public func toggle() {
        hapticsEngine.lightClick()
        engine.toggle()
    }
    
    public func stop() {
        engine.stop()
    }
    
    public func setMode(_ mode: Mode) {
        guard mode != state.mode else { return }
        hapticsEngine.lightClick()
        engine.setMode(mode)
    }
    
    public func setProgress(_ progress: Float) {
        engine.setProgress(progress)
    }
    
    public func setTooltip(_ show: Bool) {
        engine.setTooltip(show)
    }
    
    public func dismissTooltip() {
        if state.tooltip {
            engine.setTooltip(false)
        }
    }
    
    // MARK: - MetronomeEngineDelegate
    
    public func metronomeEngineDidTick(state: HomeState) {
        self.state = state
    }
    
    public func metronomeEngineStateDidChange(state: HomeState) {
        self.state = state
    }
    
    // MARK: - Simulator Emulation
    
    private func triggerFlashSimulation() {
        flashSimulatedBlink = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.flashSimulatedBlink = false
        }
    }
    
    private func triggerPulseSimulation() {
        withAnimation(.easeOut(duration: 0.08)) {
            pulseSimulatedBounce = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
            withAnimation(.easeIn(duration: 0.08)) {
                self?.pulseSimulatedBounce = false
            }
        }
    }
}

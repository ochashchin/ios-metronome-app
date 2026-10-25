//
//  HomeState.swift
//  ometronome
//

import Foundation

public struct HomeState: Equatable {
    public var isPlaying: Bool
    public var mode: Mode
    public var progress: Float // 0.0 ... 100.0
    public var tooltip: Bool
    public var flashBlink: Bool
    public var pulseBounce: Bool
    
    public init(
        isPlaying: Bool = false,
        mode: Mode = .sound,
        progress: Float = 15.56,
        tooltip: Bool = false,
        flashBlink: Bool = false,
        pulseBounce: Bool = false
    ) {
        self.isPlaying = isPlaying
        self.mode = mode
        self.progress = progress
        self.tooltip = tooltip
        self.flashBlink = flashBlink
        self.pulseBounce = pulseBounce
    }
    
    /// Tempo calculated identically to Android HomeState.getBpm()
    /// int result = (int) (progress * 1.8 + 40);
    /// return (result % 2 == 0) ? result : result + 1;
    public var bpm: Int {
        let raw = Int(Double(progress) * 1.8 + 40.0)
        return (raw % 2 == 0) ? raw : raw + 1
    }
    
    /// Milliseconds calculated identically to Android HomeState.getMs()
    /// Math.round(60000.0 / bpm)
    public var ms: Int {
        let currentBpm = max(1, bpm)
        return Int(round(60000.0 / Double(currentBpm)))
    }
    
    public func copyIsPlaying(_ playing: Bool) -> HomeState {
        HomeState(isPlaying: playing, mode: mode, progress: progress, tooltip: tooltip, flashBlink: false, pulseBounce: false)
    }
    
    public func copyMode(_ newMode: Mode) -> HomeState {
        HomeState(isPlaying: isPlaying, mode: newMode, progress: progress, tooltip: tooltip, flashBlink: false, pulseBounce: false)
    }
    
    public func copyProgress(_ newProgress: Float) -> HomeState {
        HomeState(isPlaying: isPlaying, mode: mode, progress: newProgress, tooltip: tooltip, flashBlink: false, pulseBounce: false)
    }
    
    public func copyTooltip(_ show: Bool) -> HomeState {
        HomeState(isPlaying: isPlaying, mode: mode, progress: progress, tooltip: show, flashBlink: false, pulseBounce: false)
    }
    
    public func copyFlashBlink() -> HomeState {
        HomeState(isPlaying: isPlaying, mode: mode, progress: progress, tooltip: tooltip, flashBlink: true, pulseBounce: false)
    }
    
    public func copyPulseBounce() -> HomeState {
        HomeState(isPlaying: isPlaying, mode: mode, progress: progress, tooltip: tooltip, flashBlink: false, pulseBounce: true)
    }
}

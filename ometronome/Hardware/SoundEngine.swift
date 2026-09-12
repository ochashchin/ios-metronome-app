//
//  SoundEngine.swift
//  ometronome
//

import Foundation
import AVFoundation

public protocol SoundEngineProtocol: AnyObject {
    func tick()
    func stop()
}

public final class SoundEngine: SoundEngineProtocol {
    private var players: [AVAudioPlayer] = []
    private var currentIndex = 0
    private let queue = DispatchQueue(label: "com.ometronome.sound", qos: .userInteractive)
    
    public init() {
        configureAudioSession()
        preloadSound()
    }
    
    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("[SoundEngine] Failed to configure AVAudioSession: \(error)")
        }
    }
    
    private func preloadSound() {
        guard let soundURL = Bundle.main.url(forResource: "hit", withExtension: "wav") else {
            print("[SoundEngine] Audio asset 'hit.wav' not found in bundle")
            return
        }
        
        // Use a pool of 4 pre-warmed players (matching Android SoundPool maxStreams=4)
        for _ in 0..<4 {
            if let player = try? AVAudioPlayer(contentsOf: soundURL) {
                player.numberOfLoops = 0
                player.prepareToPlay()
                players.append(player)
            }
        }
    }
    
    public func tick() {
        queue.async { [weak self] in
            guard let self = self, !self.players.isEmpty else { return }
            let player = self.players[self.currentIndex]
            player.currentTime = 0
            player.play()
            self.currentIndex = (self.currentIndex + 1) % self.players.count
        }
    }
    
    public func stop() {
        queue.async { [weak self] in
            guard let self = self else { return }
            for player in self.players {
                player.stop()
                player.currentTime = 0
            }
        }
    }
}

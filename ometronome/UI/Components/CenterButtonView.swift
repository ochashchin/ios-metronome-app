//
//  CenterButtonView.swift
//  ometronome
//

import SwiftUI

public struct CenterButtonView: View {
    let isPlaying: Bool
    let action: () -> Void
    
    public init(isPlaying: Bool, action: @escaping () -> Void) {
        self.isPlaying = isPlaying
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            ZStack {
                Image("center_button_off")
                    .resizable()
                    .scaledToFit()
                    .opacity(isPlaying ? 0.0 : 1.0)
                    .animation(.easeInOut(duration: 0.15), value: isPlaying)
                
                Image("center_button_on")
                    .resizable()
                    .scaledToFit()
                    .opacity(isPlaying ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.15), value: isPlaying)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(NSLocalizedString("play_metronome", comment: "Play metronome"))
    }
}

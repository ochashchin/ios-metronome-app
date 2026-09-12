//
//  BottomSliderView.swift
//  ometronome
//

import SwiftUI

public struct BottomSliderView: View {
    let activeMode: Mode
    let isPlaying: Bool
    let onModeSelected: (Mode) -> Void
    
    public init(
        activeMode: Mode,
        isPlaying: Bool,
        onModeSelected: @escaping (Mode) -> Void
    ) {
        self.activeMode = activeMode
        self.isPlaying = isPlaying
        self.onModeSelected = onModeSelected
    }
    
    private var bias: CGFloat {
        switch activeMode {
        case .sound: return 0.0
        case .flash: return 0.5
        case .pulse: return 1.0
        }
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let trackWidth = geometry.size.width
            let trackHeight = geometry.size.height
            // Thumb button diameter matches track height with padding
            let thumbSize = trackHeight * 0.88
            let availableTravel = trackWidth - thumbSize
            let thumbX = availableTravel * bias
            
            ZStack(alignment: .leading) {
                // 1. Slider Bar Background
                Image("bottom_slider")
                    .resizable()
                    .scaledToFit()
                    .frame(width: trackWidth, height: trackHeight)
                
                // 2. Mode Icons Inset
                Image("bottom_slider_icons")
                    .resizable()
                    .scaledToFit()
                    .frame(width: trackWidth, height: trackHeight)
                
                // 3. Sliding Thumb Knob
                ZStack {
                    Image("slider_button_on")
                        .resizable()
                        .scaledToFit()
                        .opacity(isPlaying ? 1.0 : 0.0)
                    
                    Image("slider_button_off")
                        .resizable()
                        .scaledToFit()
                        .opacity(isPlaying ? 0.0 : 1.0)
                    
                    // Active mode icon on the thumb
                    modeIconView(for: activeMode)
                        .frame(width: thumbSize * 0.55, height: thumbSize * 0.55)
                }
                .frame(width: thumbSize, height: thumbSize)
                .offset(x: thumbX, y: 0)
                .animation(.spring(response: 0.35, dampingFraction: 0.72), value: bias)
                .animation(.easeInOut(duration: 0.15), value: isPlaying)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let locationX = value.location.x
                        let segmentWidth = trackWidth / 3.0
                        
                        let targetMode: Mode
                        if locationX < segmentWidth {
                            targetMode = .sound
                        } else if locationX > segmentWidth * 2.0 {
                            targetMode = .pulse
                        } else {
                            targetMode = .flash
                        }
                        
                        if targetMode != activeMode {
                            onModeSelected(targetMode)
                        }
                    }
            )
        }
        .aspectRatio(416.0 / 158.0, contentMode: .fit)
    }
    
    @ViewBuilder
    private func modeIconView(for mode: Mode) -> some View {
        switch mode {
        case .sound:
            ZStack {
                Image("sound_off")
                    .resizable()
                    .scaledToFit()
                    .opacity(isPlaying ? 0.0 : 1.0)
                Image("sound_on")
                    .resizable()
                    .scaledToFit()
                    .opacity(isPlaying ? 1.0 : 0.0)
            }
        case .flash:
            ZStack {
                Image("flash_off")
                    .resizable()
                    .scaledToFit()
                    .opacity(isPlaying ? 0.0 : 1.0)
                Image("flash_on")
                    .resizable()
                    .scaledToFit()
                    .opacity(isPlaying ? 1.0 : 0.0)
            }
        case .pulse:
            ZStack {
                Image("pulse_off")
                    .resizable()
                    .scaledToFit()
                    .opacity(isPlaying ? 0.0 : 1.0)
                Image("pulse_on")
                    .resizable()
                    .scaledToFit()
                    .opacity(isPlaying ? 1.0 : 0.0)
            }
        }
    }
}

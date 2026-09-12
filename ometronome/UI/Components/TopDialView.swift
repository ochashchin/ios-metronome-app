//
//  TopDialView.swift
//  ometronome
//

import SwiftUI

public struct TopDialView: View {
    let progress: Float
    let isPlaying: Bool
    let onProgressChanged: (Float) -> Void
    
    // Total rotary sweep is 270 degrees (from -45° to +225°)
    private let maxRotation: Double = 270.0
    
    public init(
        progress: Float,
        isPlaying: Bool,
        onProgressChanged: @escaping (Float) -> Void
    ) {
        self.progress = progress
        self.isPlaying = isPlaying
        self.onProgressChanged = onProgressChanged
    }
    
    private var knobAngle: Double {
        // Progress 0% -> -45°, Progress 100% -> 225°
        let total = (Double(progress) * maxRotation) / 100.0
        return -45.0 + total
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = size / 2
            
            ZStack {
                // 1. Empty Progress Track
                Image("top_slider_progress_empty")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                
                // 2. 6-Segment Layered Arc Fill (Matching Android d45...d270)
                Group {
                    let totalRotation = Double(progress) * maxRotation / 100.0
                    
                    Image("top_slider_progress_filled")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)
                    
                    Image("top_slider_progress_filled")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)
                        .rotationEffect(.degrees(min(totalRotation, 45.0)))
                    
                    Image("top_slider_progress_filled")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)
                        .rotationEffect(.degrees(min(totalRotation, 90.0)))
                    
                    Image("top_slider_progress_filled")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)
                        .rotationEffect(.degrees(min(totalRotation, 135.0)))
                    
                    Image("top_slider_progress_filled")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)
                        .rotationEffect(.degrees(min(totalRotation, 180.0)))
                    
                    Image("top_slider_progress_filled")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)
                        .rotationEffect(.degrees(min(totalRotation, 225.0)))
                    
                    Image("top_slider_progress_filled")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)
                        .rotationEffect(.degrees(min(totalRotation, 270.0)))
                }
                
                // 3. Surface Bezel Ring
                Image("top_slider_surface")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                
                // 4. Ambient Occlusion Overlay
                Image("top_slider_ao")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                
                // 5. Rotary Knob Thumb
                let knobSize = size * 0.235
                let orbitRadius = radius * 0.76
                let angleRad = (knobAngle - 90.0) * .pi / 180.0
                let knobX = center.x + CGFloat(cos(angleRad)) * orbitRadius
                let knobY = center.y + CGFloat(sin(angleRad)) * orbitRadius
                
                ZStack {
                    Image("slider_button_on")
                        .resizable()
                        .scaledToFit()
                        .frame(width: knobSize, height: knobSize)
                        .opacity(isPlaying ? 1.0 : 0.0)
                    
                    Image("slider_button_off")
                        .resizable()
                        .scaledToFit()
                        .frame(width: knobSize, height: knobSize)
                        .opacity(isPlaying ? 0.0 : 1.0)
                }
                .rotationEffect(.degrees(knobAngle))
                .position(x: knobX, y: knobY)
            }
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let location = value.location
                        let dx = location.x - center.x
                        let dy = location.y - center.y
                        
                        // Angle from top (-Y): 0 at 12 o'clock
                        var degrees = Double(atan2(dy, dx)) * 180.0 / .pi + 90.0
                        if degrees < 0 { degrees += 360.0 }
                        
                        // Map degrees to Android coordinate system:
                        // Top is 0°, Left is -90° (270°), Right is +90°, Bottom is 180°
                        // Android start angle is -45° (top-left, 315°), end is 225° (bottom-left)
                        var angleFromStart: Double
                        if degrees >= 315.0 {
                            angleFromStart = degrees - 315.0
                        } else if degrees <= 225.0 {
                            angleFromStart = degrees + 45.0
                        } else {
                            // Dead zone between 225° and 315°: clamp to nearest edge
                            if degrees < 270.0 {
                                angleFromStart = 270.0
                            } else {
                                angleFromStart = 0.0
                            }
                        }
                        
                        let newProgress = Float(max(0.0, min(100.0, (angleFromStart / maxRotation) * 100.0)))
                        onProgressChanged(newProgress)
                    }
            )
        }
    }
}

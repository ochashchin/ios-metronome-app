//
//  MetronomeMainView.swift
//  ometronome
//

import SwiftUI

public struct MetronomeMainView: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var reviewManager = ReviewManager.shared
    
    // Splash animation states
    @State private var splashAnimating = true
    @State private var metroOffset: CGFloat = 0
    @State private var nomeOffset: CGFloat = 0
    @State private var logoOpacity: Double = 1.0
    @State private var vignetteOpacity: Double = 0.0
    @State private var controlsOpacity: Double = 0.0
    @State private var controlsScale: CGFloat = 0.94
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // 1. App Dynamic Background Color (#D5D8DD in Light, #1D1D1D in Dark)
            Color("BackgroundColor")
                .edgesIgnoringSafeArea(.all)
            
            // 2. Vignette Background
            Image("vignette")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
                .opacity(vignetteOpacity)
            
            // 3. Main Controls Layer
            VStack(spacing: 0) {
                Spacer()
                
                // Top Circular Dial Section
                ZStack {
                    TopDialView(
                        progress: viewModel.state.progress,
                        isPlaying: viewModel.state.isPlaying,
                        onProgressChanged: { newProgress in
                            viewModel.setProgress(newProgress)
                        }
                    )
                    .frame(maxWidth: 380, maxHeight: 380)
                    .aspectRatio(1.0, contentMode: .fit)
                    
                    // Center Power Button
                    CenterButtonView(
                        isPlaying: viewModel.state.isPlaying,
                        action: {
                            viewModel.toggle()
                        }
                    )
                    .frame(width: 96, height: 96)
                    
                    // Onboarding Tooltip (Auto-shown and dismissable)
                    if viewModel.state.tooltip && !viewModel.state.isPlaying {
                        TooltipView(
                            text: NSLocalizedString("press_to_start", comment: ""),
                            onDismiss: {
                                viewModel.dismissTooltip()
                            }
                        )
                        .offset(y: -74)
                        .transition(.opacity.combined(with: .scale))
                    }
                }
                .padding(.horizontal, 24)
                .scaleEffect(viewModel.pulseSimulatedBounce ? 1.03 : 1.0)
                .animation(.easeOut(duration: 0.08), value: viewModel.pulseSimulatedBounce)
                
                // Readout Section: BPM & Milliseconds
                VStack(spacing: 4) {
                    Text("\(viewModel.state.bpm)")
                        .font(.custom("Rubik-Regular", size: 68))
                        .foregroundColor(Color("TextColor"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    Text("\(viewModel.state.ms) ms")
                        .font(.custom("Rubik-Bold", size: 16))
                        .foregroundColor(Color("TextColor").opacity(0.85))
                        .tracking(0.5)
                }
                .padding(.top, 10)
                .padding(.bottom, 24)
                
                // Bottom Mode Bar (3 Modes: Sound, Flash, Pulse)
                BottomSliderView(
                    activeMode: viewModel.state.mode,
                    isPlaying: viewModel.state.isPlaying,
                    onModeSelected: { mode in
                        viewModel.setMode(mode)
                    }
                )
                .frame(maxWidth: 320)
                .padding(.horizontal, 32)
                .padding(.bottom, 36)
                
                Spacer()
            }
            .opacity(controlsOpacity)
            .scaleEffect(controlsScale)
            
            // 4. Flash Simulator Visual Indicator (For verifying flash mode on Simulator!)
            if viewModel.flashSimulatedBlink {
                Color.white
                    .opacity(0.85)
                    .edgesIgnoringSafeArea(.all)
                    .allowsHitTesting(false)
            }
            
            // 5. Kinetic Intro Splash Layer
            if splashAnimating {
                ZStack {
                    Color("BackgroundColor")
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack(spacing: -38) {
                        Image("metro_")
                            .resizable()
                            .scaledToFit()
                            .offset(x: metroOffset)
                        
                        Image("nome_")
                            .resizable()
                            .scaledToFit()
                            .offset(x: nomeOffset)
                    }
                    .padding(.horizontal, 20)
                    .frame(maxWidth: 420)
                    .opacity(logoOpacity)
                }
            }
            
            // 6. Review Rating Modal Dialog
            if reviewManager.shouldShowDialog {
                ReviewDialogView(
                    onRateNow: {
                        reviewManager.rateNow()
                    },
                    onLater: {
                        reviewManager.dismiss()
                    }
                )
                .transition(.opacity)
            }
        }
        .onAppear {
            reviewManager.logAppLaunch()
            startSplashAnimation()
        }
    }
    
    private func startSplashAnimation() {
        // 1. Launch Screen / Splash delay (600 ms)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring(response: 0.85, dampingFraction: 0.65)) {
                metroOffset = -600
                nomeOffset = -700
                logoOpacity = 0.0
                vignetteOpacity = 1.0
                controlsOpacity = 1.0
                controlsScale = 1.0
            }
            
            // 2. Motion completes (0.85s) + 1000ms delay in between -> Tooltip (2.45s total from launch)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.85) {
                splashAnimating = false
                // Trigger onboarding tooltip
                withAnimation(.easeIn(duration: 0.25)) {
                    viewModel.setTooltip(true)
                }
            }
        }
    }
}

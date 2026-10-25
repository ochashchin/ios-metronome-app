//
//  ViewController.swift
//  ometronome
//

import UIKit
import AVFoundation
import SwiftUI

class ViewController: UIViewController, MetronomeEngineDelegate {
    
    // Storyboard Outlets
    @IBOutlet weak var controlsContainer: UIView!
    @IBOutlet weak var topSliderBar: TopSliderBar!
    @IBOutlet weak var bottomSliderBar: BottomSliderBar!
    @IBOutlet weak var bpmLabel: UILabel!
    @IBOutlet weak var msLabel: UILabel!
    @IBOutlet weak var vignetteImageView: UIImageView!
    
    // Core Engines
    private let soundEngine = SoundEngine()
    private let flashController = FlashController()
    private let hapticsEngine = HapticsEngine()
    private lazy var engine = MetronomeEngine(
        sound: soundEngine,
        flash: flashController,
        vibrator: hapticsEngine
    )
    
    // Flash Overlay & Ad Banner & Review Dialog
    private let flashOverlay = FlashOverlayView()
    private let adBannerContainer = AdBannerContainerView()
    private var reviewController: UIHostingController<ReviewDialogView>?
    
    // Splash Intro (Android match)
    private var splashIntroView: SplashIntroView?
    private var splashWorkItems: [DispatchWorkItem] = []
    
    private var isUITesting: Bool {
        return CommandLine.arguments.contains("-UITestStartPlaying") ||
               CommandLine.arguments.contains("-UITestShowReviewDialog") ||
               CommandLine.arguments.contains("-UITestTriggerRateNow") ||
               CommandLine.arguments.contains("-UITestModeFlash") ||
               CommandLine.arguments.contains("-UITestModePulse") ||
               CommandLine.arguments.contains("-UITestFastForward")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(named: "BackgroundColor")
        
        // Vignette is initially transparent and fades in with intro exit
        vignetteImageView?.isHidden = false
        vignetteImageView?.alpha = isUITesting ? 1.0 : 0.0
        
        // Setup BPM Label
        if let bpm = bpmLabel {
            bpm.font = UIFont(name: "Rubik-Regular", size: 78) ?? UIFont.systemFont(ofSize: 78, weight: .regular)
            bpm.textColor = UIColor(named: "TextColor")
            bpm.text = "\(engine.state.bpm)"
            bpm.textAlignment = .center
        }
        
        // Setup MS Label
        if let ms = msLabel {
            ms.font = UIFont(name: "Rubik-Bold", size: 22) ?? UIFont.boldSystemFont(ofSize: 22)
            ms.textColor = UIColor(named: "TextColor")
            ms.text = "\(engine.state.ms)"
            ms.textAlignment = .center
        }
        
        // Setup TopSliderBar
        if let topSlider = topSliderBar {
            topSlider.setProgress(engine.state.progress)
            
            topSlider.onProgressChanged = { [weak self] progress, bpm in
                guard let self = self else { return }
                self.bpmLabel?.text = "\(bpm)"
                let ms = Int(round(60000.0 / Double(max(1, bpm))))
                self.msLabel?.text = "\(ms)"
                self.engine.setProgress(progress)
            }
            
            topSlider.onCenterButtonTapped = { [weak self] in
                self?.engine.toggle()
            }
        }
        
        // Setup BottomSliderBar
        if let bottomSlider = bottomSliderBar {
            bottomSlider.setMode(engine.state.mode, animated: false)
            
            bottomSlider.onModeSelected = { [weak self] mode in
                self?.engine.setMode(mode)
            }
        }
        
        // Engine Delegate
        engine.delegate = self
        
        // Setup Flash Overlay (Synchronized full-screen flash)
        setupFlashOverlay()
        
        // Simulator visual indicators
        setupSimulatorIndicators()
        
        // Setup Ad Banner
        setupAdBanner()
        
        // Setup Review Prompt
        setupReviewPrompt()
        
        // Setup Android-identical Splash Intro Animation
        setupSplashIntro()
        
        // Automated UI test support
        if CommandLine.arguments.contains("-UITestStartPlaying") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.45) { [weak self] in
                self?.engine.start()
            }
        }
        if CommandLine.arguments.contains("-UITestTriggerRateNow") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.45) {
                ReviewManager.shared.rateNow()
            }
        }
        if CommandLine.arguments.contains("-UITestModeFlash") {
            engine.setMode(.flash)
            bottomSliderBar?.setMode(.flash, animated: false)
        } else if CommandLine.arguments.contains("-UITestModePulse") {
            engine.setMode(.pulse)
            bottomSliderBar?.setMode(.pulse, animated: false)
        }
    }
    
    private func setupAdBanner() {
        guard !AdBannerContainerView.shouldDisableAds else {
            print("[ViewController] Ads disabled for screenshots / UI testing.")
            return
        }
        
        adBannerContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(adBannerContainer)
        
        NSLayoutConstraint.activate([
            adBannerContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            adBannerContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            adBannerContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
        
        adBannerContainer.loadAd(rootViewController: self)
    }
    
    private func setupReviewPrompt() {
        ReviewManager.shared.onShowDialog = { [weak self] in
            self?.presentReviewDialog()
        }
        ReviewManager.shared.onDismissDialog = { [weak self] in
            self?.dismissReviewDialog()
        }
        ReviewManager.shared.checkReviewTrigger()
    }
    
    private func presentReviewDialog() {
        guard reviewController == nil else { return }
        let dialogView = ReviewDialogView(
            onRateNow: { [weak self] in
                ReviewManager.shared.rateNow()
                self?.dismissReviewDialog()
            },
            onLater: { [weak self] in
                ReviewManager.shared.dismiss()
                self?.dismissReviewDialog()
            }
        )
        let hostingController = UIHostingController(rootView: dialogView)
        hostingController.modalPresentationStyle = .overFullScreen
        hostingController.modalTransitionStyle = .crossDissolve
        hostingController.view.backgroundColor = .clear
        reviewController = hostingController
        present(hostingController, animated: true)
    }
    
    private func dismissReviewDialog() {
        reviewController?.dismiss(animated: true) { [weak self] in
            self?.reviewController = nil
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        var output = "=== DEBUG VIEW HIERARCHY ===\n"
        dumpViews(view, indent: 0, output: &output)
        output += "=== END VIEW HIERARCHY ===\n"
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("view_dump.txt")
        try? output.write(to: url, atomically: true, encoding: .utf8)
        NSLog("View dump saved to %@", url.path)
    }
    
    private func dumpViews(_ view: UIView, indent: Int, output: inout String) {
        let prefix = String(repeating: "  ", count: indent)
        let alphaStr = String(format: "%.2f", view.alpha)
        let hiddenStr = view.isHidden ? " hidden" : ""
        let shadowStr = view.layer.shadowOpacity > 0 ? " shadowOpacity=\(view.layer.shadowOpacity)" : ""
        let layerShadowStr = (view.layer.sublayers?.contains(where: { $0.shadowOpacity > 0 }) ?? false) ? " sublayerShadow" : ""
        let imgStr: String
        if let iv = view as? UIImageView, let name = iv.image?.accessibilityIdentifier ?? iv.accessibilityLabel {
            imgStr = " img=\(name)"
        } else {
            imgStr = ""
        }
        output += "\(prefix)\(type(of: view)) frame=\(view.frame) alpha=\(alphaStr)\(hiddenStr)\(shadowStr)\(layerShadowStr)\(imgStr)\n"
        for sub in view.subviews {
            dumpViews(sub, indent: indent + 1, output: &output)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return traitCollection.userInterfaceStyle == .dark ? .lightContent : .darkContent
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    // MARK: - MetronomeEngineDelegate
    
    func metronomeEngineStateDidChange(state: HomeState) {
        topSliderBar?.setPlaying(state.isPlaying)
        bottomSliderBar?.setPlaying(state.isPlaying)
        flashOverlay.setPlaying(state.isPlaying, mode: state.mode)
    }
    
    func metronomeEngineDidTick(state: HomeState) {
        if state.flashBlink {
            view.bringSubviewToFront(flashOverlay)
            flashOverlay.blink()
        }
    }
    
    // MARK: - Flash Overlay
    
    private func setupFlashOverlay() {
        flashOverlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(flashOverlay)
        NSLayoutConstraint.activate([
            flashOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            flashOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            flashOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            flashOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Simulator Emulation Support
    
    private func setupSimulatorIndicators() {
        hapticsEngine.onVibrateSimulated = { [weak self] in
            guard let self = self, self.engine.state.isPlaying, self.engine.state.mode == .pulse else { return }
            guard let container = self.topSliderBar else { return }
            UIView.animate(withDuration: 0.05, animations: {
                container.transform = CGAffineTransform(scaleX: 1.03, y: 1.03)
            }) { _ in
                UIView.animate(withDuration: 0.08) {
                    container.transform = .identity
                }
            }
        }
    }
    
    // MARK: - Splash Intro Animation (Android match)
    
    private func setupSplashIntro() {
        guard !isUITesting else {
            vignetteImageView?.isHidden = false
            vignetteImageView?.alpha = 1.0
            controlsContainer?.transform = .identity
            topSliderBar?.showTooltip(autoDismiss: true)
            return
        }
        
        // Hide tooltip on launch until controls finish entering
        topSliderBar?.hideTooltipImmediately()
        
        // Hide ad banner initially so splash is completely clean
        adBannerContainer.alpha = 0.0
        
        // Position controls offscreen to the right (matching Android app:layout_constraintStart_toEndOf="parent")
        let screenWidth = UIScreen.main.bounds.width
        controlsContainer.transform = CGAffineTransform(translationX: screenWidth, y: 0)
        
        let introView = SplashIntroView()
        introView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(introView, belowSubview: flashOverlay)
        
        NSLayoutConstraint.activate([
            introView.topAnchor.constraint(equalTo: view.topAnchor),
            introView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            introView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            introView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        splashIntroView = introView
        introView.onTapToSkip = { [weak self] in
            self?.fastForwardSplashIntro()
        }
        
        // Schedule animations matching Android timing:
        // 1. Initial 2000ms hold (SplashViewModel.splashOn)
        // 2. At 2000ms: metro & nome exit left (duration 1500ms, tension 1.5 & 1.0), vignette fades in (800ms)
        // 3. At 4500ms (2000ms + 2500ms startDelay): controls enters from right (duration 2000ms, tension 1.0)
        // 4. At 6500ms: controls settles, tooltip shown (setTooltip(true))
        
        let workItem1 = DispatchWorkItem { [weak self] in
            guard let self = self, let intro = self.splashIntroView else { return }
            let exitDistance = max(self.view.bounds.width, self.view.bounds.height) + 100
            intro.animateLogosExit(exitDistance: exitDistance, duration: 1.5)
            UIView.animate(withDuration: 0.8) {
                self.vignetteImageView?.alpha = 1.0
            }
        }
        
        let workItem2 = DispatchWorkItem { [weak self] in
            guard let self = self, let controls = self.controlsContainer else { return }
            let anim = AndroidInterpolator.createTranslationXAnimation(
                from: self.view.bounds.width,
                to: 0,
                duration: 2.0,
                tension: 1.0
            )
            controls.layer.add(anim, forKey: "controlsSlideIn")
            UIView.animate(withDuration: 0.5) {
                self.adBannerContainer.alpha = 1.0
            }
        }
        
        let workItem3 = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.controlsContainer?.layer.removeAnimation(forKey: "controlsSlideIn")
            self.controlsContainer?.transform = .identity
            self.splashIntroView?.removeFromSuperview()
            self.splashIntroView = nil
            self.topSliderBar?.showTooltip(autoDismiss: true)
        }
        
        splashWorkItems = [workItem1, workItem2, workItem3]
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: workItem1)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5, execute: workItem2)
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.5, execute: workItem3)
    }
    
    private func fastForwardSplashIntro() {
        for item in splashWorkItems {
            item.cancel()
        }
        splashWorkItems.removeAll()
        
        splashIntroView?.layer.removeAllAnimations()
        splashIntroView?.removeFromSuperview()
        splashIntroView = nil
        
        vignetteImageView?.isHidden = false
        vignetteImageView?.alpha = 1.0
        adBannerContainer.alpha = 1.0
        
        controlsContainer?.layer.removeAllAnimations()
        controlsContainer?.transform = .identity
        
        topSliderBar?.showTooltip(autoDismiss: true)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        flashOverlay.reset()
    }
}

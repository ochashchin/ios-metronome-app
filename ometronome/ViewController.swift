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
    
    // Simulator visual indicator for flash
    private var simulatorFlashOverlay: UIView?
    
    // Ad Banner & Review Dialog
    private let adBannerContainer = AdBannerContainerView()
    private var reviewController: UIHostingController<ReviewDialogView>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(named: "BackgroundColor")
        
        // Android controls screen uses flat background color without vignette
        vignetteImageView?.isHidden = true
        
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
        
        // Simulator visual indicators
        setupSimulatorIndicators()
        
        // Setup Ad Banner
        setupAdBanner()
        
        // Setup Review Prompt
        setupReviewPrompt()
        
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
    }
    
    func metronomeEngineDidTick(state: HomeState) {
        // Can add subtle visual pulse if needed
    }
    
    // MARK: - Simulator Emulation Support
    
    private func setupSimulatorIndicators() {
        // Flash overlay for simulator verification
        let overlay = UIView(frame: view.bounds)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.backgroundColor = .white
        overlay.alpha = 0
        overlay.isUserInteractionEnabled = false
        view.addSubview(overlay)
        simulatorFlashOverlay = overlay
        
        flashController.onBlinkSimulated = { [weak self] in
            guard let self = self, self.engine.state.isPlaying, self.engine.state.mode == .flash else { return }
            UIView.animate(withDuration: 0.03, animations: {
                self.simulatorFlashOverlay?.alpha = 0.8
            }) { _ in
                UIView.animate(withDuration: 0.05) {
                    self.simulatorFlashOverlay?.alpha = 0
                }
            }
        }
        
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
}

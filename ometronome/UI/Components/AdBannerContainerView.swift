//
//  AdBannerContainerView.swift
//  ometronome
//
//

import UIKit
import GoogleMobileAds

public class AdBannerContainerView: UIView, BannerViewDelegate {
    
    /// Global toggle to disable ads for App Store screenshots / UI testing
    public static var isAdsDisabledForScreenshots: Bool = false
    
    /// Returns true if ads should be suppressed (via flag, launch argument, or UserDefaults)
    public static var shouldDisableAds: Bool {
        if isAdsDisabledForScreenshots { return true }
        if CommandLine.arguments.contains("-DisableAds") ||
           CommandLine.arguments.contains("-Screenshots") ||
           CommandLine.arguments.contains("-FASTLANE_SNAPSHOT") {
            return true
        }
        if UserDefaults.standard.bool(forKey: "disable_ads") ||
           UserDefaults.standard.bool(forKey: "disable_ads_for_screenshots") {
            return true
        }
        return false
    }
    
    public private(set) var bannerView: BannerView?
    private let cardView = UIView()
    private var isAdLoaded = false
    
    // Production Ad Unit ID (always used, including on simulators)
    private let adUnitID = "ca-app-pub-2874567203173670/1118749785"

    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .clear
        
        // CardView matching Android fragment_ad.xml
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.layer.cornerRadius = 12
        cardView.layer.masksToBounds = true
        cardView.clipsToBounds = true
        if #available(iOS 13.0, *) {
            cardView.layer.cornerCurve = .continuous
        }
        cardView.backgroundColor = UIColor(named: "BackgroundColor")
        cardView.alpha = 0.0 // Starts invisible, animates on load
        addSubview(cardView)
        
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            cardView.centerXAnchor.constraint(equalTo: centerXAnchor),
            cardView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        applyCornerRadius()
    }
    
    private func applyCornerRadius() {
        cardView.layer.cornerRadius = 12
        cardView.layer.masksToBounds = true
        cardView.clipsToBounds = true
        if #available(iOS 13.0, *) {
            cardView.layer.cornerCurve = .continuous
        }
        if let banner = bannerView {
            banner.layer.cornerRadius = 12
            banner.layer.masksToBounds = true
            banner.clipsToBounds = true
            if #available(iOS 13.0, *) {
                banner.layer.cornerCurve = .continuous
            }
            banner.subviews.forEach { subview in
                subview.layer.cornerRadius = 12
                subview.layer.masksToBounds = true
                subview.clipsToBounds = true
                if #available(iOS 13.0, *) {
                    subview.layer.cornerCurve = .continuous
                }
            }
        }
    }
    
    public func loadAd(rootViewController: UIViewController) {
        guard !Self.shouldDisableAds else {
            print("[AdBanner] Ads disabled for screenshots / testing.")
            return
        }
        
        let viewWidth: CGFloat
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            viewWidth = window.frame.inset(by: window.safeAreaInsets).width
        } else {
            viewWidth = rootViewController.view.bounds.width
        }
        
        // Match Android getAdSize(): deduct standard horizontal padding (16dp left + 16dp right)
        let adWidth = max(0, viewWidth - 32)
        guard adWidth > 0 else { return }
        
        let adaptiveSize = currentOrientationAnchoredAdaptiveBanner(width: adWidth)
        
        if bannerView == nil {
            let banner = BannerView(adSize: adaptiveSize)
            banner.translatesAutoresizingMaskIntoConstraints = false
            banner.layer.cornerRadius = 12
            banner.layer.masksToBounds = true
            banner.clipsToBounds = true
            if #available(iOS 13.0, *) {
                banner.layer.cornerCurve = .continuous
            }
            banner.adUnitID = adUnitID
            banner.rootViewController = rootViewController
            banner.delegate = self
            cardView.addSubview(banner)
            
            NSLayoutConstraint.activate([
                banner.topAnchor.constraint(equalTo: cardView.topAnchor),
                banner.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
                banner.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
                banner.bottomAnchor.constraint(equalTo: cardView.bottomAnchor)
            ])
            self.bannerView = banner
        } else {
            bannerView?.adSize = adaptiveSize
        }
        
        let request = Request()
        bannerView?.load(request)
    }
    
    // MARK: - BannerViewDelegate
    
    public func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        isAdLoaded = true
        applyCornerRadius()
        // Animate alpha to 1.0 with 1000ms duration, matching Android's animate(true)
        UIView.animate(withDuration: 1.0) {
            self.cardView.alpha = 1.0
        }
    }
    
    public func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        print("AdBannerView failed to receive ad: \(error.localizedDescription)")
    }
}

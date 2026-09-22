//
//  ReviewDialogView.swift
//  ometronome
//
//

import SwiftUI
import StoreKit

public struct ReviewDialogView: View {
    let onRateNow: () -> Void
    let onLater: () -> Void
    
    public init(onRateNow: @escaping () -> Void, onLater: @escaping () -> Void) {
        self.onRateNow = onRateNow
        self.onLater = onLater
    }
    
    public var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    onLater()
                }
            
            VStack(spacing: 0) {
                // Trending Icon matching Android @drawable/trending_up
                Image("trending_up")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .foregroundColor(Color("DialogBodyColor"))
                    .opacity(0.9)
                    .padding(.top, 24)
                
                // Header text matching @string/dialog_head
                Text(NSLocalizedString("dialog_head", comment: "Please rate us!"))
                    .font(.custom("Rubik-Regular", size: 24))
                    .foregroundColor(Color("DialogHeadColor"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 18)
                
                // Body text matching @string/dialog_body
                Text(NSLocalizedString("dialog_body", comment: "Feedback text"))
                    .font(.custom("Rubik-Regular", size: 15))
                    .foregroundColor(Color("DialogBodyColor"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 28)
                
                // Action Buttons matching Android fragment_dialog.xml
                HStack(spacing: 12) {
                    Spacer()
                    
                    Button(action: onLater) {
                        Text(NSLocalizedString("dialog_cancel", comment: "Later"))
                            .font(.custom("Rubik-Medium", size: 16))
                            .foregroundColor(Color("DialogButtonColor"))
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                    }
                    
                    // Focused "Rate Now" button with pill container background
                    Button(action: onRateNow) {
                        Text(NSLocalizedString("dialog_ok", comment: "Rate Now"))
                            .font(.custom("Rubik-Medium", size: 16))
                            .foregroundColor(Color("DialogButtonColor"))
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color("DialogButtonColor").opacity(0.18))
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .frame(maxWidth: 330)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color("BackgroundColor"))
                    .shadow(color: Color.black.opacity(0.22), radius: 24, x: 0, y: 10)
            )
            .padding(.horizontal, 24)
        }
    }
}

public final class ReviewManager: ObservableObject {
    public static let shared = ReviewManager()
    private let key = "review"
    private let targetCount = 3
    // 4. Review Prompt Dialog triggers 1000ms after Ads (4.45s total from app launch)
    private let dialogDelay = 4.45
    
    @Published public var shouldShowDialog = false
    public var onShowDialog: (() -> Void)?
    public var onDismissDialog: (() -> Void)?
    
    public init() {}
    
    public func logAppLaunch() {
        checkReviewTrigger()
    }
    
    public func checkReviewTrigger() {
        if CommandLine.arguments.contains("-UITestShowReviewDialog") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.45) { [weak self] in
                self?.shouldShowDialog = true
                self?.onShowDialog?()
            }
            return
        }
        
        let prefs = UserDefaults.standard
        let currentCount = prefs.object(forKey: key) != nil ? prefs.integer(forKey: key) : 1
        
        if currentCount < targetCount {
            prefs.set(currentCount + 1, forKey: key)
        } else if currentCount == targetCount {
            prefs.set(currentCount + 1, forKey: key)
            DispatchQueue.main.asyncAfter(deadline: .now() + dialogDelay) { [weak self] in
                self?.shouldShowDialog = true
                self?.onShowDialog?()
            }
        }
    }
    
    public func rateNow() {
        shouldShowDialog = false
        onDismissDialog?()
        UserDefaults.standard.set(targetCount + 1, forKey: key)
        let appID = "1665225967"
        
        #if targetEnvironment(simulator)
        // iOS Simulator does not have the App Store app installed.
        // Opening App Store URLs in Simulator causes Safari to fail with:
        // "Safari cannot open the page because the address is invalid."
        // We trigger StoreKit in-app review instead so it tests cleanly on simulator.
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.45) {
            if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                SKStoreReviewController.requestReview(in: windowScene)
            }
        }
        #else
        // On physical iOS devices:
        // 1. Direct App Store deep-link to write-review screen (bypasses Safari)
        if let url = URL(string: "itms-apps://itunes.apple.com/app/id\(appID)?action=write-review"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else if let url = URL(string: "https://apps.apple.com/app/id\(appID)?action=write-review") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        #endif
    }
    
    public func dismiss() {
        shouldShowDialog = false
        onDismissDialog?()
        UserDefaults.standard.set(targetCount + 1, forKey: key)
    }
}

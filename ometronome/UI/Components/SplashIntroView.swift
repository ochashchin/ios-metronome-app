//
//  SplashIntroView.swift
//  ometronome
//
//  Android-matching intro splash animation
//

import UIKit

public enum AndroidInterpolator {
    /// Android's AnticipateOvershootInterpolator(tension)
    /// In Android AOSP:
    /// public AnticipateOvershootInterpolator(float tension) {
    ///     mTension = tension * 1.5f;
    /// }
    /// a(t, s) = t * t * ((s + 1) * t - s)
    /// o(t, s) = t * t * ((s + 1) * t + s)
    /// f(t) = 0.5 * a(t * 2, mTension), when t < 0.5
    /// f(t) = 0.5 * (o(t * 2 - 2, mTension) + 2), when t <= 1.0
    public static func anticipateOvershoot(t: CGFloat, tension: CGFloat) -> CGFloat {
        let s = tension * 1.5
        func a(_ t: CGFloat, _ s: CGFloat) -> CGFloat {
            return t * t * ((s + 1.0) * t - s)
        }
        func o(_ t: CGFloat, _ s: CGFloat) -> CGFloat {
            return t * t * ((s + 1.0) * t + s)
        }
        if t < 0.5 {
            return 0.5 * a(t * 2.0, s)
        } else {
            return 0.5 * (o(t * 2.0 - 2.0, s) + 2.0)
        }
    }
    
    public static func createTranslationXAnimation(
        from: CGFloat,
        to: CGFloat,
        duration: TimeInterval,
        tension: CGFloat,
        sampleCount: Int = 120
    ) -> CAKeyframeAnimation {
        var values: [CGFloat] = []
        var keyTimes: [NSNumber] = []
        
        for i in 0...sampleCount {
            let t = CGFloat(i) / CGFloat(sampleCount)
            let interp = anticipateOvershoot(t: t, tension: tension)
            let val = from + (to - from) * interp
            values.append(val)
            keyTimes.append(NSNumber(value: Double(t)))
        }
        
        let anim = CAKeyframeAnimation(keyPath: "transform.translation.x")
        anim.values = values
        anim.keyTimes = keyTimes
        anim.duration = duration
        anim.fillMode = .forwards
        anim.isRemovedOnCompletion = false
        return anim
    }
}

public final class SplashIntroView: UIView {
    
    public let colView = UIView()
    public let metroImageView = UIImageView()
    public let nomeImageView = UIImageView()
    public let centreView = UIView()
    
    public var onTapToSkip: (() -> Void)?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        backgroundColor = .clear
        isUserInteractionEnabled = true
        
        // Col container
        colView.translatesAutoresizingMaskIntoConstraints = false
        colView.backgroundColor = .clear
        addSubview(colView)
        
        // Metro image view
        metroImageView.translatesAutoresizingMaskIntoConstraints = false
        metroImageView.image = UIImage(named: "metro_")
        metroImageView.contentMode = .scaleAspectFit
        metroImageView.clipsToBounds = true
        colView.addSubview(metroImageView)
        
        // Nome image view
        nomeImageView.translatesAutoresizingMaskIntoConstraints = false
        nomeImageView.image = UIImage(named: "nome_")
        nomeImageView.contentMode = .scaleAspectFit
        nomeImageView.clipsToBounds = true
        colView.addSubview(nomeImageView)
        
        // Centre spacer view (matches LaunchScreen.storyboard exactly)
        centreView.translatesAutoresizingMaskIntoConstraints = false
        centreView.backgroundColor = .clear
        centreView.isUserInteractionEnabled = false
        colView.addSubview(centreView)
        
        let colWidthPref = colView.widthAnchor.constraint(equalTo: widthAnchor)
        colWidthPref.priority = UILayoutPriority(750)
        
        NSLayoutConstraint.activate([
            // Col container layout
            colView.topAnchor.constraint(equalTo: topAnchor),
            colView.bottomAnchor.constraint(equalTo: bottomAnchor),
            colView.centerXAnchor.constraint(equalTo: centerXAnchor),
            colView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            colView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            colView.widthAnchor.constraint(lessThanOrEqualToConstant: 420),
            colWidthPref,
            
            // Metro logo
            metroImageView.leadingAnchor.constraint(equalTo: colView.leadingAnchor, constant: 20),
            metroImageView.trailingAnchor.constraint(equalTo: colView.trailingAnchor, constant: -20),
            metroImageView.widthAnchor.constraint(equalTo: metroImageView.heightAnchor, multiplier: 1586.0 / 746.0),
            
            // Centre spacer: centerY in colView, height ratio 1586:373, bottom aligns with metro.bottom
            centreView.centerYAnchor.constraint(equalTo: colView.centerYAnchor),
            centreView.leadingAnchor.constraint(equalTo: metroImageView.leadingAnchor),
            centreView.trailingAnchor.constraint(equalTo: metroImageView.trailingAnchor),
            centreView.widthAnchor.constraint(equalTo: centreView.heightAnchor, multiplier: 1586.0 / 373.0),
            centreView.bottomAnchor.constraint(equalTo: metroImageView.bottomAnchor),
            
            // Nome logo: top aligns with centre.top
            nomeImageView.leadingAnchor.constraint(equalTo: colView.leadingAnchor, constant: 20),
            nomeImageView.trailingAnchor.constraint(equalTo: colView.trailingAnchor, constant: -20),
            nomeImageView.widthAnchor.constraint(equalTo: nomeImageView.heightAnchor, multiplier: 1586.0 / 746.0),
            nomeImageView.topAnchor.constraint(equalTo: centreView.topAnchor)
        ])
        
        // Tap to skip
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }
    
    @objc private func handleTap() {
        onTapToSkip?()
    }
    
    /// Animates metro and nome exiting offscreen to the left with AnticipateOvershootInterpolator
    /// - metro uses tension 1.5 (winds up to the right more)
    /// - nome uses tension 1.0 (winds up to the right less)
    public func animateLogosExit(exitDistance: CGFloat, duration: TimeInterval = 1.5, completion: (() -> Void)? = nil) {
        let metroAnim = AndroidInterpolator.createTranslationXAnimation(
            from: 0,
            to: -exitDistance,
            duration: duration,
            tension: 1.5
        )
        
        let nomeAnim = AndroidInterpolator.createTranslationXAnimation(
            from: 0,
            to: -exitDistance,
            duration: duration,
            tension: 1.0
        )
        
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            completion?()
        }
        metroImageView.layer.add(metroAnim, forKey: "metroExit")
        nomeImageView.layer.add(nomeAnim, forKey: "nomeExit")
        CATransaction.commit()
    }
}

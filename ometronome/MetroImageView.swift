//
//  MetroImageView.swift
//  ometronome
//
//  Created by Administrator on 12/20/22.
//

import UIKit

class MetroImageView: UIView {
                        
    private weak var imageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        
        imageView.leadingAnchor.constraint(equalTo:leadingAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo:trailingAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        imageView.image = UIImage(systemName:"metro_")
        imageView.contentMode = .scaleAspectFit
        self.imageView = imageView
        backgroundColor = UIColor.clear
    }
}

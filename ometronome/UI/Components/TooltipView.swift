//
//  TooltipView.swift
//  ometronome
//

import SwiftUI

public struct TooltipView: View {
    let text: String
    let onDismiss: () -> Void
    
    public init(text: String = NSLocalizedString("press_to_start", comment: ""), onDismiss: @escaping () -> Void) {
        self.text = text
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        HStack(spacing: 6) {
            Text(text)
                .font(.custom("Rubik-Regular", size: 14))
                .foregroundColor(Color.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.14, opacity: 0.92))
                .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 3)
        )
        .overlay(
            // Downward pointing pointer triangle
            GeometryReader { _ in
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: 10, y: 8))
                    path.addLine(to: CGPoint(x: 20, y: 0))
                    path.closeSubpath()
                }
                .fill(Color(red: 0.12, green: 0.12, blue: 0.14, opacity: 0.92))
                .frame(width: 20, height: 8)
                .offset(y: 32)
            }
            .frame(width: 20, height: 8),
            alignment: .bottom
        )
        .onTapGesture {
            onDismiss()
        }
    }
}

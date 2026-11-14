//
//  Extension.swift
//  PerData
//
//  Created by Jan Hovland on 14/10/2024.
//

import SwiftUI

extension UIDevice {
  
  static var idiom: UIUserInterfaceIdiom {
    UIDevice.current.userInterfaceIdiom
  }
  
  static var isIpad: Bool {
    idiom == .pad
  }
  
  static var isiPhone: Bool {
    idiom == .phone
  }
}

struct GradientGlassRoundedModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    var lineWidth: CGFloat = 0.25
    var material: Material = .ultraThinMaterial
    var gradient: LinearGradient = .init(
        colors: [.white.opacity(0.6), .blue.opacity(0.4), .purple.opacity(0.3)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(material)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(gradient, lineWidth: lineWidth)
            )
            .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 8)
    }
}

extension View {
    func gradientGlass(
        cornerRadius: CGFloat = 20,
        lineWidth: CGFloat = 0.75,
        material: Material = .ultraThinMaterial,
        gradient: LinearGradient? = nil
    ) -> some View {
        let defaultGradient = LinearGradient(
            colors: [.white.opacity(0.50), .gray.opacity(0.25)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        return modifier(
            GradientGlassRoundedModifier(
                cornerRadius: cornerRadius,
                lineWidth: lineWidth,
                material: material,
                gradient: gradient ?? defaultGradient
            )
        )
    }
}

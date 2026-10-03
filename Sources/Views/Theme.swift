import DevBarCore
import SwiftUI

public enum Theme {
    // Elegant Dark Theme Palette
    public static let bgMain = Color(nsColor: NSColor(calibratedRed: 0.08, green: 0.08, blue: 0.11, alpha: 0.95))
    public static let bgCard = Color(nsColor: NSColor(calibratedRed: 0.14, green: 0.14, blue: 0.20, alpha: 0.50))
    public static let bgInput = Color(nsColor: NSColor(calibratedRed: 0.05, green: 0.05, blue: 0.07, alpha: 0.60))

    // Curated accent colors
    public static let textPrimary = Color.white
    public static let textSecondary = Color(nsColor: NSColor(calibratedWhite: 0.70, alpha: 1.0))
    public static let textMuted = Color(nsColor: NSColor(calibratedWhite: 0.45, alpha: 1.0))

    public static let activeGreen = Color(nsColor: NSColor(calibratedRed: 0.20, green: 0.85, blue: 0.50, alpha: 1.0))
    public static let bootingOrange = Color(nsColor: NSColor(calibratedRed: 0.95, green: 0.60, blue: 0.20, alpha: 1.0))
    public static let shutdownGray = Color(nsColor: NSColor(calibratedWhite: 0.50, alpha: 1.0))

    // Harmony gradients
    public static let iosGradient = LinearGradient(
        colors: [Color(nsColor: NSColor(calibratedRed: 0.92, green: 0.18, blue: 0.45, alpha: 1.0)),
                 Color(nsColor: NSColor(calibratedRed: 0.55, green: 0.20, blue: 0.90, alpha: 1.0))],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let androidGradient = LinearGradient(
        colors: [Color(nsColor: NSColor(calibratedRed: 0.22, green: 0.78, blue: 0.40, alpha: 1.0)),
                 Color(nsColor: NSColor(calibratedRed: 0.10, green: 0.55, blue: 0.85, alpha: 1.0))],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let mainAccentGradient = LinearGradient(
        colors: [Color(nsColor: NSColor(calibratedRed: 0.15, green: 0.45, blue: 0.95, alpha: 1.0)),
                 Color(nsColor: NSColor(calibratedRed: 0.05, green: 0.25, blue: 0.80, alpha: 1.0))],
        startPoint: .top,
        endPoint: .bottom
    )

    public static let cardBorder = LinearGradient(
        colors: [Color.white.opacity(0.12), Color.white.opacity(0.04)],
        startPoint: .top,
        endPoint: .bottom
    )
}

// Custom Glassmorphic Modifier
struct GlassmorphicModifier: ViewModifier {
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Theme.bgCard)
            )
            .background(
                VisualEffectView(material: .hudWindow, blendingMode: .withinWindow)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Theme.cardBorder, lineWidth: 1.0)
            )
            .shadow(color: Color.black.opacity(0.25), radius: 6.0, x: 0, y: 3)
    }
}

extension View {
    public func glassmorphic(cornerRadius: CGFloat = 12.0) -> some View {
        self.modifier(GlassmorphicModifier(cornerRadius: cornerRadius))
    }
}

// macOS Visual Effect View helper for native SwiftUI blurred materials
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// Custom Premium Hover & Press Buttons
public struct PremiumButtonStyle: ButtonStyle {
    var accentGradient: LinearGradient? = nil
    var isCircular: Bool = false

    @State private var isHovered = false

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .background(
                Group {
                    if let gradient = accentGradient {
                        RoundedRectangle(cornerRadius: isCircular ? 100 : 8)
                            .fill(gradient)
                            .brightness(isHovered ? 0.08 : 0)
                            .opacity(configuration.isPressed ? 0.85 : 1.0)
                    } else {
                        RoundedRectangle(cornerRadius: isCircular ? 100 : 8)
                            .fill(Color.white.opacity(isHovered ? 0.12 : 0.06))
                            .opacity(configuration.isPressed ? 0.7 : 1.0)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: isCircular ? 100 : 8)
                    .stroke(Color.white.opacity(isHovered ? 0.18 : 0.08), lineWidth: 1.0)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : (isHovered ? 1.02 : 1.0))
            .animation(.spring(response: 0.25, dampingFraction: 0.6, blendDuration: 0), value: isHovered)
            .animation(.interactiveSpring(), value: configuration.isPressed)
            .onHover { hover in
                isHovered = hover
            }
    }
}

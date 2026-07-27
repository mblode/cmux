import AppKit
import SwiftUI

/// The leading agent-status glyph on a sidebar workspace row.
///
/// Shape carries the meaning; colour only reinforces it. Every state is a
/// different silhouette inside an identical circular box, so the sidebar stays
/// readable at 100% greyscale (WCAG 1.4.1) and survives a colourblind palette
/// swap without restructuring. This replaced a set of five recoloured dots.
///
/// Motion policy: `needsAttention` is the only animated element in the sidebar.
/// That inverts the usual convention — Claude Code, Conductor and Linear animate
/// the *ambient working* state and keep blocking states loud but still — and is
/// a deliberate product decision, not an oversight. `working` renders a static
/// wedge; do not add a spinner to it.
struct SidebarAgentStatusGlyph: View {
    let state: SidebarAgentStatusState
    let metrics: SidebarAgentStatusGlyphMetrics
    let color: NSColor
    let label: String

    var body: some View {
        content
            .frame(width: metrics.side, height: metrics.side)
            .fixedSize()
            .safeHelp(label)
            .accessibilityLabel(label)
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .needsAttention:
            GPUSpinner(
                style: .attentionPulse(symbolName: "exclamationmark.circle.fill"),
                color: color
            )
        case .error:
            symbol("xmark.circle.fill")
        case .done:
            symbol("checkmark.circle.fill")
        case .working:
            SidebarAgentWorkingWedge(lineWidth: metrics.side * 0.11)
                .foregroundColor(Color(nsColor: color))
        case .idle:
            symbol("circle.dashed")
        }
    }

    private func symbol(_ systemName: String) -> some View {
        CmuxSystemSymbolImage(
            magnified: systemName,
            pointSize: metrics.symbolPointSize,
            weight: .medium
        )
        .foregroundColor(Color(nsColor: color))
    }
}

/// Linear's in-progress glyph: a thin ring with an inset pie wedge. Reads as
/// "started but not finished" in pure greyscale, which a filled dot cannot, and
/// carries that meaning with no motion at all.
struct SidebarAgentWorkingWedge: View {
    let lineWidth: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(lineWidth: lineWidth)
            WedgeShape()
                .padding(lineWidth * 2)
        }
    }

    private struct WedgeShape: Shape {
        func path(in rect: CGRect) -> Path {
            let center = CGPoint(x: rect.midX, y: rect.midY)
            var path = Path()
            path.move(to: center)
            path.addArc(
                center: center,
                radius: min(rect.width, rect.height) / 2,
                startAngle: .degrees(-90),
                endAngle: .degrees(30),
                clockwise: false
            )
            path.closeSubpath()
            return path
        }
    }
}

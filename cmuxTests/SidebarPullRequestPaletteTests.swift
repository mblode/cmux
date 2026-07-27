import AppKit
import CmuxSidebar
import SwiftUI
import Testing
#if canImport(cmux_DEV)
@testable import cmux_DEV
#elseif canImport(cmux)
@testable import cmux
#endif

/// Pins the PR row to GitHub Primer's functional tokens.
///
/// These are not cmux's colours to taste-tune: users read this sidebar and
/// GitHub side by side, and green-open / purple-merged / red-closed / grey-draft
/// is vocabulary they already have. A well-meaning palette "harmonization" pass
/// would silently break that, so the exact hexes are asserted.
@Suite struct SidebarPullRequestPaletteTests {
    private static func hex(_ color: NSColor) -> String {
        guard let srgb = color.usingColorSpace(.sRGB) else { return "unconvertible" }
        return String(
            format: "#%02X%02X%02X",
            Int((srgb.redComponent * 255).rounded()),
            Int((srgb.greenComponent * 255).rounded()),
            Int((srgb.blueComponent * 255).rounded())
        )
    }

    private static func hex(_ presentation: SidebarPullRequestPresentation, _ scheme: ColorScheme) -> String {
        hex(SidebarPullRequestPalette.color(for: presentation, colorScheme: scheme))
    }

    @Test func lightSchemeMatchesPrimerTokens() {
        #expect(Self.hex(.draft, .light) == "#59636E", "--fgColor-draft")
        #expect(Self.hex(.open, .light) == "#1A7F37", "--fgColor-open")
        #expect(Self.hex(.merged, .light) == "#8250DF", "--fgColor-done")
        #expect(Self.hex(.closed, .light) == "#D1242F", "--fgColor-closed")
    }

    @Test func darkSchemeMatchesPrimerTokens() {
        #expect(Self.hex(.draft, .dark) == "#9198A1", "--fgColor-draft")
        #expect(Self.hex(.open, .dark) == "#3FB950", "--fgColor-open")
        #expect(Self.hex(.merged, .dark) == "#AB7DF8", "--fgColor-done")
        #expect(Self.hex(.closed, .dark) == "#F85149", "--fgColor-closed")
    }

    @Test func everyStateIsVisuallyDistinctWithinAScheme() {
        for scheme in [ColorScheme.light, .dark] {
            let hexes = SidebarPullRequestPresentation.allCases.map { Self.hex($0, scheme) }
            #expect(
                Set(hexes).count == hexes.count,
                "Two PR states sharing a colour in \(scheme) collapses the distinction — GitHub's own grey-means-draft-and-merged bug."
            )
        }
    }

    /// Shape must carry the state on its own, because colour cannot (WCAG 1.4.1)
    /// and because the same hex appears in both light and dark for no state.
    @Test func everyStateHasItsOwnGlyph() {
        let icons = SidebarPullRequestPresentation.allCases.map {
            SidebarPullRequestRowView.iconName($0)
        }
        #expect(Set(icons).count == icons.count)
        #expect(!icons.contains { $0.isEmpty })
    }

    @Test func everyStateHasALocalizedWordForTheTooltip() {
        for presentation in SidebarPullRequestPresentation.allCases {
            #expect(!SidebarPullRequestRowView.stateLabel(presentation).isEmpty)
        }
    }
}

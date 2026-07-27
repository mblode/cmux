import AppKit
import CmuxSidebar
import SwiftUI

/// GitHub Primer's functional foreground tokens for pull-request state.
///
/// Borrowed verbatim rather than re-derived from the cmux palette: every user
/// of this sidebar also reads GitHub, and green-open / purple-merged / red-closed
/// / grey-draft is vocabulary they already know. Reinventing it would cost a
/// teaching moment for no gain.
///
/// Values are `--fgColor-{draft,open,done,closed}` from
/// `@primer/primitives` `functional/themes/{light,dark}.css`.
enum SidebarPullRequestPalette {
    static func color(
        for presentation: SidebarPullRequestPresentation,
        colorScheme: ColorScheme
    ) -> NSColor {
        switch presentation {
        case .draft: return draft(colorScheme)
        case .open: return open(colorScheme)
        case .merged: return merged(colorScheme)
        case .closed: return closed(colorScheme)
        }
    }

    /// `--fgColor-draft` (alias of `--fgColor-neutral`).
    static func draft(_ scheme: ColorScheme) -> NSColor {
        scheme == .dark ? hex(0x91, 0x98, 0xA1) : hex(0x59, 0x63, 0x6E)
    }

    /// `--fgColor-open` (alias of `--fgColor-success`).
    static func open(_ scheme: ColorScheme) -> NSColor {
        scheme == .dark ? hex(0x3F, 0xB9, 0x50) : hex(0x1A, 0x7F, 0x37)
    }

    /// `--fgColor-done`.
    static func merged(_ scheme: ColorScheme) -> NSColor {
        scheme == .dark ? hex(0xAB, 0x7D, 0xF8) : hex(0x82, 0x50, 0xDF)
    }

    /// `--fgColor-closed` (alias of `--fgColor-danger`).
    static func closed(_ scheme: ColorScheme) -> NSColor {
        scheme == .dark ? hex(0xF8, 0x51, 0x49) : hex(0xD1, 0x24, 0x2F)
    }

    private static func hex(_ red: Int, _ green: Int, _ blue: Int) -> NSColor {
        NSColor(
            srgbRed: CGFloat(red) / 255,
            green: CGFloat(green) / 255,
            blue: CGFloat(blue) / 255,
            alpha: 1
        )
    }
}

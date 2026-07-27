import AppKit
import CmuxSidebar
import SwiftUI

/// One `⑂ #1234` row under a workspace in the sidebar.
///
/// Extracted from `TabItemView.body` so the PR axis has somewhere to live that
/// isn't a 600-line view body, and kept to value types plus a single closure so
/// it stays legal below the sidebar's `LazyVStack` (CLAUDE.md snapshot boundary).
///
/// Glyph and text hold `fontSize` in every state, so a PR transitioning from
/// open to merged can never change the row's height.
struct SidebarPullRequestRowView: View, Equatable {
    let number: Int
    let label: String
    let url: URL
    let presentation: SidebarPullRequestPresentation
    let isStale: Bool
    let isClickable: Bool
    let fontSize: CGFloat
    let font: Font
    let color: NSColor
    let openLink: (URL) -> Void

    nonisolated static func == (lhs: SidebarPullRequestRowView, rhs: SidebarPullRequestRowView) -> Bool {
        lhs.number == rhs.number &&
        lhs.label == rhs.label &&
        lhs.url == rhs.url &&
        lhs.presentation == rhs.presentation &&
        lhs.isStale == rhs.isStale &&
        lhs.isClickable == rhs.isClickable &&
        lhs.fontSize == rhs.fontSize &&
        lhs.color == rhs.color
    }

    private var tooltip: String {
        // "Open microsoft/vscode #1234 · Merged" — the state word lives here and
        // in the accessibility label rather than inline, so the row stays quiet
        // and the colour never has to carry the meaning alone (WCAG 1.4.1).
        let title = "\(label) #\(number)"
        let opening = String(localized: "sidebar.pullRequest.openTooltip", defaultValue: "Open \(title)")
        return "\(opening) · \(Self.stateLabel(presentation))"
    }

    static func stateLabel(_ presentation: SidebarPullRequestPresentation) -> String {
        switch presentation {
        case .draft:
            return String(localized: "sidebar.pullRequest.state.draft", defaultValue: "Draft")
        case .open:
            return String(localized: "sidebar.pullRequest.state.open", defaultValue: "Open")
        case .merged:
            return String(localized: "sidebar.pullRequest.state.merged", defaultValue: "Merged")
        case .closed:
            return String(localized: "sidebar.pullRequest.state.closed", defaultValue: "Closed")
        }
    }

    /// Distinct silhouettes, not one glyph in four colours: draft's dashed arm,
    /// merge's inbound curve and closed's ✕ all survive greyscale.
    static func iconName(_ presentation: SidebarPullRequestPresentation) -> String {
        switch presentation {
        case .draft: return "BlodeGitPullRequestDraft"
        case .open: return "BlodeGitPullRequest"
        case .merged: return "BlodeGitMerge"
        case .closed: return "BlodeGitPullRequestClosed"
        }
    }

    var body: some View {
        let foreground = Color(nsColor: color)
        let content = HStack(spacing: 5) {
            BlodeIconImage(name: Self.iconName(presentation), size: fontSize)
            Text("#\(String(number))").lineLimit(1).truncationMode(.tail)
            Spacer(minLength: 0)
        }
        .font(font)
        .foregroundColor(foreground)
        .opacity(isStale ? 0.5 : 1)

        if isClickable {
            Button(action: { openLink(url) }) { content }
                .buttonStyle(.plain)
                .cmuxHoverUnderline()
                .cmuxPointingHandCursor()
                .tint(foreground)
                .safeHelp(tooltip)
                .accessibilityLabel(tooltip)
                .accessibilityIdentifier("SidebarPullRequestRow")
        } else {
            content
                .accessibilityElement(children: .combine)
                .accessibilityLabel(tooltip)
                .accessibilityIdentifier("SidebarPullRequestRow")
        }
    }
}

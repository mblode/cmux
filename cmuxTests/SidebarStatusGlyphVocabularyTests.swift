import AppKit
import CmuxSidebar
import SwiftUI
import Testing
#if canImport(cmux_DEV)
@testable import cmux_DEV
#elseif canImport(cmux)
@testable import cmux
#endif

/// The sidebar's two glyph families must each be readable with no colour at all:
/// the PR row is deliberately monochrome, and the agent glyph drops its semantic
/// colour on a solid-fill selected row. Shape is therefore the only channel
/// guaranteed to be present, which is also what satisfies WCAG 1.4.1.
@Suite struct SidebarStatusGlyphVocabularyTests {
    @Test func everyPullRequestStateHasItsOwnSilhouette() {
        let icons = SidebarPullRequestPresentation.allCases.map {
            SidebarPullRequestRowView.iconName($0)
        }
        #expect(
            Set(icons).count == icons.count,
            "The PR row carries no colour, so two states sharing a glyph are indistinguishable."
        )
        #expect(!icons.contains { $0.isEmpty })
    }

    @Test func everyPullRequestStateHasALocalizedWordForTheTooltip() {
        for presentation in SidebarPullRequestPresentation.allCases {
            #expect(!SidebarPullRequestRowView.stateLabel(presentation).isEmpty)
        }
    }

    @Test func everyAgentStateHasALocalizedWordForTheTooltip() {
        for state in SidebarAgentStatusState.allCases {
            #expect(!state.localizedLabel.isEmpty)
        }
    }

    /// Colour is secondary but must still not collide, so a user who reads
    /// colour first is never told two different things by the same hue.
    @Test func agentStateColoursAreDistinctWithinEachScheme() {
        for scheme in [ColorScheme.light, .dark] {
            let colors = SidebarAgentStatusState.allCases.map {
                SidebarStatusStyle.color(for: $0, colorScheme: scheme)
            }
            #expect(Set(colors).count == colors.count, "Two agent states share a colour in \(scheme).")
        }
    }

    /// The inbox rule: a glyph exists to say "this row wants you". `working` is
    /// the sole exception and is rendered recessive to keep it from competing.
    @Test func workingIsTheOnlyNonActionableStateAndItIsRecessive() {
        #expect(SidebarAgentStatusGlyph.workingGlyphOpacity < 1)
        #expect(
            SidebarAgentStatusState.displayPriority.last == .done,
            "Done sits at the bottom of the ranking so live work always wins the glyph."
        )
    }
}

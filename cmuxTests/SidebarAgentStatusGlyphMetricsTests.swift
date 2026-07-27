import CoreGraphics
import Testing
#if canImport(cmux_DEV)
@testable import cmux_DEV
#elseif canImport(cmux)
@testable import cmux
#endif

@Suite struct SidebarAgentStatusGlyphMetricsTests {
    /// The whole point of the glyph family: every state occupies an identical
    /// box. A state-dependent footprint would change the row's height on an
    /// agent transition, and re-laying-out one row re-runs layout for the entire
    /// sidebar (issues #5764 / #5845).
    @Test(arguments: [0.5, 0.85, 1.0, 1.4, 2.0] as [CGFloat])
    func footprintIsIdenticalAcrossEveryStateAtEachFontScale(fontScale: CGFloat) {
        let baseline = SidebarAgentStatusGlyphMetrics.metrics(for: nil, fontScale: fontScale)

        for state in SidebarAgentStatusState.allCases {
            #expect(
                SidebarAgentStatusGlyphMetrics.metrics(for: state, fontScale: fontScale) == baseline,
                "\(state) has a different footprint from the empty slot, so transitioning into it would reflow the sidebar."
            )
        }
    }

    @Test func emptySlotReservesTheSameWidthAsAGlyph() {
        let empty = SidebarAgentStatusGlyphMetrics.metrics(for: nil, fontScale: 1)
        let working = SidebarAgentStatusGlyphMetrics.metrics(for: .working, fontScale: 1)
        #expect(
            empty.side == working.side,
            "A workspace with no agent must reserve the glyph's width so titles align and starting an agent does not re-truncate them."
        )
    }

    @Test func geometryScalesWithTheSidebarFontScale() {
        let single = SidebarAgentStatusGlyphMetrics(fontScale: 1)
        let double = SidebarAgentStatusGlyphMetrics(fontScale: 2)

        #expect(single.side == SidebarAgentStatusGlyphMetrics.baseSide)
        #expect(double.side == SidebarAgentStatusGlyphMetrics.baseSide * 2)
        #expect(double.topPadding == single.topPadding * 2)
        #expect(double.trailingPadding == single.trailingPadding * 2)
    }

    @Test func symbolPointSizeStaysInsideTheBox() {
        let metrics = SidebarAgentStatusGlyphMetrics(fontScale: 1)
        #expect(
            metrics.symbolPointSize < metrics.side,
            "Filled SF Symbols draw to their full point size; overshooting the frame clips the glyph."
        )
    }
}

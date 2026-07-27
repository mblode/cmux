import CoreGraphics

/// Geometry for the leading agent-status glyph.
///
/// Extracted as a value type so the state-independence contract below can be
/// asserted in a unit test without measuring a rendered `View`.
struct SidebarAgentStatusGlyphMetrics: Equatable {
    /// Unscaled glyph box. Sits between the 12pt title and the 9pt accessory
    /// glyphs so the shape stays legible without out-shouting the title.
    static let baseSide: CGFloat = 11

    /// Nudges the glyph down onto the title's cap height. The row's title is
    /// 12pt with `alignment: .top`, so a bare-aligned 11pt glyph reads high.
    static let baseTopPadding: CGFloat = 1.5

    static let baseTrailingPadding: CGFloat = 1

    let side: CGFloat
    let topPadding: CGFloat
    let trailingPadding: CGFloat

    /// Symbol point size. Slightly under `side` so the heavier `.fill` glyphs
    /// (`exclamationmark.circle.fill` and friends) don't bleed past the box and
    /// get clipped by the frame.
    var symbolPointSize: CGFloat { side * 0.95 }

    init(fontScale: CGFloat) {
        side = Self.baseSide * fontScale
        topPadding = Self.baseTopPadding * fontScale
        trailingPadding = Self.baseTrailingPadding * fontScale
    }

    /// The footprint is intentionally independent of `state`.
    ///
    /// This is a correctness requirement, not a style choice: a glyph whose box
    /// changes with the state would change the row's height when an agent
    /// transitions, and re-laying-out a row re-runs layout for the whole sidebar
    /// (issues #5764 / #5845). The exhaustive switch exists so that adding a
    /// state forces a decision here rather than silently inheriting a size.
    static func metrics(for state: SidebarAgentStatusState?, fontScale: CGFloat) -> Self {
        switch state {
        case .error, .needsAttention, .working, .idle, .done, nil:
            return Self(fontScale: fontScale)
        }
    }
}

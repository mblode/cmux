enum GPUSpinnerStyle: Equatable {
    /// The native macOS indeterminate look: static fading spokes, rotating ring.
    case macOSSpokes
    /// A single rotating arc.
    case arc
    /// A slow opacity breathe on a tinted SF Symbol, for the sidebar's
    /// needs-attention glyph. Opacity only — never scale or position, which
    /// would change the layer's visual bounds and invite someone to "fix" it by
    /// animating the SwiftUI frame instead (see the row-height constraint in
    /// `TabItemView`).
    case attentionPulse(symbolName: String)
}

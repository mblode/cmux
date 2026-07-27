import AppKit
import SwiftUI

/// A GPU-driven ambient indicator — an indeterminate spinner or a slow pulse.
/// The only animated property is a single layer's transform or opacity
/// (render-server interpolated, zero per-frame CPU), and the animation is
/// removed while off-window, occluded, or under Reduce Motion.
///
/// This is the sanctioned way to animate anything in the sidebar: SwiftUI
/// animation on a row would re-run layout for the whole list every frame.
struct GPUSpinner: NSViewRepresentable {
    let style: GPUSpinnerStyle
    let color: NSColor

    func makeNSView(context: Context) -> GPUSpinnerNSView {
        let view = GPUSpinnerNSView(frame: .zero)
        view.style = style
        view.color = color
        return view
    }

    func updateNSView(_ view: GPUSpinnerNSView, context: Context) {
        view.style = style
        view.color = color
    }
}

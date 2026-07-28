import Foundation

/// What a sidebar workspace row has to say, ranked by how urgently it wants the
/// user's eyes.
///
/// The glyph column is an inbox, not a status board. With ~30 workspaces the
/// only question it can usefully answer at a glance is "which rows want me?", so
/// a state earns a glyph only if the answer is yes. Three of these are
/// actionable (`error`, `needsAttention`, `done`); `working` is ambient and
/// deliberately recessive.
///
/// Two states are absent on purpose:
///
/// - **Idle.** An agent process sitting there doing nothing is not a reason to
///   click, which makes it indistinguishable in usefulness from a blank row.
///   Giving it a silhouette spent a shape and taught the eye to ignore the
///   column. Lifecycle `.idle` resolves to `nil`.
/// - **"No status."** That is `Optional.none`, not a case. Every `switch` here
///   is a rendering decision, and folding "nothing to say" into the enum makes
///   it too easy to give it a glyph by accident.
enum SidebarAgentStatusState: String, Equatable, CaseIterable, Sendable {
    case error
    case needsAttention
    case done
    case working

    /// Ranked so a lower-priority concurrent signal can never mask a higher one:
    /// an error is never hidden behind a "working", and a finished sub-agent
    /// never makes a still-running workspace look complete.
    static let displayPriority: [SidebarAgentStatusState] = [
        .error,
        .needsAttention,
        .working,
        .done,
    ]

    /// The word the shape stands for. Carried by the tooltip and the
    /// accessibility label, never rendered inline — the row is already dense and
    /// a status chip would squeeze titles that are usually truncating already.
    var localizedLabel: String {
        switch self {
        case .error:
            return String(localized: "sidebar.agentStatus.error", defaultValue: "Error")
        case .needsAttention:
            return String(localized: "sidebar.agentStatus.needsAttention", defaultValue: "Needs your input")
        case .working:
            return String(localized: "sidebar.agentStatus.working", defaultValue: "Working")
        case .done:
            return String(localized: "sidebar.agentStatus.done", defaultValue: "Finished — not reviewed yet")
        }
    }
}

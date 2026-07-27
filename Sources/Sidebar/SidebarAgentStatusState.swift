import Foundation

/// The five agent states a sidebar workspace row can advertise, ranked by how
/// urgently they want the user's eyes.
///
/// "No status" is deliberately `Optional.none` rather than a sixth case: every
/// `switch` over this enum is a rendering decision, and folding "nothing to say"
/// into the enum makes it too easy to give it a glyph by accident.
enum SidebarAgentStatusState: String, Equatable, CaseIterable, Sendable {
    case error
    case needsAttention
    case working
    case idle
    case done

    /// Ranked so a lower-priority concurrent signal can never mask a higher one
    /// (an error is never hidden behind a "running"). Order matches the legacy
    /// `SidebarStatusStyle.rankedDotColor` ranking exactly — changing it changes
    /// which dot a multi-status workspace shows.
    static let displayPriority: [SidebarAgentStatusState] = [
        .error,
        .needsAttention,
        .working,
        .idle,
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
        case .idle:
            return String(localized: "sidebar.agentStatus.idle", defaultValue: "Idle")
        case .done:
            return String(localized: "sidebar.agentStatus.done", defaultValue: "Done")
        }
    }
}

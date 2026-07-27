import Foundation

/// Resolves one `SidebarAgentStatusState` for a workspace row from the two
/// signals cmux already collects.
///
/// Deliberately a free function over plain values, not a method on `Workspace`:
/// rows live under a `LazyVStack` and may not hold store references (CLAUDE.md
/// snapshot-boundary rule), and taking the maps as parameters is what makes the
/// precedence table unit-testable without standing up a workspace.
enum SidebarAgentStatusResolver {
    /// Two sources, unioned then ranked:
    ///
    /// 1. **Typed** `AgentHibernationLifecycleState`, written per panel by the
    ///    agent hook pipeline (`FeedCoordinator`) and the `set_agent_lifecycle`
    ///    control-socket command. Covers `working` / `needsAttention` / `idle`.
    /// 2. **Free text** `SidebarStatusEntry` key/value pairs matched by
    ///    `SidebarStatusStyle.kind(forKey:value:)`. This is the only source for
    ///    `done` and `error` — neither has a typed representation today, and
    ///    inventing one here would mean guessing at agent intent.
    ///
    /// Union-then-rank rather than "typed wins" is the load-bearing choice: when
    /// no panel reports a lifecycle, the result is identical to what the old
    /// `rankedDotColor` produced from the same entries, so swapping the dot for
    /// the glyph cannot regress an existing workspace. Adding typed states can
    /// only raise the resolved priority, never lower it.
    static func state(
        lifecycleStatesByPanelId: [UUID: [String: AgentHibernationLifecycleState]],
        statusEntries: [(key: String, value: String)]
    ) -> SidebarAgentStatusState? {
        var candidates = Set<SidebarAgentStatusState>()

        for panelStates in lifecycleStatesByPanelId.values {
            for (key, lifecycle) in panelStates {
                // `manual` is the reserved `cmux workspace loading` namespace. It
                // drives its own affordance and is excluded from the hibernation
                // rollup, so it must not colour the agent glyph either.
                guard !AgentHibernationLifecycleStatusKeys.isManualKey(key) else { continue }
                if let state = state(forLifecycle: lifecycle) {
                    candidates.insert(state)
                }
            }
        }

        for entry in statusEntries {
            if let kind = SidebarStatusStyle.kind(forKey: entry.key, value: entry.value) {
                candidates.insert(state(forKind: kind))
            }
        }

        return SidebarAgentStatusState.displayPriority.first { candidates.contains($0) }
    }

    /// `.unknown` contributes nothing: an agent that has registered but not yet
    /// reported is not a state worth a glyph, and treating it as `idle` would
    /// light up every row at launch.
    static func state(forLifecycle lifecycle: AgentHibernationLifecycleState) -> SidebarAgentStatusState? {
        switch lifecycle {
        case .running: return .working
        case .needsInput: return .needsAttention
        case .idle: return .idle
        case .unknown: return nil
        }
    }

    static func state(forKind kind: SidebarStatusStyle.Kind) -> SidebarAgentStatusState {
        switch kind {
        case .error: return .error
        case .needsInput: return .needsAttention
        case .running: return .working
        case .idle: return .idle
        case .done: return .done
        }
    }
}

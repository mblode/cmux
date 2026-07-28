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
    ///    `error`, which has no typed representation today; inventing one here
    ///    would mean guessing at agent intent.
    /// 3. **The completion latch**, `hasUnseenAgentCompletion`. Without it
    ///    `done` would be unreachable in practice: cmux erases an agent's
    ///    lifecycle *and* its status entries when the process exits, so a
    ///    finished workspace otherwise looks exactly like one that never ran
    ///    anything. This is the single biggest source of glyphs at rest.
    ///
    /// Union-then-rank rather than "typed wins": adding a source can only raise
    /// the resolved priority, never lower it, so no signal can be masked by a
    /// quieter one arriving later.
    static func state(
        lifecycleStatesByPanelId: [UUID: [String: AgentHibernationLifecycleState]],
        statusEntries: [(key: String, value: String)],
        hasUnseenAgentCompletion: Bool
    ) -> SidebarAgentStatusState? {
        var candidates = Set<SidebarAgentStatusState>()
        if hasUnseenAgentCompletion {
            candidates.insert(.done)
        }

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
            if let kind = SidebarStatusStyle.kind(forKey: entry.key, value: entry.value),
               let state = state(forKind: kind) {
                candidates.insert(state)
            }
        }

        return SidebarAgentStatusState.displayPriority.first { candidates.contains($0) }
    }

    /// `.unknown` and `.idle` both contribute nothing. Unknown is an agent that
    /// registered but has not reported — treating it as a state would light up
    /// every row at launch. Idle is a live process doing nothing, which is not a
    /// reason to click, so it reads the same as a blank row.
    static func state(forLifecycle lifecycle: AgentHibernationLifecycleState) -> SidebarAgentStatusState? {
        switch lifecycle {
        case .running: return .working
        case .needsInput: return .needsAttention
        case .idle, .unknown: return nil
        }
    }

    /// Free-text `idle`-family words ("paused", "waiting", "hibernating") map to
    /// nothing for the same reason the typed `.idle` does.
    static func state(forKind kind: SidebarStatusStyle.Kind) -> SidebarAgentStatusState? {
        switch kind {
        case .error: return .error
        case .needsInput: return .needsAttention
        case .running: return .working
        case .done: return .done
        case .idle: return nil
        }
    }
}

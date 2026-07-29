import CmuxSidebar
import Foundation
import XCTest

#if canImport(cmux_DEV)
@testable import cmux_DEV
#elseif canImport(cmux)
@testable import cmux
#endif

/// The latch behind the sidebar's "finished, not reviewed yet" glyph.
///
/// It exists because cmux erases an agent's lifecycle and status when its
/// process exits, and because an agent that merely finishes a *turn* stays alive
/// at its prompt and reports nothing distinguishable at all. Without the latch,
/// a workspace that just did 10 minutes of work looks exactly like one that has
/// never been touched.
final class SidebarAgentCompletionLatchTests: XCTestCase {
    @MainActor
    func testFinishingATurnLatchesCompletion() throws {
        let workspace = Workspace()
        let panelId = try XCTUnwrap(workspace.focusedPanelId)

        workspace.setAgentLifecycle(key: "claude_code", panelId: panelId, lifecycle: .running)
        XCTAssertFalse(workspace.hasUnseenAgentCompletion)

        workspace.setAgentLifecycle(key: "claude_code", panelId: panelId, lifecycle: .idle)

        XCTAssertTrue(
            workspace.hasUnseenAgentCompletion,
            "An agent going from working to not-working has finished a turn, which is the sidebar's 'done' signal."
        )
    }

    @MainActor
    func testResolvingAPermissionPromptAndThenFinishingAlsoLatches() throws {
        let workspace = Workspace()
        let panelId = try XCTUnwrap(workspace.focusedPanelId)

        workspace.setAgentLifecycle(key: "claude_code", panelId: panelId, lifecycle: .needsInput)
        XCTAssertFalse(workspace.hasUnseenAgentCompletion)

        workspace.setAgentLifecycle(key: "claude_code", panelId: panelId, lifecycle: .idle)

        XCTAssertTrue(workspace.hasUnseenAgentCompletion)
    }

    @MainActor
    func testStartupDoesNotLatchCompletion() throws {
        let workspace = Workspace()
        let panelId = try XCTUnwrap(workspace.focusedPanelId)

        // First report of any kind, and the unknown -> idle registration step.
        workspace.setAgentLifecycle(key: "claude_code", panelId: panelId, lifecycle: .idle)
        XCTAssertFalse(
            workspace.hasUnseenAgentCompletion,
            "An agent registering as idle has not finished anything; latching here would check every row at launch."
        )

        workspace.setAgentLifecycle(key: "claude_code", panelId: panelId, lifecycle: .unknown)
        workspace.setAgentLifecycle(key: "claude_code", panelId: panelId, lifecycle: .idle)
        XCTAssertFalse(workspace.hasUnseenAgentCompletion)
    }

    @MainActor
    func testRepeatedIdleReportsDoNotRelatch() throws {
        let workspace = Workspace()
        let panelId = try XCTUnwrap(workspace.focusedPanelId)

        workspace.setAgentLifecycle(key: "claude_code", panelId: panelId, lifecycle: .running)
        workspace.setAgentLifecycle(key: "claude_code", panelId: panelId, lifecycle: .idle)
        workspace.clearUnseenAgentCompletion()

        // Claude's idle nag re-reports idle every ~60s; that is not a new turn.
        workspace.setAgentLifecycle(key: "claude_code", panelId: panelId, lifecycle: .idle)

        XCTAssertFalse(
            workspace.hasUnseenAgentCompletion,
            "Re-reporting idle must not resurrect a check the user already cleared by visiting."
        )
    }

    @MainActor
    func testCompletionRetiresTheAgentsOwnPillButNotUserStatuses() throws {
        let workspace = Workspace()
        let panelId = try XCTUnwrap(workspace.focusedPanelId)

        workspace.statusEntries["claude_code"] = SidebarStatusEntry(
            key: "claude_code",
            value: "Running",
            timestamp: Date()
        )
        workspace.statusEntries["deploy"] = SidebarStatusEntry(
            key: "deploy",
            value: "staging",
            timestamp: Date()
        )

        workspace.setAgentLifecycle(key: "claude_code", panelId: panelId, lifecycle: .running)
        workspace.setAgentLifecycle(key: "claude_code", panelId: panelId, lifecycle: .idle)

        XCTAssertNil(
            workspace.statusEntries["claude_code"],
            "A stale 'Running' pill would out-rank the completion in the resolver and contradict the glyph above it."
        )
        XCTAssertEqual(
            workspace.statusEntries["deploy"]?.value,
            "staging",
            "A user's own `cmux set-status` line is not the agent's to clear."
        )
    }

    @MainActor
    func testManualLoaderKeyNeverLatches() throws {
        let workspace = Workspace()
        let panelId = try XCTUnwrap(workspace.focusedPanelId)
        let manualKey = AgentHibernationLifecycleStatusKeys.manualKey

        workspace.setAgentLifecycle(key: manualKey, panelId: panelId, lifecycle: .running)
        workspace.setAgentLifecycle(key: manualKey, panelId: panelId, lifecycle: .idle)

        XCTAssertFalse(
            workspace.hasUnseenAgentCompletion,
            "`cmux workspace loading` is not an agent finishing work."
        )
    }
}

import Foundation
import SwiftUI
import Testing
#if canImport(cmux_DEV)
@testable import cmux_DEV
#elseif canImport(cmux)
@testable import cmux
#endif

@Suite struct SidebarAgentStatusResolverTests {
    private static let panelA = UUID()
    private static let panelB = UUID()

    private static func resolve(
        lifecycles: [UUID: [String: AgentHibernationLifecycleState]] = [:],
        entries: [(key: String, value: String)] = []
    ) -> SidebarAgentStatusState? {
        SidebarAgentStatusResolver.state(
            lifecycleStatesByPanelId: lifecycles,
            statusEntries: entries
        )
    }

    @Test func noSignalsResolveToNoGlyph() {
        #expect(Self.resolve() == nil)
    }

    @Test func unrecognizedStatusTextDoesNotInventAState() {
        #expect(
            Self.resolve(entries: [(key: "fleet", value: "deploying to shard 4")]) == nil,
            "Agents put arbitrary text in status entries; only the recognized vocabulary may light a glyph."
        )
    }

    @Test func unknownLifecycleContributesNothing() {
        #expect(
            Self.resolve(lifecycles: [Self.panelA: ["claude_code": .unknown]]) == nil,
            "A registered-but-silent agent has nothing to report; treating it as idle would light up every row at launch."
        )
    }

    @Test func typedLifecycleResolvesWithoutAnyStatusText() {
        #expect(Self.resolve(lifecycles: [Self.panelA: ["claude_code": .running]]) == .working)
        #expect(Self.resolve(lifecycles: [Self.panelA: ["claude_code": .needsInput]]) == .needsAttention)
        #expect(Self.resolve(lifecycles: [Self.panelA: ["claude_code": .idle]]) == .idle)
    }

    @Test func manualLoadingKeyIsExcluded() {
        #expect(
            Self.resolve(lifecycles: [Self.panelA: [AgentHibernationLifecycleStatusKeys.manualKey: .running]]) == nil,
            "`cmux workspace loading` drives its own affordance and is excluded from the hibernation rollup; it must not colour the agent glyph either."
        )
        #expect(Self.resolve(lifecycles: [Self.panelA: ["manual:import": .running]]) == nil)
    }

    @Test func highestPriorityStateAcrossPanelsWins() {
        #expect(
            Self.resolve(lifecycles: [
                Self.panelA: ["claude_code": .idle],
                Self.panelB: ["codex": .needsInput],
            ]) == .needsAttention,
            "One panel blocking on the user must not be masked by another panel sitting idle."
        )
    }

    @Test func errorOutranksEveryOtherSignal() {
        #expect(
            Self.resolve(
                lifecycles: [Self.panelA: ["claude_code": .running]],
                entries: [(key: "build", value: "failed")]
            ) == .error
        )
    }

    @Test func needsAttentionOutranksWorking() {
        #expect(
            Self.resolve(lifecycles: [Self.panelA: ["claude_code": .running, "codex": .needsInput]]) == .needsAttention
        )
    }

    @Test func workingOutranksDone() {
        #expect(
            Self.resolve(
                lifecycles: [Self.panelA: ["claude_code": .running]],
                entries: [(key: "fleet", value: "done")]
            ) == .working,
            "A finished sub-task must not make a still-running workspace look complete."
        )
    }

    @Test func doneIsTheLowestPriority() {
        #expect(Self.resolve(entries: [(key: "fleet", value: "done")]) == .done)
        #expect(
            Self.resolve(entries: [
                (key: "fleet", value: "done"),
                (key: "claude_code", value: "idle"),
            ]) == .idle
        )
    }

    /// The load-bearing anti-regression test for replacing the free-text dot.
    ///
    /// With no typed lifecycle present, the resolver must land on exactly the
    /// colour the old `rankedDotColor` produced for the same entries. If this
    /// fails, existing workspaces changed colour when the glyph shipped.
    @Test(arguments: [ColorScheme.light, ColorScheme.dark])
    func matchesLegacyRankedDotColorWhenNoLifecycleIsReported(scheme: ColorScheme) {
        let vocabulary: [(key: String, value: String)] = [
            ("build", "error"), ("test", "fail"), ("agent", "crash"),
            ("tool", "denied"), ("merge", "blocked"),
            ("claude_code", "Needs input"), ("codex", "await"),
            ("agent", "approval"), ("agent", "action required"),
            ("agent", "waiting for you"), ("agent", "your turn"),
            ("fleet", "done"), ("task", "complete"), ("task", "finished"),
            ("pr", "merged"), ("build", "success"), ("pr", "ready"),
            ("agent", "idle"), ("agent", "paused"), ("agent", "waiting"),
            ("agent", "hibernating"), ("agent", "sleep"), ("agent", "stopped"),
            ("agent", "running"), ("agent", "working"), ("agent", "in progress"),
            ("agent", "streaming"), ("agent", "thinking"), ("agent", "building"),
            ("agent", "active"),
        ]

        for entry in vocabulary {
            let legacy = SidebarStatusStyle.rankedDotColor(forEntries: [entry], colorScheme: scheme)
            let resolved = Self.resolve(entries: [entry]).map {
                SidebarStatusStyle.color(for: $0, colorScheme: scheme)
            }
            #expect(
                legacy == resolved,
                "\(entry.key)=\(entry.value) changed colour when the dot became a glyph."
            )
        }
    }

    @Test func rankingMatchesLegacyForConcurrentEntries() {
        let entries: [(key: String, value: String)] = [
            (key: "agent", value: "running"),
            (key: "fleet", value: "done"),
            (key: "build", value: "failed"),
        ]
        let legacy = SidebarStatusStyle.rankedDotColor(forEntries: entries, colorScheme: .dark)
        let resolved = Self.resolve(entries: entries).map {
            SidebarStatusStyle.color(for: $0, colorScheme: .dark)
        }
        #expect(legacy == resolved)
    }

    @Test func everyStateIsReachableAndDistinctlyPrioritized() {
        #expect(Set(SidebarAgentStatusState.displayPriority) == Set(SidebarAgentStatusState.allCases))
        #expect(SidebarAgentStatusState.displayPriority.count == SidebarAgentStatusState.allCases.count)
    }
}

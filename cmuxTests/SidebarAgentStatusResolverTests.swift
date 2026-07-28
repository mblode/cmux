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
        entries: [(key: String, value: String)] = [],
        completed: Bool = false
    ) -> SidebarAgentStatusState? {
        SidebarAgentStatusResolver.state(
            lifecycleStatesByPanelId: lifecycles,
            statusEntries: entries,
            hasUnseenAgentCompletion: completed
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
    }

    /// The glyph column is an inbox. An agent sitting idle is not a reason to
    /// click, so it reads the same as a row with no agent at all.
    @Test func idleEarnsNoGlyph() {
        #expect(Self.resolve(lifecycles: [Self.panelA: ["claude_code": .idle]]) == nil)
        #expect(Self.resolve(entries: [(key: "agent", value: "paused")]) == nil)
        #expect(Self.resolve(entries: [(key: "agent", value: "hibernating")]) == nil)
    }

    /// Without the completion latch `done` is unreachable: cmux erases an
    /// agent's lifecycle and status entries when its process exits, so a
    /// finished workspace looks identical to one that never ran anything.
    @Test func completionLatchIsWhatMakesDoneReachable() {
        #expect(Self.resolve(completed: true) == .done)
        #expect(Self.resolve(completed: false) == nil)
    }

    @Test func liveWorkOutranksAPriorCompletion() {
        #expect(
            Self.resolve(lifecycles: [Self.panelA: ["claude_code": .running]], completed: true) == .working,
            "A workspace that finished one agent and started another is working, not done."
        )
        #expect(
            Self.resolve(lifecycles: [Self.panelA: ["claude_code": .needsInput]], completed: true) == .needsAttention
        )
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
                (key: "build", value: "failed"),
            ]) == .error
        )
    }

    /// Anti-regression for replacing the free-text dot: with no typed lifecycle
    /// present, every recognized word must still land on exactly the colour the
    /// old `rankedDotColor` produced.
    ///
    /// The idle family is excluded by design — those words used to draw an amber
    /// dot and now draw nothing, which is the one intentional break.
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

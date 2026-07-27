import Foundation
import Testing
@testable import CmuxSidebar

@Suite struct SidebarPullRequestPresentationTests {
    @Test func openPullRequestResolvesOpen() {
        #expect(SidebarPullRequestPresentation.resolve(status: .open, isDraft: false) == .open)
    }

    @Test func openDraftResolvesDraft() {
        #expect(SidebarPullRequestPresentation.resolve(status: .open, isDraft: true) == .draft)
    }

    @Test func mergedOutranksAStaleDraftFlag() {
        #expect(
            SidebarPullRequestPresentation.resolve(status: .merged, isDraft: true) == .merged,
            "A merged PR is a terminal fact; `isDraft` can lag a ready-for-review flip by a poll interval and must not render a landed PR as grey draft."
        )
    }

    @Test func closedOutranksAStaleDraftFlag() {
        #expect(SidebarPullRequestPresentation.resolve(status: .closed, isDraft: true) == .closed)
    }

    @Test func mergedAndClosedIgnoreDraftEntirely() {
        for isDraft in [true, false] {
            #expect(SidebarPullRequestPresentation.resolve(status: .merged, isDraft: isDraft) == .merged)
            #expect(SidebarPullRequestPresentation.resolve(status: .closed, isDraft: isDraft) == .closed)
        }
    }

    @Test func everyPresentationIsReachable() {
        let reachable = Set(
            [SidebarPullRequestStatus.open, .merged, .closed].flatMap { status in
                [true, false].map { SidebarPullRequestPresentation.resolve(status: status, isDraft: $0) }
            }
        )
        #expect(
            reachable == Set(SidebarPullRequestPresentation.allCases),
            "A presentation case with no input that produces it is dead code the view still has to switch on."
        )
    }

    /// The frozen-wire-format guard. If someone adds a case to
    /// `SidebarPullRequestStatus`, `report_pr --state=` and the custom-sidebar
    /// projection silently start accepting a value older cmux builds reject.
    @Test func statusWireVocabularyIsUnchanged() {
        #expect(SidebarPullRequestStatus.open.rawValue == "open")
        #expect(SidebarPullRequestStatus.merged.rawValue == "merged")
        #expect(SidebarPullRequestStatus.closed.rawValue == "closed")
        #expect(SidebarPullRequestStatus(rawValue: "draft") == nil)
    }

    @Test func draftDefaultsToFalseSoExistingCallersAreUnaffected() {
        let state = SidebarPullRequestState(
            number: 1,
            label: "PR",
            url: URL(string: "https://github.com/o/r/pull/1")!,
            status: .open
        )
        #expect(state.isDraft == false)
    }
}

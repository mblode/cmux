public import Foundation

/// One pull-request row shown under a workspace in the sidebar.
public struct SidebarPullRequestState: Equatable, Sendable {
    /// The PR number.
    public let number: Int
    /// The repository label (e.g. `owner/repo`).
    public let label: String
    /// The PR URL.
    public let url: URL
    /// Lifecycle status.
    public let status: SidebarPullRequestStatus
    /// The PR's branch, normalized (trimmed, nil when empty).
    public let branch: String?
    /// Whether the row is stale (reported by an inactive panel).
    public let isStale: Bool
    /// Whether the PR is still a draft. A sibling field, not a
    /// ``SidebarPullRequestStatus`` case: those raw values are a frozen
    /// control-socket wire format. See ``SidebarPullRequestPresentation``.
    public let isDraft: Bool

    /// Creates a pull-request row (defaults mirror the legacy initializer).
    public init(
        number: Int,
        label: String,
        url: URL,
        status: SidebarPullRequestStatus,
        branch: String? = nil,
        isStale: Bool = false,
        isDraft: Bool = false
    ) {
        self.number = number
        self.label = label
        self.url = url
        self.status = status
        self.branch = branch?.normalizedSidebarBranchName
        self.isStale = isStale
        self.isDraft = isDraft
    }
}

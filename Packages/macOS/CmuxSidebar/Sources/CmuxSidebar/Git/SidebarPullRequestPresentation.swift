/// What a sidebar pull-request row should actually look like.
///
/// This exists because `SidebarPullRequestStatus` is a frozen control-socket
/// wire format and cannot grow cases. Every additional PR axis — draft today,
/// merge conflicts or CI checks later — arrives as a *sibling field* on
/// `SidebarPullRequestState` and is folded into this presentation union here,
/// so the wire contract stays stable and the view keeps one thing to switch on.
///
/// Do not add cases to `SidebarPullRequestStatus`. Add a field, then a case here.
public enum SidebarPullRequestPresentation: String, Sendable, Equatable, CaseIterable {
    case draft
    case open
    case merged
    case closed

    /// Terminal facts win. A PR that has landed or been closed is reported as
    /// such by the API, while `isDraft` can lag a `ready-for-review` flip by up
    /// to a poll interval — resolving draft first would render merged PRs grey.
    public static func resolve(
        status: SidebarPullRequestStatus,
        isDraft: Bool
    ) -> SidebarPullRequestPresentation {
        switch status {
        case .merged: return .merged
        case .closed: return .closed
        case .open: return isDraft ? .draft : .open
        }
    }
}

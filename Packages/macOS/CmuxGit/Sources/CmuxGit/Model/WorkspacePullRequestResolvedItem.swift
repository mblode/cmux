import Foundation

/// The pull request a refresh resolved for one panel, reduced to the fields a
/// badge needs.
public struct WorkspacePullRequestResolvedItem: Sendable {
    /// The pull request number.
    public let number: Int
    /// The PR's html URL string.
    public let urlString: String
    /// The ``PullRequestStatus`` raw value (`"open"`/`"merged"`/`"closed"`),
    /// kept as a string so app-side status enums can bridge via `rawValue`.
    public let statusRawValue: String
    /// The branch the PR was matched for.
    public let branch: String
    /// Whether the PR is a draft. A sibling field rather than a status case:
    /// the status raw values are a frozen control-socket wire format.
    public let isDraft: Bool

    /// Creates a resolved item.
    public init(
        number: Int,
        urlString: String,
        statusRawValue: String,
        branch: String,
        isDraft: Bool = false
    ) {
        self.number = number
        self.urlString = urlString
        self.statusRawValue = statusRawValue
        self.branch = branch
        self.isDraft = isDraft
    }
}

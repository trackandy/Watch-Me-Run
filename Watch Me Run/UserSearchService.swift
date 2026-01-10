import Foundation
import Combine
import FirebaseFirestore

struct FriendSearchResult: Identifiable, Hashable {
    let id: String          // Firebase user document ID (uid)
    let name: String
    let location: String?
    let affiliation: String?
    let searchable: Bool
}

final class UserSearchService: ObservableObject {
    static let shared = UserSearchService()

    @Published var results: [FriendSearchResult] = []
    @Published var isSearching: Bool = false

    private let db = Firestore.firestore()

    private init() {}

    /// Search for users by name. Uses the `searchNameLower` field for prefix matching
    /// and only returns users who have `searchable == true`.
    /// - Parameters:
    ///   - query: The partial name to search for (case-insensitive). Must be at least 2 non-whitespace characters.
    ///   - limit: Maximum number of results to return. Defaults to 20.
    ///   - completion: Optional callback invoked on the main thread with the results.
    func searchUsers(byName query: String, limit: Int = 20, completion: (([FriendSearchResult]) -> Void)? = nil) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        // Require at least 2 characters to avoid overly broad queries
        guard trimmed.count >= 2 else {
            DispatchQueue.main.async {
                self.results = []
                self.isSearching = false
                completion?([])
            }
            return
        }

        isSearching = true

        let lower = trimmed.lowercased()
        // Firestore prefix-search upper-bound trick using \u{f8ff}
        let upperBound = lower + "\u{f8ff}"

        db.collection("users")
            .whereField("searchable", isEqualTo: true)
            .whereField("searchNameLower", isGreaterThanOrEqualTo: lower)
            .whereField("searchNameLower", isLessThan: upperBound)
            .limit(to: limit)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    self.isSearching = false

                    if let error = error {
                        print("⚠️ UserSearchService.searchUsers error: \(error.localizedDescription)")
                        self.results = []
                        completion?([])
                        return
                    }

                    guard let documents = snapshot?.documents else {
                        self.results = []
                        completion?([])
                        return
                    }

                    let mapped: [FriendSearchResult] = documents.map { doc in
                        let data = doc.data()
                        let name = (data["name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                            .nonEmpty ?? "Runner"
                        let location = (data["location"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty
                        let affiliation = (data["affiliation"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty
                        let searchable = data["searchable"] as? Bool ?? false

                        return FriendSearchResult(
                            id: doc.documentID,
                            name: name,
                            location: location,
                            affiliation: affiliation,
                            searchable: searchable
                        )
                    }

                    self.results = mapped
                    completion?(mapped)
                }
            }
    }
}

private extension String {
    var nonEmpty: String? {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

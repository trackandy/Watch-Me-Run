
//
//  UserDetailsStore.swift
//  Watch Me Run
//
//  Created by Andy Kent on 1/2/26.
//

import Foundation
import Combine
import FirebaseFirestore

/// Observable store for the top-level user details in `users/{uid}`.
///
/// Races live under `users/{uid}/races/{raceId}`, but this store
/// is specifically for the profile / runner details document.
final class UserDetailsStore: ObservableObject {

    @Published var details: UserDetails?

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    // MARK: - Listener lifecycle

    /// Start listening to `users/{uid}` for details changes.
    func startListening(for uid: String) {
        guard !uid.isEmpty else {
            print("⚠️ UserDetailsStore.startListening called with empty uid")
            return
        }

        // Remove any existing listener before attaching a new one
        if let listener {
            print("🛑 UserDetailsStore: removing existing listener before starting a new one")
            listener.remove()
            self.listener = nil
        }

        print("👂 UserDetailsStore.startListening: attaching listener for uid \(uid)")

        listener = db.collection("users")
            .document(uid)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("❌ UserDetailsStore snapshot error for uid \(uid): \(error)")
                    return
                }

                guard let snapshot = snapshot else {
                    print("⚠️ UserDetailsStore: snapshot was nil for uid \(uid)")
                    return
                }

                if let data = snapshot.data() {
                    let loaded = UserDetails(id: snapshot.documentID, data: data)
                    self.details = loaded
                    print("📥 UserDetailsStore: loaded details for uid \(uid): \(loaded)")
                } else {
                    // No document yet — keep details nil and let UI decide how to treat it,
                    // or initialize an empty model if you prefer.
                    print("ℹ️ UserDetailsStore: no details document yet for uid \(uid)")
                    self.details = nil
                }
            }
    }

    /// Stop listening to the current user's details and clear state.
    func stopListening() {
        if let listener {
            print("🛑 UserDetailsStore.stopListening: removing listener and clearing details")
            listener.remove()
            self.listener = nil
        }
        details = nil
    }

    // MARK: - Save

    /// Save (or update) the details for a given uid into `users/{uid}`.
    ///
    /// - Parameters:
    ///   - details: The `UserDetails` model to save.
    ///   - uid: The Firebase Auth UID; used as the document ID.
    ///   - completion: Optional callback with an `Error?` for debugging or UI feedback.
    func save(_ details: UserDetails, for uid: String, completion: ((Error?) -> Void)? = nil) {
        guard !uid.isEmpty else {
            let errorMessage = "UserDetailsStore.save called with empty uid"
            print("❌ \(errorMessage)")
            completion?(NSError(domain: "UserDetailsStore", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
            return
        }

        var data = details.toDictionary()

        // Derive a lowercase search field from the user's name, if present.
        if let rawName = data["name"] as? String {
            let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                data["name"] = trimmed
                data["searchNameLower"] = trimmed.lowercased()
            }
        }

        print("⬆️ UserDetailsStore.save: saving details for uid \(uid) with data: \(data)")

        db.collection("users")
            .document(uid)
            .setData(data, merge: true) { error in
                if let error = error {
                    print("❌ UserDetailsStore.save error for uid \(uid): \(error)")
                    completion?(error)
                } else {
                    print("✅ UserDetailsStore.save succeeded for uid \(uid)")
                    completion?(nil)
                }
            }
    }
}


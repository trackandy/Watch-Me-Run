
//
//  FriendRaceStore.swift
//  Watch Me Run
//
//  Created by Andy Kent on 12/24/25.
//

import Foundation
import SwiftUI
import Combine
import FirebaseFirestore

/// Read-only store for another user's races, backed by Firestore.
/// Used primarily by RunnerDetailView when viewing a "friend" from the Watching tab.
@MainActor
final class FriendRaceStore: ObservableObject {

    @Published private(set) var races: [UserRace] = []

    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()

    /// Begin listening to the given user's races in Firestore.
    /// - Parameter uid: The friend's Firebase Auth UID (users/{uid}/races).
    func startListening(for uid: String) {
        // Clean up any prior listener
        stopListening()

        print("👂 FriendRaceStore.startListening: attaching listener for friend uid \(uid)")

        let collection = db
            .collection("users")
            .document(uid)
            .collection("races")

        listener = collection
            .order(by: "date", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("❌ FriendRaceStore: error listening to races for uid \(uid): \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("ℹ️ FriendRaceStore: snapshot has no documents for uid \(uid); setting races to empty.")
                    self.races = []
                    return
                }

                print("📥 FriendRaceStore snapshot for uid \(uid): \(documents.count) race docs")

                let mapped: [UserRace] = documents.compactMap { doc in
                    let data = doc.data()

                    let id = doc.documentID
                    let name = data["name"] as? String ?? "Untitled race"
                    let distance = data["distance"] as? String ?? ""

                    let date: Date
                    if let ts = data["date"] as? Timestamp {
                        date = ts.dateValue()
                    } else {
                        date = Date()
                    }

                    let liveString = data["liveResultsURL"] as? String ?? ""
                    let watchString = data["watchURL"] as? String ?? ""

                    let liveURL = liveString.isEmpty ? nil : URL(string: liveString)
                    let watchURL = watchString.isEmpty ? nil : URL(string: watchString)

                    return UserRace(
                        id: id,
                        name: name,
                        distance: distance,
                        date: date,
                        liveResultsURL: liveURL,
                        watchURL: watchURL
                    )
                }

                self.races = mapped
            }
    }

    /// Stop listening to Firestore for this friend's races.
    func stopListening() {
        if listener != nil {
            print("🛑 FriendRaceStore.stopListening: removing listener and clearing races")
        }
        listener?.remove()
        listener = nil
        races = []
    }
}

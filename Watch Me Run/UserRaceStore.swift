//
//  UserRaceStore.swift
//  Watch Me Run
//
//  Created by Andy Kent on 12/23/25.
//

import Foundation
import Combine
import SwiftUI
import FirebaseFirestore

/// Central store for a user's races, backed by Firestore.
/// MeView and, eventually, WatchingView read from here instead of their own local [UserRace] state.
@MainActor
final class UserRaceStore: ObservableObject {

    @Published private(set) var races: [UserRace] = []

    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()

    // MARK: - Listening

    /// Start listening to the signed-in user's races in Firestore.
    /// Call this after the user signs in, passing their Firebase uid.
    func startListening(for uid: String) {
        // Clean up any existing listener first
        stopListening()

        print("👂 UserRaceStore.startListening: attaching listener for uid \(uid)")

        let collection = db
            .collection("users")
            .document(uid)
            .collection("races")

        listener = collection
            .order(by: "date", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("❌ Error listening to races for uid \(uid): \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("ℹ️ Snapshot has no documents for uid \(uid); setting races to empty.")
                    self.races = []
                    return
                }

                print("📥 UserRaceStore snapshot for uid \(uid): \(documents.count) race docs")

                let mapped: [UserRace] = documents.compactMap { doc in
                    let data = doc.data()

                    let id = doc.documentID
                    let name = data["name"] as? String ?? "Untitled race"
                    let distance = data["distance"] as? String ?? ""

                    // Date
                    let date: Date
                    if let ts = data["date"] as? Timestamp {
                        date = ts.dateValue()
                    } else {
                        date = Date()
                    }

                    // URLs
                    let liveString = data["liveResultsURL"] as? String ?? ""
                    let watchString = data["watchURL"] as? String ?? ""
                    let meetString = data["meetPageURL"] as? String ?? ""

                    let liveURL = liveString.isEmpty ? nil : URL(string: liveString)
                    let watchURL = watchString.isEmpty ? nil : URL(string: watchString)
                    let meetPageURL = meetString.isEmpty ? nil : URL(string: meetString)

                    // Time zone & location
                    let timeZoneIdentifier = data["timeZoneIdentifier"] as? String
                    let location = data["location"] as? String ?? ""

                    // Levels – support both legacy "level" string and new "levels" array
                    var levels: [String] = []
                    if let levelArray = data["levels"] as? [String] {
                        levels = levelArray
                    } else if let singleLevel = data["level"] as? String, !singleLevel.isEmpty {
                        levels = [singleLevel]
                    }

                    // Optional text fields
                    let instructions = data["instructions"] as? String
                    let comments = data["comments"] as? String

                    return UserRace(
                        id: id,
                        name: name,
                        distance: distance,
                        date: date,
                        liveResultsURL: liveURL,
                        watchURL: watchURL,
                        timeZoneIdentifier: timeZoneIdentifier,
                        location: location,
                        meetPageURL: meetPageURL,
                        levels: levels,
                        instructions: instructions,
                        comments: comments
                    )
                }

                self.races = mapped
            }
    }

    /// Stop listening to Firestore (e.g., when user logs out).
    func stopListening() {
        if listener != nil {
            print("🛑 UserRaceStore.stopListening: removing listener and clearing races")
        }
        listener?.remove()
        listener = nil
        races = []
    }

    // MARK: - CRUD

    /// Create or update a race document in Firestore for the given user.
    func addOrUpdate(_ race: UserRace, for uid: String) async {
        let docRef = db
            .collection("users")
            .document(uid)
            .collection("races")
            .document(race.id)

        var data: [String: Any] = [
            "name": race.name,
            "distance": race.distance,
            "date": race.date
        ]

        // URLs
        if let live = race.liveResultsURL?.absoluteString, !live.isEmpty {
            data["liveResultsURL"] = live
        } else {
            data["liveResultsURL"] = NSNull()
        }

        if let watch = race.watchURL?.absoluteString, !watch.isEmpty {
            data["watchURL"] = watch
        } else {
            data["watchURL"] = NSNull()
        }

        if let meet = race.meetPageURL?.absoluteString, !meet.isEmpty {
            data["meetPageURL"] = meet
        } else {
            data["meetPageURL"] = NSNull()
        }

        // Time zone & location
        if let tz = race.timeZoneIdentifier, !tz.isEmpty {
            data["timeZoneIdentifier"] = tz
        } else {
            data["timeZoneIdentifier"] = NSNull()
        }

        let trimmedLocation = race.location.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedLocation.isEmpty {
            data["location"] = trimmedLocation
        } else {
            data["location"] = NSNull()
        }

        // Levels (array of strings)
        if !race.levels.isEmpty {
            data["levels"] = race.levels
        } else {
            data["levels"] = NSNull()
        }

        // Optional text fields
        if let instructions = race.instructions?.trimmingCharacters(in: .whitespacesAndNewlines),
           !instructions.isEmpty {
            data["instructions"] = instructions
        } else {
            data["instructions"] = NSNull()
        }

        if let comments = race.comments?.trimmingCharacters(in: .whitespacesAndNewlines),
           !comments.isEmpty {
            data["comments"] = comments
        } else {
            data["comments"] = NSNull()
        }

        print("⬆️ UserRaceStore.addOrUpdate: saving race \(race.id) for uid \(uid) with data: \(data)")

        do {
            try await docRef.setData(data, merge: true)
            print("✅ Successfully saved race \(race.id) for uid \(uid)")
        } catch {
            print("❌ Error saving race \(race.id) for uid \(uid): \(error.localizedDescription)")
        }
    }

    /// Delete a race document from Firestore.
    func delete(_ race: UserRace, for uid: String) async {
        let docRef = db
            .collection("users")
            .document(uid)
            .collection("races")
            .document(race.id)

        print("🗑 UserRaceStore.delete: deleting race \(race.id) for uid \(uid)")

        do {
            try await docRef.delete()
            print("✅ Successfully deleted race \(race.id) for uid \(uid)")
        } catch {
            print("❌ Error deleting race \(race.id) for uid \(uid): \(error.localizedDescription)")
        }
    }
}

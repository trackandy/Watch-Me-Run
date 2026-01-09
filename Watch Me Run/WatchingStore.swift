
//
//  WatchingStore.swift
//  Watch Me Run
//
//  Created by Andy Kent on 1/9/26.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

/// Central store for all "watching" / favorites state for the current user.
///
/// Responsibilities:
/// - Listen to `/users/{uid}/watchingFriends` and keep `watchedFriendIDs` in sync.
/// - Listen to `/users/{uid}/watchingFeaturedEvents` and keep `watchedFeaturedEventKeys` in sync.
/// - Provide helper methods to toggle watching state for friends and featured events.
final class WatchingStore: ObservableObject {

    // MARK: - Published state

    /// Friend user IDs the current user is watching.
    @Published var watchedFriendIDs: Set<String> = []

    /// Keys for featured events the current user is watching.
    /// Convention: "{featuredMeetId}_::{eventId}"
    @Published var watchedFeaturedEventKeys: Set<String> = []

    // MARK: - Private properties

    private let db = Firestore.firestore()

    private var friendsListener: ListenerRegistration?
    private var featuredEventsListener: ListenerRegistration?

    // MARK: - Lifecycle

    deinit {
        stopListening()
    }

    // MARK: - Listening wiring

    /// Call when a user signs in to begin listening to their watching state.
    func startListening(for userID: String) {
        stopListening()

        // Friends the user is watching
        let friendsRef = db
            .collection("users")
            .document(userID)
            .collection("watchingFriends") // /users/{uid}/watchingFriends/{friendUid}

        friendsListener = friendsRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                print("⚠️ WatchingStore: failed to listen to watchingFriends: \(error.localizedDescription)")
                return
            }

            guard let snapshot = snapshot else {
                print("⚠️ WatchingStore: watchingFriends snapshot nil") 
                self.watchedFriendIDs = []
                return
            }

            let ids = snapshot.documents.map { doc in
                // Document ID is the watched friend's UID
                doc.documentID
            }
            self.watchedFriendIDs = Set(ids)
            print("👀 WatchingStore: now watching \(ids.count) friends for uid=\(userID)")
        }

        // Featured events the user is watching
        let featuredRef = db
            .collection("users")
            .document(userID)
            .collection("watchingFeaturedEvents") // /users/{uid}/watchingFeaturedEvents/{docId}

        featuredEventsListener = featuredRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                print("⚠️ WatchingStore: failed to listen to watchingFeaturedEvents: \(error.localizedDescription)")
                return
            }

            guard let snapshot = snapshot else {
                print("⚠️ WatchingStore: watchingFeaturedEvents snapshot nil")
                self.watchedFeaturedEventKeys = []
                return
            }

            // We'll store the document IDs as keys (they can be composed as featuredMeetId_eventId)
            let keys = snapshot.documents.map { $0.documentID }
            self.watchedFeaturedEventKeys = Set(keys)
            print("👀 WatchingStore: now watching \(keys.count) featured events for uid=\(userID)")
        }
    }

    /// Call when a user signs out to tear down listeners and clear state.
    func stopListening() {
        friendsListener?.remove()
        friendsListener = nil

        featuredEventsListener?.remove()
        featuredEventsListener = nil

        watchedFriendIDs = []
        watchedFeaturedEventKeys = []

        print("🛑 WatchingStore: stopped listening and cleared watching state")
    }

    // MARK: - Public API: Friends

    /// Toggle watching state for a friend.
    ///
    /// - Parameters:
    ///   - currentUserID: The uid of the signed-in user.
    ///   - friendID: The uid of the friend being watched/unwatched.
    func toggleFriendWatching(currentUserID: String, friendID: String) {
        let ref = db
            .collection("users")
            .document(currentUserID)
            .collection("watchingFriends")
            .document(friendID)

        if watchedFriendIDs.contains(friendID) {
            // Currently watching → unwatch
            print("🔁 WatchingStore: unwatching friend=\(friendID) for uid=\(currentUserID)")
            ref.delete { error in
                if let error = error {
                    print("⚠️ WatchingStore: failed to unwatch friend: \(error.localizedDescription)")
                }
            }
        } else {
            // Not watching → start watching
            print("🔁 WatchingStore: watching friend=\(friendID) for uid=\(currentUserID)")
            ref.setData([
                "friendId": friendID,
                "createdAt": FieldValue.serverTimestamp()
            ]) { error in
                if let error = error {
                    print("⚠️ WatchingStore: failed to watch friend: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Public API: Featured Events

    /// Turn a (meetId, eventId) pair into a stable key for the store and Firestore doc ID.
    func keyForFeaturedEvent(featuredMeetId: String, eventId: String) -> String {
        return "\(featuredMeetId)_::\(eventId)"
    }

    /// Toggle watching state for a single event inside a featured meet.
    ///
    /// - Parameters:
    ///   - currentUserID: The uid of the signed-in user.
    ///   - featuredMeetId: The Firestore ID of the featured meet in `featuredmeets`.
    ///   - eventId: The ID of the event (e.g. event document ID under `events`).
    ///   - eventName: Human-readable name for the event (Mens 10km, etc.).
    ///   - eventStart: Optional Date for the event start, used by notifications.
    func toggleFeaturedEventWatching(
        currentUserID: String,
        featuredMeetId: String,
        eventId: String,
        eventName: String,
        eventStart: Date?
    ) {
        let key = keyForFeaturedEvent(featuredMeetId: featuredMeetId, eventId: eventId)

        let ref = db
            .collection("users")
            .document(currentUserID)
            .collection("watchingFeaturedEvents")
            .document(key)

        if watchedFeaturedEventKeys.contains(key) {
            // Currently watching → unwatch
            print("🔁 WatchingStore: unwatching featured event key=\(key) for uid=\(currentUserID)")
            // Cancel any previously scheduled notification for this featured event.
            NotificationManager.shared.cancelWatchingNotificationForFeaturedEvent(eventKey: key)
            ref.delete { error in
                if let error = error {
                    print("⚠️ WatchingStore: failed to unwatch featured event: \(error.localizedDescription)")
                }
            }
        } else {
            // Not watching → start watching
            var data: [String: Any] = [
                "featuredMeetId": featuredMeetId,
                "eventId": eventId,
                "eventName": eventName,
                "createdAt": FieldValue.serverTimestamp()
            ]

            if let start = eventStart {
                data["eventStart"] = Timestamp(date: start)
            }

            print("🔁 WatchingStore: watching featured event key=\(key) for uid=\(currentUserID)")
            // Schedule a single watching notification for this featured event, if we have a start time.
            if let start = eventStart {
                // For now, use a single 20-minute reminder before the event.
                NotificationManager.shared.scheduleWatchingNotificationForFeaturedEvent(
                    eventKey: key,
                    eventName: eventName,
                    eventStartDate: start,
                    minutesBefore: 20
                )
            } else {
                print("ℹ️ WatchingStore: no start time for featured event \(eventName); skipping notification scheduling.")
            }
            ref.setData(data) { error in
                if let error = error {
                    print("⚠️ WatchingStore: failed to watch featured event: \(error.localizedDescription)")
                }
            }
        }
    }
}


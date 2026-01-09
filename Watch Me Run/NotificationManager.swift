//  NotificationManager.swift
//  Watch Me Run
//
//  Created by Andy Kent on 12/24/25.
//

import Foundation
import UserNotifications

/// Central place to manage local notification behavior for Watch Me Run.
///
/// For v1, this focuses on a single feature:
///  - A "pre-race details" reminder that fires 6 hours before a race start time
///    to nudge the runner to confirm their links (live results, stream, event home).
///
/// Design notes:
///  - This is intentionally lightweight and stateless; it wraps `UNUserNotificationCenter`.
///  - Authentication/UID and race models live elsewhere; we accept simple primitives
///    (raceID, raceName, raceStartDate, ownerUID) so we don't depend directly on app models.
@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    private let center = UNUserNotificationCenter.current()

    /// Ask iOS for authorization to send notifications, but only when needed.
    ///
    /// - Returns: `true` if the app is allowed to send alerts/sounds/badges, `false` otherwise.
    func requestAuthorizationIfNeeded() async -> Bool {
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            // Already allowed.
            return true
        case .denied:
            // User explicitly denied; respect that.
            return false
        case .notDetermined:
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                if granted {
                    print("✅ Notifications authorized")
                } else {
                    print("⚠️ Notifications not authorized")
                }
                return granted
            } catch {
                print("❌ Error requesting notification authorization: \(error)")
                return false
            }
        @unknown default:
            return false
        }
    }

    // MARK: - Pre-race details reminder

    /// Schedule a local notification to remind the race owner some hours before the race
    /// to double-check their race details (start time, links, etc.).
    ///
    /// - Parameters:
    ///   - raceID: Stable identifier for the race (e.g. UUID string or Firestore doc id).
    ///   - raceName: Name of the race, used in the notification text.
    ///   - raceStartDate: Exact start date/time of the race in the user's current time zone.
    ///   - ownerUID: Firebase UID of the race owner; used to namespace identifiers per user.
    ///   - hoursBefore: How many hours before the race start the reminder should fire.
    func schedulePreRaceDetailsReminder(
        raceID: String,
        raceName: String,
        raceStartDate: Date,
        ownerUID: String,
        hoursBefore: Int
    ) {
        let safeHours = max(1, hoursBefore)
        let reminderDate = raceStartDate.addingTimeInterval(-Double(safeHours) * 60 * 60)
        let now = Date()

        // If the reminder time is already in the past, skip scheduling.
        guard reminderDate > now else {
            print("ℹ️ Skipping pre-race details reminder for \(raceName) — reminder time already passed.")
            return
        }

        // Build the notification content.
        let content = UNMutableNotificationContent()
        content.title = "Race coming up"
        content.body = "\(raceName) is coming up soon! Please make sure to update your race information so friends can follow along."
        content.sound = .default

        // Translate reminderDate into calendar components for a non-repeating trigger.
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let identifier = preRaceDetailsIdentifier(raceID: raceID, ownerUID: ownerUID)

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule pre-race details reminder for \(raceName): \(error)")
            } else {
                print("✅ Scheduled pre-race details reminder for \(raceName) at \(reminderDate) (\(safeHours)h before)")
            }
        }
    }

    /// Cancel any previously scheduled pre-race details reminder for a given race.
    /// Useful when a race is edited (date changes) or deleted.
    func cancelPreRaceDetailsReminder(raceID: String, ownerUID: String) {
        let identifier = preRaceDetailsIdentifier(raceID: raceID, ownerUID: ownerUID)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        print("🗑️ Cancelled pre-race details reminder for raceID=\(raceID) ownerUID=\(ownerUID)")
    }

    /// Helper to generate a stable identifier for the 6-hour pre-race reminder.
    private func preRaceDetailsIdentifier(raceID: String, ownerUID: String) -> String {
        return "race-\(ownerUID)-\(raceID)-details6h"
    }

    // MARK: - Watching reminders (friends / pros / meets)

    /// Schedule up to two notifications for a race the user is watching.
    /// The first reminder is typically a short lead (e.g. 20 minutes), and the second
    /// is a longer lead (e.g. 12–24 hours). Both parameters are in minutes; pass 0 to skip.
    func scheduleWatchingNotificationsForRace(
        raceID: String,
        raceName: String,
        raceStartDate: Date,
        firstMinutesBefore: Int,
        secondMinutesBefore: Int
    ) {
        let now = Date()

        func makeTriggerDate(minutesBefore: Int) -> Date? {
            guard minutesBefore > 0 else { return nil }
            let date = raceStartDate.addingTimeInterval(-Double(minutesBefore) * 60)
            return date > now ? date : nil
        }

        // First (short lead) notification
        if let firstDate = makeTriggerDate(minutesBefore: firstMinutesBefore) {
            let content = UNMutableNotificationContent()
            content.title = "Race you're watching"
            content.body = "\(raceName) is about to start soon. Tap to follow along live."
            content.sound = .default

            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: firstDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let identifier = watchingIdentifier(raceID: raceID, slot: "first")

            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            center.add(request) { error in
                if let error = error {
                    print("❌ Failed to schedule FIRST watching notification for \(raceName): \(error)")
                } else {
                    print("✅ Scheduled FIRST watching notification for \(raceName) at \(firstDate) (\(firstMinutesBefore)m before)")
                }
            }
        }

        // Second (longer lead) notification
        if let secondDate = makeTriggerDate(minutesBefore: secondMinutesBefore) {
            let content = UNMutableNotificationContent()
            content.title = "Upcoming race you're watching"
            content.body = "\(raceName) is coming up. Get ready to follow the race!"
            content.sound = .default

            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: secondDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let identifier = watchingIdentifier(raceID: raceID, slot: "second")

            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            center.add(request) { error in
                if let error = error {
                    print("❌ Failed to schedule SECOND watching notification for \(raceName): \(error)")
                } else {
                    print("✅ Scheduled SECOND watching notification for \(raceName) at \(secondDate) (\(secondMinutesBefore)m before)")
                }
            }
        }
    }

    /// Cancel any previously scheduled watching notifications for a given race
    /// (both the first and second slots, if they exist).
    func cancelWatchingNotificationsForRace(raceID: String) {
        let identifiers = [
            watchingIdentifier(raceID: raceID, slot: "first"),
            watchingIdentifier(raceID: raceID, slot: "second")
        ]
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        print("🗑️ Cancelled watching notifications for raceID=\(raceID)")
    }

    /// Helper to generate unique identifiers for watching notifications.
    private func watchingIdentifier(raceID: String, slot: String) -> String {
        return "watch-\(raceID)-\(slot)"
    }

    // MARK: - Featured event watching notifications

    /// Schedule a single notification for a specific featured event the user is watching.
    /// Unlike full races/meets (which may get two reminders), individual events only get
    /// one reminder at `minutesBefore` to avoid over-notifying users.
    ///
    /// - Parameters:
    ///   - eventKey: Stable key for this event in the watching store (e.g. user+meet+event).
    ///   - eventName: Display name for the event (e.g. "Men's 1500m Final").
    ///   - eventStartDate: Exact start date/time of the event in the user's current time zone.
    ///   - minutesBefore: How many minutes before the event start the reminder should fire.
    func scheduleWatchingNotificationForFeaturedEvent(
        eventKey: String,
        eventName: String,
        eventStartDate: Date,
        minutesBefore: Int
    ) {
        let now = Date()
        guard minutesBefore > 0 else {
            print("ℹ️ Skipping featured event notification for \(eventName) — minutesBefore <= 0")
            return
        }

        let fireDate = eventStartDate.addingTimeInterval(-Double(minutesBefore) * 60)

        // If the reminder time is already in the past, skip scheduling.
        guard fireDate > now else {
            print("ℹ️ Skipping featured event notification for \(eventName) — reminder time already passed.")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Event you're watching"
        content.body = "\(eventName) is about to start. Tap to follow along."
        content.sound = .default

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let identifier = watchingFeaturedIdentifier(eventKey: eventKey)

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule featured event watching notification for \(eventName): \(error)")
            } else {
                print("✅ Scheduled featured event watching notification for \(eventName) at \(fireDate) (\(minutesBefore)m before)")
            }
        }
    }

    /// Cancel any previously scheduled watching notification for a specific featured event.
    func cancelWatchingNotificationForFeaturedEvent(eventKey: String) {
        let identifier = watchingFeaturedIdentifier(eventKey: eventKey)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        print("🗑️ Cancelled featured event watching notification for eventKey=\(eventKey)")
    }

    /// Helper to generate unique identifiers for featured event watching notifications.
    private func watchingFeaturedIdentifier(eventKey: String) -> String {
        return "watch-featured-\(eventKey)"
    }
}

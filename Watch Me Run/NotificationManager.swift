
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

    // MARK: - Pre-race details reminder (6 hours before)

    /// Schedule a local notification to remind the race owner 6 hours before the race
    /// to double-check their race details (start time, links, etc.).
    ///
    /// - Parameters:
    ///   - raceID: Stable identifier for the race (e.g. UUID string or Firestore doc id).
    ///   - raceName: Name of the race, used in the notification text.
    ///   - raceStartDate: Exact start date/time of the race in the user's current time zone.
    ///   - ownerUID: Firebase UID of the race owner; used to namespace identifiers per user.
    func schedulePreRaceDetailsReminder(
        raceID: String,
        raceName: String,
        raceStartDate: Date,
        ownerUID: String
    ) {
        // Compute the reminder time: 6 hours before the race start.
        let reminderDate = raceStartDate.addingTimeInterval(-6 * 60 * 60)
        let now = Date()

        // If the reminder time is already in the past, skip scheduling.
        guard reminderDate > now else {
            print("ℹ️ Skipping pre-race details reminder for \(raceName) — reminder time already passed.")
            return
        }

        // Build the notification content.
        let content = UNMutableNotificationContent()
        content.title = "Race coming up"
        content.body = "\(raceName) begins in 6 hours! Please make sure to update your race information so friends can follow along."
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
                print("✅ Scheduled pre-race details reminder for \(raceName) at \(reminderDate)")
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
}


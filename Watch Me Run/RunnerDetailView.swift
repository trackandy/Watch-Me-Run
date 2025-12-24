//
//  RunnerDetailView.swift
//  Watch Me Run
//
//  Created by Andy Kent on 12/23/25.
//

import SwiftUI

/// Lightweight race summary for displaying a runner's schedule in the Watching tab.
struct RunnerRaceSummary: Identifiable, Equatable {
    let name: String
    let distance: String
    let date: Date
    let timeZoneAbbrev: String  // "PT", "MT", "CT", "ET"
    let liveURL: URL?
    let streamURL: URL?
    let homeURL: URL?
    let isUpcoming: Bool
    
    /// Stable identifier for the underlying race when known (e.g., Firestore doc id).
    /// This is used for notification identifiers so we don't create duplicates when
    /// the view is rebuilt. For static/pro preview data this will be nil.
    let raceID: String?
    
    /// Local identity used by SwiftUI lists. This can change across reloads and should
    /// not be used for notification identifiers.
    let id: UUID
    
    /// Explicit initializer so that we can take an optional stable raceID (for Firestore-backed
    /// races) while still allowing call sites to omit it (e.g., previews and static data).
    init(
        name: String,
        distance: String,
        date: Date,
        timeZoneAbbrev: String,
        liveURL: URL?,
        streamURL: URL?,
        homeURL: URL?,
        isUpcoming: Bool,
        raceID: String? = nil,
        id: UUID = UUID()
    ) {
        self.name = name
        self.distance = distance
        self.date = date
        self.timeZoneAbbrev = timeZoneAbbrev
        self.liveURL = liveURL
        self.streamURL = streamURL
        self.homeURL = homeURL
        self.isUpcoming = isUpcoming
        self.raceID = raceID
        self.id = id
    }
}

/// The main sheet/card that appears when a user taps on a Pro or Friend row.
/// It shows the runner's name, a synced "Watching" toggle, and their upcoming/past events.
struct RunnerDetailView: View {
    let name: String

    /// Bound to the same boolean used to control the star/watching state in the list.
    @Binding var isWatching: Bool

    /// Static races for this runner (used for pros or previews).
    /// For friends with a Firebase UID, these are ignored and we instead use FriendRaceStore.
    let upcomingRaces: [RunnerRaceSummary]
    let pastRaces: [RunnerRaceSummary]

    /// Optional Firebase UID of this runner when they are a "friend" whose races live in Firestore.
    /// When non-nil, we use FriendRaceStore to load their races live from:
    /// users/{uid}/races
    let friendID: String?

    @StateObject private var friendRaceStore = FriendRaceStore()
    @State private var selectedRace: RunnerRaceSummary?
    @State private var isShowingRaceDetail: Bool = false

    // Notification settings for races I'm watching (friends/fans side)
    @AppStorage("watchingRemindersEnabled") private var watchingRemindersEnabled: Bool = true
    @AppStorage("watchingFirstMinutesBefore") private var watchingFirstMinutesBefore: Int = 20   // 0 = none
    @AppStorage("watchingSecondMinutesBefore") private var watchingSecondMinutesBefore: Int = 0   // 0 = none

    init(
        name: String,
        isWatching: Binding<Bool>,
        upcomingRaces: [RunnerRaceSummary],
        pastRaces: [RunnerRaceSummary],
        friendID: String? = nil
    ) {
        self.name = name
        self._isWatching = isWatching
        self.upcomingRaces = upcomingRaces
        self.pastRaces = pastRaces
        self.friendID = friendID
    }

    /// Computed races actually shown in the UI, based on whether we're using Firestore or static data.
    private var displayedUpcomingRaces: [RunnerRaceSummary] {
        guard let _ = friendID else { return upcomingRaces }
        return summaries(from: friendRaceStore.races, upcoming: true)
    }

    private var displayedPastRaces: [RunnerRaceSummary] {
        guard let _ = friendID else { return pastRaces }
        return summaries(from: friendRaceStore.races, upcoming: false)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header: Runner name
            Text(name)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(Color.wmrTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Watching toggle bar, visually in sync with the list pill
            WatchingToggleBar(isWatching: $isWatching)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Upcoming races section (matches Me tab styling conceptually)
            RunnerRacesSection(
                title: "Upcoming Races",
                races: displayedUpcomingRaces,
                onRaceTap: handleRaceTap
            )

            // Past races section
            RunnerRacesSection(
                title: "Past Races",
                races: displayedPastRaces,
                onRaceTap: handleRaceTap
            )

            Spacer(minLength: 8)
        }
        .padding(16)
        .background(
            Color.wmrBackground
                .ignoresSafeArea()
        )
        .onAppear {
            if let friendID = friendID {
                friendRaceStore.startListening(for: friendID)
            }
        }
        .onDisappear {
            friendRaceStore.stopListening()
        }
        .sheet(isPresented: $isShowingRaceDetail) {
            if let race = selectedRace {
                RaceDetailSheet(race: race)
            } else {
                EmptyView()
            }
        }
        .onChange(of: isWatching) { oldValue, newValue in
            handleWatchingToggle(isNowWatching: newValue)
        }
        .onChange(of: displayedUpcomingRaces) { oldValue, newValue in
            print("🔁 displayedUpcomingRaces changed from \(oldValue.count) to \(newValue.count); isWatching=\(isWatching)")
            // If the user is currently watching this runner, keep notifications in sync
            // with the latest set of upcoming races.
            if isWatching {
                handleWatchingToggle(isNowWatching: true)
            }
        }
    }
    /// Handle tapping on a race row by selecting it and showing the detail sheet.
    private func handleRaceTap(_ race: RunnerRaceSummary) {
        selectedRace = race
        isShowingRaceDetail = true
    }

    // MARK: - Watching notifications

    /// When the user toggles the "Watching" state for this runner, schedule or
    /// cancel notifications for all upcoming races according to the settings.
    private func handleWatchingToggle(isNowWatching: Bool) {
        print("🔔 handleWatchingToggle called isNowWatching=\(isNowWatching) enabled=\(watchingRemindersEnabled) first=\(watchingFirstMinutesBefore) second=\(watchingSecondMinutesBefore) displayedUpcoming=\(displayedUpcomingRaces.count)")
        
        // Use the races that are actually displayed as upcoming in this view.
        let futureRaces = displayedUpcomingRaces.filter { $0.date > Date() }
        print("🔔 futureRaces count = \(futureRaces.count)")
        
        if !isNowWatching {
            // No longer watching: cancel any pending notifications for these races.
            for race in futureRaces {
                let stableID = race.raceID ?? race.id.uuidString
                print("🗑️ Cancelling watching notifications because no longer watching for race=\(race.name) raceID=\(String(describing: race.raceID)) notificationID=\(stableID)")
                NotificationManager.shared.cancelWatchingNotificationsForRace(raceID: stableID)
            }
            return
        }
        
        // If watching reminders are disabled globally, cancel and exit.
        guard watchingRemindersEnabled else {
            print("⚙️ Watching reminders globally disabled; cancelling any existing notifications for these races.")
            for race in futureRaces {
                let stableID = race.raceID ?? race.id.uuidString
                NotificationManager.shared.cancelWatchingNotificationsForRace(raceID: stableID)
            }
            return
        }
        
        // At least one of the two timers must be > 0 to schedule anything.
        let firstMinutes = max(0, watchingFirstMinutesBefore)
        let secondMinutes = max(0, watchingSecondMinutesBefore)
        guard firstMinutes > 0 || secondMinutes > 0 else {
            print("⚙️ Both watching offsets are zero; cancelling notifications for these races.")
            for race in futureRaces {
                let stableID = race.raceID ?? race.id.uuidString
                NotificationManager.shared.cancelWatchingNotificationsForRace(raceID: stableID)
            }
            return
        }
        
        Task {
            let granted = await NotificationManager.shared.requestAuthorizationIfNeeded()
            guard granted else {
                print("🚫 Notification authorization not granted for watching races.")
                return
            }
            
            for race in futureRaces {
                let stableID = race.raceID ?? race.id.uuidString
                
                // Clear any existing notifications for this race first.
                print("🧹 Clearing and rescheduling watching notifications for race=\(race.name) raceID=\(String(describing: race.raceID)) notificationID=\(stableID) date=\(race.date) first=\(firstMinutes) second=\(secondMinutes)")
                NotificationManager.shared.cancelWatchingNotificationsForRace(raceID: stableID)
                
                NotificationManager.shared.scheduleWatchingNotificationsForRace(
                    raceID: stableID,
                    raceName: race.name,
                    raceStartDate: race.date,
                    firstMinutesBefore: firstMinutes,
                    secondMinutesBefore: secondMinutes
                )
            }
        }
    }

    /// Map UserRace models (from Firestore) into the lightweight RunnerRaceSummary
    /// used by RunnerDetailView for display.
    private func summaries(from userRaces: [UserRace], upcoming: Bool) -> [RunnerRaceSummary] {
        // Split into upcoming vs past using the same isInPast logic as the Me tab.
        let filtered: [UserRace] = userRaces.filter { race in
            upcoming ? !race.isInPast : race.isInPast
        }

        // For upcoming races, show soonest first; for past races, show most recent first.
        let sorted: [UserRace]
        if upcoming {
            sorted = filtered.sorted { $0.date < $1.date }
        } else {
            sorted = filtered.sorted { $0.date > $1.date }
        }

        let tzAbbrev = TimeZone.current.abbreviation() ?? "ET"

        return sorted.map { race in
            RunnerRaceSummary(
                name: race.name,
                distance: race.distance,
                date: race.date,
                timeZoneAbbrev: tzAbbrev,
                liveURL: race.liveResultsURL,
                streamURL: race.watchURL,
                homeURL: nil,
                isUpcoming: upcoming,
                raceID: race.id  // stable Firestore id for notifications
            )
        }
    }
}

/// Shared "Watching" pill used in both the row and the detail sheet.
/// Tapping toggles the watching status (star state).
struct WatchingToggleBar: View {
    @Binding var isWatching: Bool

    var body: some View {
        Button {
            isWatching.toggle()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isWatching ? "star.fill" : "star")
                Text("Watching")
            }
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundColor(isWatching ? Color.wmrAccentOrange : Color.wmrTextSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        isWatching ? Color.wmrAccentOrange : Color.wmrBorderSubtle,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

/// A section showing either Upcoming or Past races, styled similarly to the Me tab tables.
struct RunnerRacesSection: View {
    let title: String
    let races: [RunnerRaceSummary]
    let onRaceTap: ((RunnerRaceSummary) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(Color.wmrTextSecondary)

            if races.isEmpty {
                Text("No \(title.lowercased()) yet")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(Color.wmrTextSecondary.opacity(0.7))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 6)
            } else {
                VStack(spacing: 0) {
                    ForEach(races) { race in
                        if let onRaceTap = onRaceTap {
                            Button {
                                onRaceTap(race)
                            } label: {
                                RunnerRaceRow(race: race)
                            }
                            .buttonStyle(.plain)
                        } else {
                            RunnerRaceRow(race: race)
                        }

                        if race.id != races.last?.id {
                            Divider()
                                .background(Color.wmrBorderSubtle)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.wmrSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.wmrBorderSubtle, lineWidth: 1)
                        )
                )
            }
        }
    }
}
/// Bottom-sheet card that shows more details for a single race and provides
/// tappable buttons for live results, stream, and event home links.
struct RaceDetailSheet: View {
    let race: RunnerRaceSummary
    @Environment(\.openURL) private var openURL

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy"
        return formatter.string(from: race.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            Text(race.name)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(Color.wmrTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                Text(race.distance)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.wmrTextSecondary)

                Text("\(formattedDate) • \(race.timeZoneAbbrev)")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(Color.wmrTextSecondary)
            }

            VStack(spacing: 10) {
                linkButton(
                    title: "Live Results",
                    systemImage: "list.number",
                    url: race.liveURL
                )

                linkButton(
                    title: "Stream",
                    systemImage: "tv",
                    url: race.streamURL
                )

                linkButton(
                    title: "Event Home",
                    systemImage: "house",
                    url: race.homeURL
                )
            }

            Spacer(minLength: 8)
        }
        .padding(16)
        .background(
            Color.wmrBackground
                .ignoresSafeArea()
        )
        .presentationDetents([.fraction(0.5)])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private func linkButton(title: String, systemImage: String, url: URL?) -> some View {
        let isEnabled = (url != nil)

        Button {
            if let url = url {
                openURL(url)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .foregroundColor(isEnabled ? Color.wmrAccentOrange : Color.wmrTextSecondary.opacity(0.6))
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        isEnabled
                        ? Color.wmrSurfaceAlt
                        : Color.wmrSurfaceAlt.opacity(0.7)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isEnabled ? Color.wmrAccentOrange : Color.wmrBorderSubtle,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

/// Single race row, conceptually mirroring the Me tab's Race | Distance | Links | Date layout.
/// For now this is read-only; later we can add a tap gesture to show a race detail popup
/// with the three link buttons (live / stream / home).
struct RunnerRaceRow: View {
    let race: RunnerRaceSummary

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: race.date)
    }

    var body: some View {
        HStack(spacing: 8) {
            // Race name
            Text(race.name)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(Color.wmrTextPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Distance
            Text(race.distance)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(Color.wmrTextSecondary)
                .frame(width: 60, alignment: .leading)

            // Simple link-status indicator (we can refine to match Me tab's tiny boxes)
            HStack(spacing: 4) {
                if race.liveURL != nil {
                    Circle()
                        .fill(Color.wmrAccentOrange)
                        .frame(width: 6, height: 6)
                } else {
                    Circle()
                        .stroke(Color.wmrBorderSubtle, lineWidth: 1)
                        .frame(width: 6, height: 6)
                }

                if race.streamURL != nil {
                    Circle()
                        .fill(Color.wmrAccentOrange)
                        .frame(width: 6, height: 6)
                } else {
                    Circle()
                        .stroke(Color.wmrBorderSubtle, lineWidth: 1)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(width: 26, alignment: .center)

            // Date + time zone
            VStack(alignment: .trailing, spacing: 2) {
                Text(formattedDate)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(Color.wmrTextSecondary)

                Text(race.timeZoneAbbrev)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(Color.wmrTextSecondary.opacity(0.8))
            }
            .frame(width: 80, alignment: .trailing)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

struct RunnerDetailView_Previews: PreviewProvider {
    @State static var isWatching = true

    static var previews: some View {
        let now = Date()
        let sampleUpcoming = [
            RunnerRaceSummary(
                name: "NYC Indoor Grand Prix",
                distance: "3,000m",
                date: now.addingTimeInterval(60 * 60 * 24 * 7),
                timeZoneAbbrev: "ET",
                liveURL: URL(string: "https://example.com/live"),
                streamURL: URL(string: "https://example.com/stream"),
                homeURL: URL(string: "https://example.com/home"),
                isUpcoming: true
            ),
            RunnerRaceSummary(
                name: "Millrose Games",
                distance: "1,500m",
                date: now.addingTimeInterval(60 * 60 * 24 * 21),
                timeZoneAbbrev: "ET",
                liveURL: nil,
                streamURL: URL(string: "https://example.com/stream"),
                homeURL: nil,
                isUpcoming: true
            )
        ]

        let samplePast = [
            RunnerRaceSummary(
                name: "Diamond League Final",
                distance: "5,000m",
                date: now.addingTimeInterval(-60 * 60 * 24 * 14),
                timeZoneAbbrev: "ET",
                liveURL: nil,
                streamURL: nil,
                homeURL: nil,
                isUpcoming: false
            )
        ]

        RunnerDetailView(
            name: "Jakob Ingebrigtsen",
            isWatching: $isWatching,
            upcomingRaces: sampleUpcoming,
            pastRaces: samplePast
        )
        .previewLayout(.sizeThatFits)
        .padding()
        .background(Color.black)
    }
}

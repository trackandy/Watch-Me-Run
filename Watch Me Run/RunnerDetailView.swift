//
//  RunnerDetailView.swift
//  Watch Me Run
//
//  Created by Andy Kent on 12/23/25.
//

import SwiftUI

/// Lightweight race summary for displaying a runner's schedule in the Watching tab.
struct RunnerRaceSummary: Identifiable, Equatable {
    let id: UUID = UUID()
    let name: String
    let distance: String
    let date: Date
    let timeZoneAbbrev: String  // "PT", "MT", "CT", "ET"
    let liveURL: URL?
    let streamURL: URL?
    let homeURL: URL?
    let isUpcoming: Bool
}

/// The main sheet/card that appears when a user taps on a Pro or Friend row.
/// It shows the runner's name, a synced "Watching" toggle, and their upcoming/past events.
struct RunnerDetailView: View {
    let name: String

    /// Bound to the same boolean used to control the star/watching state in the list.
    @Binding var isWatching: Bool

    /// Races that belong to this runner.
    let upcomingRaces: [RunnerRaceSummary]
    let pastRaces: [RunnerRaceSummary]

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
                races: upcomingRaces
            )

            // Past races section
            RunnerRacesSection(
                title: "Past Races",
                races: pastRaces
            )

            Spacer(minLength: 8)
        }
        .padding(16)
        .background(
            Color.wmrBackground
                .ignoresSafeArea()
        )
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
                        RunnerRaceRow(race: race)

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

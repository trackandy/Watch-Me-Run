//
//  MeetCardView.swift
//  Watch Me Run
//
//  Created by Andy Kent on 12/9/25.
//

import SwiftUI

struct MeetCardView: View {
    let meet: Meet

    // MARK: - Date Formatting

    private static let weekdayFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "EEEE"        // e.g. "Wednesday"
        return df
    }()

    private static let monthFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "MMM"         // e.g. "Dec"
        return df
    }()

    private var startDayText: String {
        let date = meet.date
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)

        let weekday = Self.weekdayFormatter.string(from: date)
        let month = Self.monthFormatter.string(from: date)
        let suffix = Self.daySuffix(for: day)

        return "\(weekday), \(month) \(day)\(suffix)"
    }

    // MARK: - Color Theme

    private var theme: CardTheme {
        CardTheme.theme(for: meet)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Name at the top
            Text(meet.name)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(theme.accent)
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            Spacer()

            // Start day sits just above the buttons
            Text(startDayText)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(theme.accent.opacity(0.85))

            // Live / Watch buttons
            HStack(spacing: 8) {
                if let liveURL = meet.liveResultsURL {
                    LinkButton(label: "Live",
                               systemImage: "list.number",   // results-style icon
                               url: liveURL,
                               accentColor: theme.accent)
                }

                if let watchURL = meet.watchURL {
                    LinkButton(label: "Watch",
                               systemImage: "tv",           // TV icon to match Me tab
                               url: watchURL,
                               accentColor: theme.accent)
                }

                Spacer()
            }
            .padding(.top, 4)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            theme.background.opacity(0.98),
                            theme.background.opacity(0.8)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(theme.accent.opacity(0.7), lineWidth: 1)
        )
        .shadow(color: theme.background.opacity(0.55), radius: 4, x: 0, y: 3)
        .frame(width: 140, height: 140)   // slightly larger square
    }

    private static func daySuffix(for day: Int) -> String {
        let teens = 11...13
        if teens.contains(day % 100) {
            return "th"
        }
        switch day % 10 {
        case 1: return "st"
        case 2: return "nd"
        case 3: return "rd"
        default: return "th"
        }
    }

    private struct CardTheme {
        let background: Color
        let accent: Color

        private static let palettes: [(background: Color, accent: Color)] = [
            // Deep red
            (
                background: Color(red: 40/255, green: 4/255, blue: 10/255),
                accent:     Color(red: 255/255, green: 130/255, blue: 140/255)
            ),
            // Indigo / blue
            (
                background: Color(red: 10/255, green: 14/255, blue: 52/255),
                accent:     Color(red: 150/255, green: 180/255, blue: 255/255)
            ),
            // Deep green
            (
                background: Color(red: 3/255, green: 30/255, blue: 18/255),
                accent:     Color(red: 140/255, green: 230/255, blue: 180/255)
            ),
            // Purple
            (
                background: Color(red: 27/255, green: 8/255, blue: 41/255),
                accent:     Color(red: 210/255, green: 160/255, blue: 255/255)
            ),
            // Orange
            (
                background: Color(red: 42/255, green: 16/255, blue: 0/255),
                accent:     Color(red: 255/255, green: 190/255, blue: 120/255)
            )
        ]

        static func theme(for meet: Meet) -> CardTheme {
            let index = abs(meet.name.hashValue) % palettes.count
            let palette = palettes[index]
            return CardTheme(background: palette.background, accent: palette.accent)
        }
    }
}

struct LinkButton: View {
    let label: String
    let systemImage: String
    let url: URL
    let accentColor: Color

    init(label: String, systemImage: String, url: URL, accentColor: Color = .accentColor) {
        self.label = label
        self.systemImage = systemImage
        self.url = url
        self.accentColor = accentColor
    }

    var body: some View {
        Link(destination: url) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(accentColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(accentColor.opacity(0.16))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

struct MeetCardView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleMeet = SampleData.sampleMeets.first ?? Meet(
            date: Date(),
            name: "NCAA D1 Championships",
            level: "Collegiate",
            priority: .high,
            liveResultsURL: URL(string: "https://example.com/live"),
            watchURL: URL(string: "https://example.com/watch")
        )

        return MeetCardView(meet: sampleMeet)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}

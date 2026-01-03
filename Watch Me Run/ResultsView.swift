//
//  ResultsView.swift
//  Watch Me Run
//
//  Created by Andy Kent on 12/9/25.
//

import SwiftUI

struct ResultsView: View {
    @ObservedObject var store: MeetStore

    private let gridSpacing: CGFloat = 16


    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 8) {
                // Section header for current meets, sitting on a raised platform
                HStack {
                    Text("Current Events")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.wmrTextPrimary)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.wmrSurfaceAlt)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.wmrBorderSubtle, lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 6)
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Text("Live Results, Stream Links, and Event Home Pages")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(Color.wmrTextSecondary)
                    .padding(.horizontal, 24)
                    .padding(.top, 4)

                GeometryReader { geo in
                    let totalWidth = geo.size.width
                    let cardWidth: CGFloat = 140
                    // gutter = left gap = middle gap = right gap
                    let gutter = max((totalWidth - 2 * cardWidth) / 3, 0)

                    let sortedMeets = store.currentMeets.sorted {
                        if $0.priority != $1.priority {
                            return $0.priority.rawValue < $1.priority.rawValue
                        } else {
                            return $0.date < $1.date
                        }
                    }

                    VStack(spacing: gridSpacing) {
                        // Featured meet card that sits above the grid and spans the full row.
                        if let featured = store.featuredMeet {
                            FeaturedMeetCardView(
                                name: featured.name,
                                date: featured.date,
                                location: featured.location,
                                liveResultsURL: featured.liveResultsURL,
                                watchURL: featured.watchURL,
                                homeMeetURL: featured.homeMeetURL
                            )
                            .padding(.horizontal, gutter)
                        }

                        if sortedMeets.isEmpty {
                            Text("No current meets")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, gutter)
                                .padding(.top, 4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            LazyVGrid(
                                columns: [
                                    GridItem(.fixed(cardWidth), spacing: gutter),
                                    GridItem(.fixed(cardWidth), spacing: gutter)
                                ],
                                alignment: .leading,
                                spacing: gridSpacing // vertical spacing between rows
                            ) {
                                ForEach(sortedMeets) { meet in
                                    MeetCardView(meet: meet)
                                }
                            }
                            .padding(.horizontal, gutter)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, gridSpacing)
                }
                .frame(maxWidth: .infinity, minHeight: 0)
            }
        }
        
    }
}

struct FeaturedMeetCardView: View {
    let name: String
    let date: Date
    let location: String?
    let liveResultsURL: String?
    let watchURL: String?
    let homeMeetURL: String?

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d • h:mm a"
        return formatter.string(from: date)
    }

    var body: some View {
        // Define a bright yellow accent and darker yellow background tones
        let accentYellow = Color(red: 1.0, green: 0.9, blue: 0.2)      // bright yellow
        let darkYellow1  = Color(red: 0.35, green: 0.27, blue: 0.02)   // deep yellow/brown
        let darkYellow2  = Color(red: 0.45, green: 0.33, blue: 0.05)   // slightly lighter

        return VStack(alignment: .leading, spacing: 8) {
            // Top labels
            Text("Featured Event")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(accentYellow.opacity(0.9))

            Text(name)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(accentYellow)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            if let location = location, !location.isEmpty {
                Text(location)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(accentYellow.opacity(0.85))
            }

            // Date/time just above the buttons
            Text(formattedDate)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(accentYellow.opacity(0.9))
                .padding(.top, 4)

            // Button row: 3 icon buttons + a long "Tap to open card" button
            HStack(spacing: 8) {
                // Live results button
                featuredLinkButton(
                    systemName: "list.number", // matches the "results" concept
                    isEnabled: liveResultsURL != nil,
                    accentYellow: accentYellow
                )

                // Stream / watching button
                featuredLinkButton(
                    systemName: "tv.fill",
                    isEnabled: watchURL != nil,
                    accentYellow: accentYellow
                )

                // Meet home button
                featuredLinkButton(
                    systemName: "house.fill",
                    isEnabled: homeMeetURL != nil,
                    accentYellow: accentYellow
                )

                Spacer(minLength: 4)

                Button(action: {
                    // Placeholder: actual card-opening action to be wired later
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "rectangle.and.hand.point.up.left")
                            .font(.system(size: 11, weight: .medium))
                        Text("Tap to open card")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(accentYellow.opacity(0.18))
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(accentYellow.opacity(0.7), lineWidth: 0.8)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 6)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(
            maxWidth: .infinity,
            minHeight: 150,
            maxHeight: 170,
            alignment: .leading
        )
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            darkYellow1,
                            darkYellow2
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(accentYellow.opacity(0.7), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.45), radius: 10, x: 0, y: 6)
        )
    }

    /// Small helper for the three circular icon buttons, with a subtle disabled state.
    private func featuredLinkButton(systemName: String, isEnabled: Bool, accentYellow: Color) -> some View {
        Button(action: {
            // Placeholder: wire up actual deep-linking for featured meet URLs later
        }) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(accentYellow.opacity(isEnabled ? 0.22 : 0.06))
                )
                .overlay(
                    Circle()
                        .stroke(accentYellow.opacity(isEnabled ? 0.9 : 0.35), lineWidth: 0.8)
                )
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1.0 : 0.45)
        .disabled(!isEnabled)
    }
}

struct ResultsColumn: View {
    let title: String
    let subtitle: String
    let meets: [Meet]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Column header
            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 2)

            // Content
            if meets.isEmpty {
                Text("No meets")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            } else {
                ForEach(meets) { meet in
                    MeetCardView(meet: meet)
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }
}

// MARK: - Preview

struct ResultsView_Previews: PreviewProvider {
    static var previews: some View {
        let store = MeetStore()
        // Optional: Uncomment this to use sample data in preview
        /*
        store.meets = SampleData.sampleMeets
        */

        return ResultsView(store: store)
            .previewLayout(.device)
    }
}

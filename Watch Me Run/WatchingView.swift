//
//  WatchingView.swift
//  Watch Me Run
//
//  Created by Andy Kent on 12/9/25.
//

import SwiftUI

struct WatchingView: View {
    // Placeholder local state for favorites until real data is wired in
    @State private var favoriteMeets: Set<String> = []
    @State private var favoritePros: Set<String> = []
    @State private var favoriteRunners: Set<String> = []
    @State private var showingMeetsInfo: Bool = false
    @State private var showingProsInfo: Bool = false
    @State private var showingRunnersInfo: Bool = false

    private let featuredMeets: [String] = [
        "NCAA D1 Indoor Championships",
        "Olympic Games",
        "NCAA D1 Outdoor Championships",
        "World Championships",
        "Olympic Trials"
    ]

    private let featuredPros: [String] = [
        "Jakob Ingebrigtsen",
        "Grant Fisher",
        "Cole Hocker",
        "Faith Kipyegon",
        "Keely Hodgkinson"
    ]

    private let placeholderRunners: [String] = [
        "Joe Schmo 1",
        "Joe Schmo 2"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // MARK: - Header
                HStack {
                    Text("Get notified of meets and racers")
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

                // MARK: - Meets Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 6) {
                        Text("Featured Meets")
                            .font(.caption)
                            .foregroundColor(Color.wmrTextSecondary)

                        Button {
                            showingMeetsInfo = true
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.caption)
                                .foregroundColor(Color.wmrTextSecondary)
                        }
                        .buttonStyle(.plain)
                    }

                    WatchingSectionCard {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(featuredMeets, id: \.self) { meet in
                                WatchingRow(
                                    title: meet,
                                    isStarred: favoriteMeets.contains(meet),
                                    onToggleStar: {
                                        if favoriteMeets.contains(meet) {
                                            favoriteMeets.remove(meet)
                                        } else {
                                            favoriteMeets.insert(meet)
                                        }
                                    }
                                )

                                if meet != featuredMeets.last {
                                    Divider()
                                        .background(Color.wmrBorderSubtle)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)

                // MARK: - Pros Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 6) {
                        Text("Featured Pros")
                            .font(.caption)
                            .foregroundColor(Color.wmrTextSecondary)

                        Button {
                            showingProsInfo = true
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.caption)
                                .foregroundColor(Color.wmrTextSecondary)
                        }
                        .buttonStyle(.plain)
                    }

                    WatchingSectionCard {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(featuredPros, id: \.self) { pro in
                                WatchingRow(
                                    title: pro,
                                    isStarred: favoritePros.contains(pro),
                                    onToggleStar: {
                                        if favoritePros.contains(pro) {
                                            favoritePros.remove(pro)
                                        } else {
                                            favoritePros.insert(pro)
                                        }
                                    }
                                )

                                if pro != featuredPros.last {
                                    Divider()
                                        .background(Color.wmrBorderSubtle)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)

                // MARK: - Runners Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 6) {
                        Text("Runners")
                            .font(.caption)
                            .foregroundColor(Color.wmrTextSecondary)

                        Button {
                            showingRunnersInfo = true
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.caption)
                                .foregroundColor(Color.wmrTextSecondary)
                        }
                        .buttonStyle(.plain)
                    }

                    WatchingSectionCard {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(placeholderRunners, id: \.self) { runner in
                                WatchingRow(
                                    title: runner,
                                    isStarred: favoriteRunners.contains(runner),
                                    onToggleStar: {
                                        if favoriteRunners.contains(runner) {
                                            favoriteRunners.remove(runner)
                                        } else {
                                            favoriteRunners.insert(runner)
                                        }
                                    }
                                )

                                if runner != placeholderRunners.last {
                                    Divider()
                                        .background(Color.wmrBorderSubtle)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)

                Spacer(minLength: 12)
            }
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .alert("Featured Meets", isPresented: $showingMeetsInfo) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Get notified of featured meets, and be able to select all events you want to watch for these multi-day long meets. Login on the Me tab in order for the app to save your selections.")
        }
        .alert("Featured Pros", isPresented: $showingProsInfo) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Select your favorite pros to never miss them race! Login on the Me tab in order for the app to save your selections.")
        }
        .alert("Runners", isPresented: $showingRunnersInfo) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Watch your friends race! Note that their racing schedules are input by the individuals themselves.")
        }
    }
}

// MARK: - Supporting Views

struct WatchingSectionCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.wmrSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.wmrBorderSubtle, lineWidth: 1)
                )

            content
                .padding(14)
        }
    }
}

struct WatchingRow: View {
    let title: String
    let isStarred: Bool
    let onToggleStar: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.wmrTextPrimary)
            }

            Spacer()

            Button(action: onToggleStar) {
                Image(systemName: isStarred ? "star.fill" : "star")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isStarred ? Color.wmrAccentOrange : Color.wmrTextSecondary)
            }
            .buttonStyle(.plain)
        }
    }
}

struct WatchingView_Previews: PreviewProvider {
    static var previews: some View {
        WatchingView()
            .environment(\.colorScheme, .dark)
            .background(Color.wmrBackground)
    }
}

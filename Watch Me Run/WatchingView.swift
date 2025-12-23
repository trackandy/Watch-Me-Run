//
//  WatchingView.swift
//  Watch Me Run
//
//  Created by Andy Kent on 12/9/25.
//

import SwiftUI

struct FeaturedMeet: Identifiable, Hashable {
    let id = UUID()
    let key: String          // used to identify favorites
    let topLabel: String     // text shown above the circle
    let bottomLabel: String  // text shown below the circle

    // Either use a custom asset image (imageName) or an SF Symbol (symbolName)
    let symbolName: String?
    let imageName: String?
}

struct WatchingView: View {
    // Placeholder local state for favorites until real data is wired in
    @State private var favoriteMeets: Set<String> = []
    @State private var favoritePros: Set<String> = []
    @State private var favoriteRunners: Set<String> = []
    @State private var showingMeetsInfo: Bool = false
    @State private var showingProsInfo: Bool = false
    @State private var showingRunnersInfo: Bool = false
    @State private var isFeaturedMeetsExpanded: Bool = false
    @State private var isFeaturedProsExpanded: Bool = false
    @State private var isFriendsExpanded: Bool = false
    @State private var selectedRunnerName: String? = nil
    @State private var selectedRunnerIsPro: Bool = true
    @State private var isShowingRunnerDetail: Bool = false

    private let featuredMeets: [FeaturedMeet] = [
        FeaturedMeet(
            key: "Olympic Games",
            topLabel: "Olympic",
            bottomLabel: "Games",
            symbolName: nil,
            imageName: "olympicRings"
        ),
        FeaturedMeet(
            key: "World Championships",
            topLabel: "World",
            bottomLabel: "Champs",
            symbolName: "trophy.fill",
            imageName: nil
        ),
        FeaturedMeet(
            key: "Diamond League",
            topLabel: "Diamond",
            bottomLabel: "League",
            symbolName: "diamond.fill",
            imageName: nil
        ),
        FeaturedMeet(
            key: "US Olympic Trials",
            topLabel: "US",
            bottomLabel: "Trials",
            symbolName: "flag.checkered",
            imageName: nil
        ),
        FeaturedMeet(
            key: "NCAA Cross Country Champs",
            topLabel: "NCAA",
            bottomLabel: "XC Champs",
            symbolName: "figure.run",
            imageName: nil
        ),
        FeaturedMeet(
            key: "NCAA D1 Indoor Champs",
            topLabel: "NCAA D1",
            bottomLabel: "Indoors",
            symbolName: "figure.run.circle",
            imageName: nil
        ),
        FeaturedMeet(
            key: "NCAA D1 Outdoor Champs",
            topLabel: "NCAA D1",
            bottomLabel: "Outdoors",
            symbolName: "figure.run.circle.fill",
            imageName: nil
        ),
        FeaturedMeet(
            key: "US Indoor Champs",
            topLabel: "US",
            bottomLabel: "Indoors",
            symbolName: "building.columns",
            imageName: nil
        ),
        FeaturedMeet(
            key: "US Outdoor Champs",
            topLabel: "US",
            bottomLabel: "Outdoors",
            symbolName: "sun.max.fill",
            imageName: nil
        ),
        FeaturedMeet(
            key: "Millrose Games",
            topLabel: "Millrose",
            bottomLabel: "Games",
            symbolName: "sparkles",
            imageName: nil
        )
    ]

    private let featuredPros: [String] = [
        "Jakob Ingebrigtsen",
        "Grant Fisher",
        "Cole Hocker",
        "Faith Kipyegon",
        "Keely Hodgkinson",
        "Sifan Hassan",
        "Moh Ahmed",
        "Yared Nuguse",
        "Kenenisa Bekele",
        "Lamecha Girma",
        "Laura Muir",
        "Emma Coburn",
        "Karissa Schweizer",
        "Abby Steiner",
        "Athing Mu"
    ]

    private let placeholderRunners: [String] = [
        "friends_slot_1",
        "friends_slot_2",
        "friends_slot_3",
        "friends_slot_4",
        "friends_slot_5",
        "friends_slot_6",
        "friends_slot_7",
        "friends_slot_8",
        "friends_slot_9",
        "friends_slot_10"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // MARK: - Header
                HStack {
                    Text("Get notified of meets, pros, and friends races")
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

                        Spacer()

                        Button {
                            isFeaturedMeetsExpanded = true
                        } label: {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.caption)
                                .padding(4)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color.wmrSurfaceAlt.opacity(0.9))
                                )
                                .foregroundColor(Color.wmrTextSecondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Expand featured meets")
                    }

                    WatchingSectionCard {
                        FeaturedMeetsScroller(
                            meets: featuredMeets,
                            favoriteMeets: $favoriteMeets
                        )
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

                        Spacer()

                        Button {
                            isFeaturedProsExpanded = true
                        } label: {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.caption)
                                .padding(4)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color.wmrSurfaceAlt.opacity(0.9))
                                )
                                .foregroundColor(Color.wmrTextSecondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Expand featured pros")
                    }

                    WatchingSectionCard {
                        ScrollView(.vertical, showsIndicators: true) {
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
                                        },
                                        onRowTap: {
                                            selectedRunnerName = pro
                                            selectedRunnerIsPro = true
                                            isShowingRunnerDetail = true
                                        }
                                    )

                                    if pro != featuredPros.last {
                                        Divider()
                                            .background(Color.wmrBorderSubtle)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .frame(height: 190)
                    }
                }
                .padding(.horizontal, 16)

                // MARK: - Runners Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 6) {
                        Text("Friends")
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

                        Spacer()

                        Button {
                            isFriendsExpanded = true
                        } label: {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.caption)
                                .padding(4)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color.wmrSurfaceAlt.opacity(0.9))
                                )
                                .foregroundColor(Color.wmrTextSecondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Expand friends")
                    }

                    WatchingSectionCard {
                        ScrollView(.vertical, showsIndicators: true) {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(Array(placeholderRunners.enumerated()), id: \.element) { index, runnerKey in
                                    // First entry shows a helpful placeholder message,
                                    // remaining entries are visually "blank" lines
                                    let displayTitle = index == 0 ? "Add your first friends link" : ""

                                    WatchingRow(
                                        title: displayTitle,
                                        isStarred: favoriteRunners.contains(runnerKey),
                                        onToggleStar: {
                                            if favoriteRunners.contains(runnerKey) {
                                                favoriteRunners.remove(runnerKey)
                                            } else {
                                                favoriteRunners.insert(runnerKey)
                                            }
                                        },
                                        onRowTap: {
                                            // Only show a detail card if we actually have a non-empty title to show
                                            guard !displayTitle.isEmpty else { return }
                                            selectedRunnerName = displayTitle
                                            selectedRunnerIsPro = false
                                            isShowingRunnerDetail = true
                                        }
                                    )

                                    if runnerKey != placeholderRunners.last {
                                        Divider()
                                            .background(Color.wmrBorderSubtle)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .frame(height: 190)
                    }
                }
                .padding(.horizontal, 16)

                Spacer(minLength: 12)
            }
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .sheet(isPresented: $isFeaturedMeetsExpanded) {
            NavigationStack {
                ScrollView {
                    FeaturedMeetsGrid(
                        meets: featuredMeets,
                        favoriteMeets: $favoriteMeets
                    )
                    .padding(16)
                }
                .background(Color.wmrBackground.ignoresSafeArea())
                .navigationTitle("Featured Meets")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            isFeaturedMeetsExpanded = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $isFeaturedProsExpanded) {
            NavigationStack {
                ScrollView {
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
                                },
                                onRowTap: {
                                    selectedRunnerName = pro
                                    selectedRunnerIsPro = true
                                    isShowingRunnerDetail = true
                                }
                            )
                            Divider()
                                .background(Color.wmrBorderSubtle)
                        }
                    }
                    .padding(16)
                }
                .background(Color.wmrBackground.ignoresSafeArea())
                .navigationTitle("Featured Pros")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            isFeaturedProsExpanded = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $isFriendsExpanded) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(placeholderRunners.enumerated()), id: \.element) { index, runnerKey in
                            let displayTitle = index == 0 ? "Add your first friends link" : ""

                            WatchingRow(
                                title: displayTitle,
                                isStarred: favoriteRunners.contains(runnerKey),
                                onToggleStar: {
                                    if favoriteRunners.contains(runnerKey) {
                                        favoriteRunners.remove(runnerKey)
                                    } else {
                                        favoriteRunners.insert(runnerKey)
                                    }
                                },
                                onRowTap: {
                                    guard !displayTitle.isEmpty else { return }
                                    selectedRunnerName = displayTitle
                                    selectedRunnerIsPro = false
                                    isShowingRunnerDetail = true
                                }
                            )

                            Divider()
                                .background(Color.wmrBorderSubtle)
                        }
                    }
                    .padding(16)
                }
                .background(Color.wmrBackground.ignoresSafeArea())
                .navigationTitle("Friends")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            isFriendsExpanded = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingRunnerDetail) {
            Group {
                if let name = selectedRunnerName {
                    // Binding that keeps the sheet's Watching toggle in sync with the list star state
                    let isWatchingBinding: Binding<Bool> = Binding(
                        get: {
                            if selectedRunnerIsPro {
                                return favoritePros.contains(name)
                            } else {
                                return favoriteRunners.contains(name)
                            }
                        },
                        set: { newValue in
                            if selectedRunnerIsPro {
                                if newValue {
                                    favoritePros.insert(name)
                                } else {
                                    favoritePros.remove(name)
                                }
                            } else {
                                if newValue {
                                    favoriteRunners.insert(name)
                                } else {
                                    favoriteRunners.remove(name)
                                }
                            }
                        }
                    )

                    // Placeholder race arrays for now; can be wired to real data later
                    RunnerDetailView(
                        name: name,
                        isWatching: isWatchingBinding,
                        upcomingRaces: [],
                        pastRaces: []
                    )
                } else {
                    Text("No runner selected")
                        .padding()
                }
            }
            .presentationDetents([.fraction(0.5)])
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
        .alert("Friends", isPresented: $showingRunnersInfo) {
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
                .padding(10)
        }
    }
}

struct FeaturedMeetsGrid: View {
    let meets: [FeaturedMeet]
    @Binding var favoriteMeets: Set<String>

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .center, spacing: 12) {
            ForEach(meets) { meet in
                FeaturedMeetBubble(
                    meet: meet,
                    isStarred: favoriteMeets.contains(meet.key),
                    onToggleStar: {
                        if favoriteMeets.contains(meet.key) {
                            favoriteMeets.remove(meet.key)
                        } else {
                            favoriteMeets.insert(meet.key)
                        }
                    }
                )
            }
        }
    }
}

// PreferenceKeys for scroll measurement
private struct FeaturedMeetsContentWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 1
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct FeaturedMeetsScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct FeaturedMeetsScroller: View {
    let meets: [FeaturedMeet]
    @Binding var favoriteMeets: Set<String>

    @State private var contentWidth: CGFloat = 1
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let bubbleWidth: CGFloat = min(80, geometry.size.width / 3.0)

            VStack(spacing: 6) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 2) {
                        ForEach(meets) { meet in
                            FeaturedMeetBubble(
                                meet: meet,
                                isStarred: favoriteMeets.contains(meet.key),
                                onToggleStar: {
                                    if favoriteMeets.contains(meet.key) {
                                        favoriteMeets.remove(meet.key)
                                    } else {
                                        favoriteMeets.insert(meet.key)
                                    }
                                }
                            )
                            .frame(width: bubbleWidth)
                        }
                    }
                    .padding(.horizontal, 2)
                    .background(
                        GeometryReader { innerGeo in
                            let width = innerGeo.size.width
                            // Offset of the content relative to the ScrollView's coordinate space
                            let offset = -innerGeo.frame(in: .named("FeaturedMeetsScroll")).origin.x

                            Color.clear
                                .preference(key: FeaturedMeetsContentWidthKey.self, value: width)
                                .preference(key: FeaturedMeetsScrollOffsetKey.self, value: offset)
                        }
                    )
                }
                .coordinateSpace(name: "FeaturedMeetsScroll")

                // Small scroll position bar
                let trackWidth = geometry.size.width * 0.45
                let maxOffset = max(contentWidth - geometry.size.width, 1)
                let rawProgress = maxOffset > 0 ? scrollOffset / maxOffset : 0
                let progress = min(max(rawProgress, 0), 1)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.wmrBorderSubtle.opacity(0.7))
                        .frame(width: trackWidth, height: 3)

                    // Thumb indicating approximate scroll position
                    Capsule()
                        .fill(Color.wmrAccentOrange.opacity(0.9))
                        .frame(width: max(trackWidth * 0.15, trackWidth * 0.15),
                               height: 3)
                        .offset(x: trackWidth * progress)
                }
                .frame(height: 6)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(height: 96)
        .onPreferenceChange(FeaturedMeetsContentWidthKey.self) { newWidth in
            contentWidth = newWidth
        }
        .onPreferenceChange(FeaturedMeetsScrollOffsetKey.self) { newOffset in
            scrollOffset = newOffset
        }
    }
}

// Draws text along an arc with given radius and base angle, supporting clockwise/counterclockwise for correct orientation.
struct ArcText: View {
    let text: String
    let radius: CGFloat
    let baseAngle: Angle          // center angle of the arc (e.g., -90 for top, +90 for bottom)
    let anglePerCharacter: Angle
    let clockwise: Bool

    init(text: String, radius: CGFloat, baseAngle: Angle, anglePerCharacter: Angle, clockwise: Bool = true) {
        self.text = text
        self.radius = radius
        self.baseAngle = baseAngle
        self.anglePerCharacter = anglePerCharacter
        self.clockwise = clockwise
    }

    var body: some View {
        let characters = Array(text)
        return ZStack {
            ForEach(characters.indices, id: \.self) { index in
                let totalAngle = anglePerCharacter.degrees * Double(max(characters.count - 1, 0))
                let halfSpan = totalAngle / 2.0

                // For top text (clockwise = true), we sweep angles left-to-right.
                // For bottom text (clockwise = false), we sweep the opposite way so text is not "backwards".
                let startAngleDeg = baseAngle.degrees + (clockwise ? -halfSpan : halfSpan)
                let step = clockwise ? anglePerCharacter.degrees : -anglePerCharacter.degrees
                let currentAngle = Angle(degrees: startAngleDeg + Double(index) * step)

                let char = String(characters[index])

                Text(char)
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.wmrTextSecondary)
                    .offset(
                        x: CGFloat(cos(currentAngle.radians)) * radius,
                        y: CGFloat(sin(currentAngle.radians)) * radius
                    )
                    // Rotate each character so it follows the tangent of the circle at its position
                    .rotationEffect(currentAngle + .degrees(90))
            }
        }
    }
}

struct FeaturedMeetBubble: View {
    let meet: FeaturedMeet
    let isStarred: Bool
    let onToggleStar: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            // Top label in a straight line
            Text(meet.topLabel)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(Color.wmrTextSecondary)

            ZStack {
                Circle()
                    .fill(Color.wmrSurfaceAlt)
                    .overlay(
                        Circle()
                            .stroke(isStarred ? Color.wmrAccentOrange : Color.wmrBorderSubtle,
                                    lineWidth: isStarred ? 2 : 1)
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 3)

                if let imageName = meet.imageName {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .padding(6)
                } else if let symbolName = meet.symbolName {
                    Image(systemName: symbolName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color.wmrTextPrimary)
                }
            }
            .frame(width: 64, height: 64)

            // Bottom label in a straight line
            Text(meet.bottomLabel)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(Color.wmrTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            onToggleStar()
        }
    }
}

struct WatchingRow: View {
    let title: String
    let isStarred: Bool
    let onToggleStar: () -> Void
    let onRowTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.wmrTextPrimary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onRowTap()
            }

            Spacer()

            Button(action: onToggleStar) {
                HStack(spacing: 6) {
                    Image(systemName: isStarred ? "star.fill" : "star")
                        .font(.system(size: 14, weight: .semibold))

                    Text("Watching")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .foregroundColor(isStarred ? Color.wmrAccentOrange : Color.wmrTextSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(
                            isStarred ? Color.wmrAccentOrange : Color.wmrBorderSubtle,
                            lineWidth: 1
                        )
                )
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

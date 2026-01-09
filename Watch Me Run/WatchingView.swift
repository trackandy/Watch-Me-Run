//
//  WatchingView.swift
//  Watch Me Run
//
//  Created by Andy Kent on 12/9/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

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
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var watchingStore: WatchingStore

    // Placeholder local state for favorites until real data is wired in
    @State private var favoriteMeets: Set<String> = []
    @State private var favoritePros: Set<String> = []
    @State private var favoriteRunners: Set<String> = []
    @State private var friendIDs: [String] = []
    @State private var hasLoadedFriendsFromStorage: Bool = false
    @State private var isPresentingAddFriend: Bool = false
    @State private var isPresentingFriendSearch: Bool = false
    @State private var newFriendID: String = ""
    @State private var showingMeetsInfo: Bool = false
    @State private var showingProsInfo: Bool = false
    @State private var showingRunnersInfo: Bool = false
    @State private var isFeaturedMeetsExpanded: Bool = false
    @State private var isFeaturedProsExpanded: Bool = false
    @State private var isFriendsExpanded: Bool = false
    @State private var selectedRunnerName: String? = nil
    @State private var selectedRunnerIsPro: Bool = true
    @State private var isShowingRunnerDetail: Bool = false

    @State private var friendDisplayNames: [String: String] = [:]

    private let db = Firestore.firestore()

    private var isLoggedIn: Bool {
        authManager.firebaseUser != nil
    }

    /// Key used to persist the list of friend IDs locally.
    private let friendsStorageKey = "watchMeRun.friendIDs"

    private var emptyFriendsTitle: String {
        isLoggedIn
            ? "Add your first friends link"
            : "Log in on the Me tab to add friends"
    }

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


    var body: some View {
        ScrollView {
            mainContent
        }
        .onAppear {
            loadFriendsFromStorageIfNeeded()
        }
        .sheet(isPresented: $isFeaturedMeetsExpanded) {
            featuredMeetsSheet
        }
        .sheet(isPresented: $isFeaturedProsExpanded) {
            featuredProsSheet
        }
        .sheet(isPresented: $isFriendsExpanded) {
            friendsSheet
        }
        .sheet(isPresented: $isPresentingFriendSearch) {
            friendSearchSheet
        }
        .sheet(isPresented: $isPresentingAddFriend) {
            addFriendSheet
        }
        .sheet(isPresented: $isShowingRunnerDetail) {
            runnerDetailSheet
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

    @ViewBuilder
    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerSection
            featuredMeetsSection
            featuredProsSection
            friendsSection
            Spacer(minLength: 12)
        }
        .padding(.top, 8)
        .padding(.bottom, 32)
    }

    @ViewBuilder
    private var headerSection: some View {
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
    }

    @ViewBuilder
    private var featuredMeetsSection: some View {
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
    }

    @ViewBuilder
    private var featuredProsSection: some View {
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
                VStack(alignment: .center, spacing: 8) {
                    Spacer(minLength: 8)

                    Text("Coming soon")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.yellow)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)

                    Text("Featured pros and schedules will be available in a future update.")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(Color.wmrTextSecondary.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)

                    Spacer(minLength: 8)
                }
                .frame(height: 120)
            }
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var friendsSection: some View {
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

                Button {
                    if isLoggedIn {
                        isPresentingAddFriend = true
                    } else {
                        showingRunnersInfo = true
                    }
                } label: {
                    Image(systemName: "person.badge.plus")
                        .font(.caption)
                        .padding(4)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.wmrSurfaceAlt.opacity(0.9))
                        )
                        .foregroundColor(Color.wmrTextSecondary.opacity(isLoggedIn ? 1.0 : 0.4))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add friend by ID")

                Spacer()

                Button {
                    isPresentingFriendSearch = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Search")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(Color.wmrTextPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.wmrSurfaceAlt.opacity(0.95))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.wmrBorderSubtle, lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)

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
                        if friendIDs.isEmpty {
                            WatchingRow(
                                title: emptyFriendsTitle,
                                isStarred: false,
                                onToggleStar: {},
                                onRowTap: {
                                    if isLoggedIn {
                                        isPresentingAddFriend = true
                                    }
                                }
                            )
                        } else {
                            ForEach(friendIDs, id: \.self) { friendID in
                                WatchingRow(
                                    title: displayName(for: friendID),
                                    isStarred: watchingStore.watchedFriendIDs.contains(friendID),
                                    onToggleStar: {
                                        guard isLoggedIn, let uid = authManager.firebaseUser?.uid else { return }
                                        watchingStore.toggleFriendWatching(currentUserID: uid, friendID: friendID)
                                    },
                                    onRowTap: {
                                        selectedRunnerName = friendID
                                        selectedRunnerIsPro = false
                                        isShowingRunnerDetail = true
                                    }
                                )

                                if friendID != friendIDs.last {
                                    Divider()
                                        .background(Color.wmrBorderSubtle)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(height: 190)
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Sheet Content Helpers

    @ViewBuilder
    private var featuredMeetsSheet: some View {
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

    @ViewBuilder
    private var featuredProsSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    WatchingSectionCard {
                        VStack(alignment: .center, spacing: 12) {
                            Text("Featured Pros")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(Color.wmrTextPrimary)
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center)

                            Text("Tracking pros and their race schedules is coming soon.")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(Color.wmrTextSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)

                    Spacer(minLength: 0)
                }
                .padding(.bottom, 24)
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

    @ViewBuilder
    private var friendsSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if friendIDs.isEmpty {
                        WatchingRow(
                            title: emptyFriendsTitle,
                            isStarred: false,
                            onToggleStar: {},
                            onRowTap: {
                                if isLoggedIn {
                                    isPresentingAddFriend = true
                                }
                            }
                        )
                    } else {
                        ForEach(friendIDs, id: \.self) { friendID in
                            WatchingRow(
                                title: displayName(for: friendID),
                                isStarred: watchingStore.watchedFriendIDs.contains(friendID),
                                onToggleStar: {
                                    guard isLoggedIn, let uid = authManager.firebaseUser?.uid else { return }
                                    watchingStore.toggleFriendWatching(currentUserID: uid, friendID: friendID)
                                },
                                onRowTap: {
                                    selectedRunnerName = friendID
                                    selectedRunnerIsPro = false
                                    isShowingRunnerDetail = true
                                }
                            )
                            Divider()
                                .background(Color.wmrBorderSubtle)
                        }
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

    @ViewBuilder
    private var friendSearchSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("Search for a runner")) {
                    Text("Search by name coming soon. For now, you can paste a friend's ID from their Me tab share into the Add Friend screen.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .navigationTitle("Search Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        isPresentingFriendSearch = false
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var addFriendSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("Friend ID")) {
                    TextField("Paste ID from Me tab share", text: $newFriendID)
                        .textInputAutocapitalization(.none)
                        .autocorrectionDisabled(true)
                        .font(.system(size: 14, weight: .regular, design: .monospaced))
                }

                Section(footer: Text("Ask your friend to share their Watch Me Run link from the Me tab, then paste the ID here.")) {
                    EmptyView()
                }
            }
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        newFriendID = ""
                        isPresentingAddFriend = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        addFriendFromInput()
                    }
                    .disabled(newFriendID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    @ViewBuilder
    private var runnerDetailSheet: some View {
        Group {
            if let name = selectedRunnerName {
                RunnerDetailView(
                    name: name,
                    isWatching: watchingBinding(for: name),
                    upcomingRaces: [],
                    pastRaces: [],
                    friendID: selectedRunnerIsPro ? nil : name
                )
            } else {
                Text("No runner selected")
                    .padding()
            }
        }
        .presentationDetents([.fraction(0.5)])
    }

    private func displayName(for friendID: String) -> String {
        if let cached = friendDisplayNames[friendID], !cached.isEmpty {
            return cached
        } else {
            return friendID
        }
    }

    private func addFriendFromInput() {
        let trimmed = newFriendID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if !friendIDs.contains(trimmed) {
            friendIDs.append(trimmed)
            saveFriendsToStorage()
            fetchDisplayNameForFriend(id: trimmed)
        }

        newFriendID = ""
        isPresentingAddFriend = false
    }

    /// Load friends from UserDefaults the first time this view appears.
    private func loadFriendsFromStorageIfNeeded() {
        guard !hasLoadedFriendsFromStorage else { return }
        hasLoadedFriendsFromStorage = true

        if let stored = UserDefaults.standard.array(forKey: friendsStorageKey) as? [String] {
            friendIDs = stored
            // Fetch display names for all stored friend IDs
            for id in stored {
                fetchDisplayNameForFriend(id: id)
            }
        }
    }

    private func fetchDisplayNameForFriend(id: String) {
        // Avoid refetching if we already have a non-empty cached name
        if let existing = friendDisplayNames[id], !existing.isEmpty {
            return
        }

        db.collection("users").document(id).getDocument { snapshot, error in
            if let error = error {
                print("❌ Failed to fetch friend details for id \(id): \(error)")
                return
            }

            guard let data = snapshot?.data() else {
                print("ℹ️ No user details document found for friend id \(id)")
                return
            }

            let rawName = (data["name"] as? String) ?? ""
            let trimmedName = rawName.trimmingCharacters(in: .whitespacesAndNewlines)

            DispatchQueue.main.async {
                if trimmedName.isEmpty {
                    // Fallback to showing the raw ID if no name is set.
                    self.friendDisplayNames[id] = id
                } else {
                    self.friendDisplayNames[id] = trimmedName
                }
            }
        }
    }

    /// Persist the current list of friend IDs to UserDefaults.
    private func saveFriendsToStorage() {
        UserDefaults.standard.set(friendIDs, forKey: friendsStorageKey)
    }

    /// Construct a Binding<Bool> that keeps the "Watching" state in sync between
    /// the list row star and the RunnerDetailView toggle for the given runner name.
    private func watchingBinding(for name: String) -> Binding<Bool> {
        Binding(
            get: {
                if selectedRunnerIsPro {
                    return favoritePros.contains(name)
                } else {
                    return watchingStore.watchedFriendIDs.contains(name)
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
                    guard let uid = authManager.firebaseUser?.uid else { return }
                    // We simply toggle via WatchingStore; it will sync with Firestore
                    watchingStore.toggleFriendWatching(currentUserID: uid, friendID: name)
                }
            }
        )
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
            .environmentObject(AuthManager())
            .environment(\.colorScheme, .dark)
            .background(Color.wmrBackground)
    }
}


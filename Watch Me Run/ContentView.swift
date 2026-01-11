//
//  ContentView.swift
//  Watch Me Run
//
//  Created by Andy Kent on 12/9/25.
//

import SwiftUI

// MARK: - Root Tabs

enum RootTab: String, CaseIterable, Identifiable {
    case results = "Results"
    case watching = "Watching"
    case me = "Me"

    var id: String { rawValue }
}

enum DockSide: String, CaseIterable, Identifiable {
    case left
    case right

    var id: String { rawValue }

    var label: String {
        switch self {
        case .left:  return "Left"
        case .right: return "Right"
        }
    }
}

enum CompetitionLevel: String, CaseIterable, Identifiable {
    case amateur = "Amateur"
    case highSchool = "High School"
    case collegiate = "Collegiate"
    case professional = "Professional"

    var id: String { rawValue }
}

// MARK: - Content View

@MainActor
struct ContentView: View {
    @StateObject private var store = MeetStore()
    @State private var selectedTab: RootTab = .results
    @State private var showingSettings = false
    @AppStorage("filterSearchDockSide") private var dockSideRaw: String = DockSide.right.rawValue

    @State private var showingFilterPanel = false
    @State private var selectedLevels: Set<CompetitionLevel> = []

    @State private var showingSearchPanel = false
    @State private var searchQuery: String = ""

    private var dockSide: DockSide {
        DockSide(rawValue: dockSideRaw) ?? .right
    }

    var body: some View {
        ZStack {
            Color.wmrBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar: settings - logo - placeholder icon
                TopBarView(isShowingSettings: $showingSettings)

                // Copilot-style "bubble" tabs
                BubbleTabSelector(selectedTab: $selectedTab)
                    .padding(.horizontal)
                    .padding(8)

                // Swipeable pages for each tab
                TabView(selection: $selectedTab) {
                    ResultsView(store: store)
                        .tag(RootTab.results)

                    WatchingView()
                        .tag(RootTab.watching)

                    MeView()
                        .tag(RootTab.me)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }

            // Bottom-floating filter/search controls
            VStack {
                Spacer()

                HStack {
                    if dockSide == .left {
                        FilterSearchBar(
                            onFilterTap: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    showingFilterPanel = true
                                }
                            },
                            onSearchTap: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    showingSearchPanel = true
                                }
                            }
                        )
                        Spacer()
                    } else {
                        Spacer()
                        FilterSearchBar(
                            onFilterTap: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    showingFilterPanel = true
                                }
                            },
                            onSearchTap: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    showingSearchPanel = true
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            }

            // Overlay filter panel when active
            if showingFilterPanel {
                Color.black.opacity(0.001) // minimal backdrop for tap-to-dismiss
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            showingFilterPanel = false
                        }
                    }

                VStack {
                    Spacer()

                    FilterPanelView(
                        selectedLevels: $selectedLevels,
                        onClose: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                showingFilterPanel = false
                            }
                        }
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 72)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            if showingSearchPanel {
                Color.black.opacity(0.001) // minimal backdrop for tap-to-dismiss
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            showingSearchPanel = false
                        }
                    }

                VStack {
                    Spacer()

                    SearchPanelView(
                        query: $searchQuery,
                        onClose: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                showingSearchPanel = false
                            }
                        }
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 72)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showingFilterPanel)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showingSearchPanel)
        .onAppear {
            // Handy debug print: you should see this in the console when it runs
            print("📊 ContentView appeared with \(store.meets.count) meets loaded")
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
}

struct FilterSearchBar: View {
    var onFilterTap: () -> Void
    var onSearchTap: () -> Void

    var body: some View {
        ZStack {
            GeometryReader { geo in
                let height = geo.size.height
                let cornerRadius = height / 2

                // Base track shape (core oval)
                let coreShape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

                ZStack {
                    // Lane configuration
                    let laneCount = 6
                    let laneStep: CGFloat = 2.5 // distance between lane outlines
                    let trackSurfaceInset = -laneStep * CGFloat(laneCount)

                    // Clay-colored track surface around the green core (more translucent)
                    coreShape
                        .inset(by: trackSurfaceInset)
                        .fill(Color.wmrAccentOrange.opacity(0.45))

                    // Outer line around the whole figure, using background navy
                    coreShape
                        .inset(by: trackSurfaceInset)
                        .stroke(Color.wmrBackground.opacity(0.9), lineWidth: 1.1)

                    // Solid darker green core (infield), more grounded
                    coreShape
                        .fill(Color(red: 20/255, green: 100/255, blue: 70/255).opacity(0.9))
                        .overlay(
                            coreShape
                                .stroke(Color.white.opacity(0.2), lineWidth: 1.0)
                        )

                    // Lane lines drawn on top of the clay surface, using dark navy (background color)
                    ForEach(0..<laneCount, id: \.self) { index in
                        coreShape
                            .inset(by: -CGFloat(index) * laneStep)
                            .stroke(
                                (index == 0
                                 ? Color.white.opacity(0.18)
                                 : Color.wmrBackground.opacity(0.7)),
                                lineWidth: index == 0 ? 1.3 : 0.9
                            )
                    }

                    // Midfield "50-yard line" running down the inner oval
                    Rectangle()
                        .fill(Color.white.opacity(0.35))
                        .frame(width: 1.2, height: height * 0.7)

                    // Filter and Search icons on either side of the field
                    HStack {
                        Button(action: {
                            onFilterTap()
                        }) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.wmrTextPrimary)
                        }
                        .buttonStyle(.plain)

                        Spacer(minLength: 0)

                        Button(action: {
                            onSearchTap()
                        }) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.wmrTextPrimary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 14)
                }
            }
        }
        .frame(width: 95, height: 42)
        .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
        .padding(.vertical, 4)
    }
}

// MARK: - Filter Panel

struct FilterPanelView: View {
    @Binding var selectedLevels: Set<CompetitionLevel>
    var onClose: () -> Void

    private let cornerRadius: CGFloat = 22

    var body: some View {
        VStack(spacing: 12) {
            // Grab handle
            Capsule()
                .fill(Color.white.opacity(0.25))
                .frame(width: 36, height: 4)
                .padding(.top, 10)

            Text("Filter by level")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.wmrTextSecondary)
                .padding(.top, 2)

            VStack(spacing: 8) {
                ForEach(CompetitionLevel.allCases) { level in
                    Button(action: {
                        toggle(level)
                    }) {
                        HStack {
                            Text(level.rawValue)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.wmrTextPrimary)

                            Spacer()

                            if selectedLevels.contains(level) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.wmrAccentGreen)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.wmrTextTertiary)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.wmrSurface.opacity(selectedLevels.contains(level) ? 0.7 : 0.3))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 10)

            Button(action: onClose) {
                Text("Done")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.wmrAccentBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.20), lineWidth: 0.8)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private func toggle(_ level: CompetitionLevel) {
        if selectedLevels.contains(level) {
            selectedLevels.remove(level)
        } else {
            selectedLevels.insert(level)
        }
    }
}

// MARK: - Search Panel

struct SearchPanelView: View {
    @Binding var query: String
    var onClose: () -> Void

    @FocusState private var isFieldFocused: Bool

    private let cornerRadius: CGFloat = 22

    var body: some View {
        VStack(spacing: 12) {
            // Grab handle
            Capsule()
                .fill(Color.white.opacity(0.25))
                .frame(width: 36, height: 4)
                .padding(.top, 10)

            HStack {
                Text("Search runners")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.wmrTextSecondary)

                Spacer()
            }
            .padding(.horizontal, 16)

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.wmrTextTertiary)

                TextField("Name, team, or location", text: $query)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(false)
                    .focused($isFieldFocused)
                    .foregroundColor(.wmrTextPrimary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.wmrSurface.opacity(0.6))
            )
            .padding(.horizontal, 12)

            Button(action: onClose) {
                Text("Done")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.wmrAccentBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.20), lineWidth: 0.8)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .task {
            // Bring up the keyboard shortly after appearing
            await MainActor.run {
                isFieldFocused = true
            }
        }
    }
}

// MARK: - Preview

@MainActor
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.colorScheme, .light)
    }
}

// MARK: - Design System Colors
extension Color {
    // Backgrounds
    static let wmrBackground = Color(red: 5/255, green: 10/255, blue: 30/255)      // deep navy
    static let wmrSurface    = Color(red: 10/255, green: 20/255, blue: 45/255)     // cards
    static let wmrSurfaceAlt = Color(red: 15/255, green: 28/255, blue: 60/255)     // slightly higher elevation
    static let wmrTabNavy = Color(red: 40/255, green: 70/255, blue: 120/255)       // lighter navy for top tabs

    // Accents
    static let wmrAccentBlue   = Color(red: 70/255, green: 150/255, blue: 255/255)  // primary accent
    static let wmrAccentGreen  = Color(red: 60/255, green: 200/255, blue: 120/255)  // positive
    static let wmrAccentOrange = Color(red: 255/255, green: 160/255, blue: 60/255)  // negative / warning

    // Text
    static let wmrTextPrimary   = Color.white
    static let wmrTextSecondary = Color.white.opacity(0.6)
    static let wmrTextTertiary  = Color.white.opacity(0.4)

    // Borders / strokes
    static let wmrBorderSubtle  = Color.white.opacity(0.06)
}

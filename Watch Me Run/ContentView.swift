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

// MARK: - Content View

@MainActor
struct ContentView: View {
    @StateObject private var store = MeetStore()
    @State private var selectedTab: RootTab = .results
    @State private var showingSettings = false
    @AppStorage("filterSearchDockSide") private var dockSideRaw: String = DockSide.right.rawValue

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
                        FilterSearchBar()
                        Spacer()
                    } else {
                        Spacer()
                        FilterSearchBar()
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
        }
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
    var body: some View {
        HStack(spacing: 24) {
            Button {
                // TODO: Hook up filter sheet / menu
                print("Filter tapped")
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 40, height: 40)
            }

            Button {
                // TODO: Hook up search field / overlay
                print("Search tapped")
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 40, height: 40)
            }
        }
        
        .padding(.horizontal, 15)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 40)
                .fill(Color.white.opacity(0.10))
                .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 4)
        )
        .padding(.vertical, 4)
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

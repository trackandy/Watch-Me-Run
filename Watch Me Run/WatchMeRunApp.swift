//
//  WatchMeRunApp.swift
//  Watch Me Run
//
//  Created by Andy Kent on 12/9/25.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct WatchMeRunApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var raceStore = UserRaceStore()
    @StateObject private var userDetailsStore = UserDetailsStore()
    @StateObject private var watchingStore = WatchingStore()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            // Root of the app
            ContentView()
                .environmentObject(authManager)
                .environmentObject(raceStore)
                .environmentObject(userDetailsStore)
                .environmentObject(watchingStore)
                .preferredColorScheme(.dark)
                .onAppear {
                    // If the user is already signed in when the app launches,
                    // start listening to their races, details, and watching state.
                    if let uid = authManager.firebaseUser?.uid {
                        raceStore.startListening(for: uid)
                        userDetailsStore.startListening(for: uid)
                        watchingStore.startListening(for: uid)
                    }
                }
                .onChange(of: authManager.firebaseUser?.uid, initial: false) { oldUid, newUid in
                    // When auth state changes, update the race, details, and watching listeners.
                    if let uid = newUid {
                        raceStore.startListening(for: uid)
                        userDetailsStore.startListening(for: uid)
                        watchingStore.startListening(for: uid)
                    } else {
                        raceStore.stopListening()
                        userDetailsStore.stopListening()
                        watchingStore.stopListening()
                    }
                }
        }
    }
}

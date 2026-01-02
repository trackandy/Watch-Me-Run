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
                .preferredColorScheme(.dark)
                .onAppear {
                    // If the user is already signed in when the app launches,
                    // start listening to their races and details.
                    if let uid = authManager.firebaseUser?.uid {
                        raceStore.startListening(for: uid)
                        userDetailsStore.startListening(for: uid)
                    }
                }
                .onChange(of: authManager.firebaseUser?.uid, initial: false) { oldUid, newUid in
                    // When auth state changes, update the race and details listeners.
                    if let uid = newUid {
                        raceStore.startListening(for: uid)
                        userDetailsStore.startListening(for: uid)
                    } else {
                        raceStore.stopListening()
                        userDetailsStore.stopListening()
                    }
                }
        }
    }
}

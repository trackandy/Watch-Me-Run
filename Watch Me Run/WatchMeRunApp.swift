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

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            // Root of the app
            ContentView()
                .environmentObject(authManager)
                .environmentObject(raceStore)
                .preferredColorScheme(.dark)
                .onAppear {
                    // If the user is already signed in when the app launches,
                    // start listening to their races.
                    if let uid = authManager.firebaseUser?.uid {
                        raceStore.startListening(for: uid)
                    }
                }
                .onChange(of: authManager.firebaseUser?.uid, initial: false) { oldUid, newUid in
                    // When auth state changes, update the race listener.
                    if let uid = newUid {
                        raceStore.startListening(for: uid)
                    } else {
                        raceStore.stopListening()
                    }
                }
        }
    }
}

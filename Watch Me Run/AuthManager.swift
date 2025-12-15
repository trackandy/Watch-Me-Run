//
//  AuthManager.swift
//  Watch Me Run
//
//  Created by Andy Kent on 12/14/25.
//

import Foundation
import Combine
import FirebaseAuth

final class AuthManager: ObservableObject {
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    @Published var firebaseUser: User?

    init() {
        // Grab current user (if any) on startup
        self.firebaseUser = Auth.auth().currentUser

        // Listen for changes in auth state
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.firebaseUser = user
        }
    }

    var isLoggedIn: Bool {
        firebaseUser != nil
    }

    // For now, a simple placeholder sign-in method
    func signInAnonymously() {
        Auth.auth().signInAnonymously { [weak self] result, error in
            if let error = error {
                print("❌ Failed to sign in anonymously: \(error)")
                return
            }
            self?.firebaseUser = result?.user
            print("✅ Signed in anonymously as \(result?.user.uid ?? "unknown")")
        }
    }

    func signInWithApple(idToken: String, nonce: String) {
        let credential = OAuthProvider.appleCredential(
            withIDToken: idToken,
            rawNonce: nonce,
            fullName: nil
        )

        Auth.auth().signIn(with: credential) { [weak self] result, error in
            if let error = error {
                print("❌ Failed to sign in with Apple: \(error)")
                return
            }

            self?.firebaseUser = result?.user
            if let uid = result?.user.uid {
                print("✅ Signed in with Apple as \(uid)")
            }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            firebaseUser = nil
            print("✅ Signed out")
        } catch {
            print("❌ Failed to sign out: \(error)")
        }
    }
}

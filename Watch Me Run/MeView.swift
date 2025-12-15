//
//  MeView.swift
//  Watch Me Run
//
//  Created by Andy Kent on 12/9/25.
//

import SwiftUI
import FirebaseAuth
import AuthenticationServices
import CryptoKit

struct MeView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var isPresentingRaceInput = false
    @State private var currentNonce: String?

    private var isLoggedIn: Bool {
        authManager.isLoggedIn
    }

    private var displayName: String {
        authManager.firebaseUser?.displayName ?? "Runner"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // MARK: - Header
                HStack {
                    Text("Allow for friends to watch you race")
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

                // MARK: - Account / Login
                VStack(alignment: .leading, spacing: 12) {
                    Text("Account")
                        .font(.caption)
                        .foregroundColor(Color.wmrTextSecondary)

                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.wmrSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.wmrBorderSubtle, lineWidth: 1)
                            )

                        HStack(spacing: 12) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(
                                    isLoggedIn
                                    ? Color.green.opacity(0.9)
                                    : Color.red.opacity(0.9)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                if isLoggedIn {
                                    Text(displayName)
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundColor(Color.wmrTextPrimary)

                                    Text("Your races are synced to this account.")
                                        .font(.caption)
                                        .foregroundColor(Color.wmrTextSecondary)
                                } else {
                                    Text("You’re not logged in")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundColor(Color.wmrTextPrimary)

                                    Text("Sign in to save and sync your race schedule.")
                                        .font(.caption)
                                        .foregroundColor(Color.wmrTextSecondary)
                                }
                            }

                            Spacer()

                            if isLoggedIn {
                                Button {
                                    authManager.signOut()
                                } label: {
                                    Text("Sign out")
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .foregroundColor(Color.wmrAccentBlue)
                                }
                            } else {
                                SignInWithAppleButton(.signIn) { request in
                                    let nonce = randomNonceString()
                                    currentNonce = nonce
                                    request.requestedScopes = [.fullName, .email]
                                    request.nonce = sha256(nonce)
                                } onCompletion: { result in
                                    switch result {
                                    case .success(let authResult):
                                        guard let appleIDCredential = authResult.credential as? ASAuthorizationAppleIDCredential else {
                                            print("❌ Unable to cast credential to ASAuthorizationAppleIDCredential")
                                            return
                                        }

                                        guard let nonce = currentNonce else {
                                            print("❌ Invalid state: no login request nonce")
                                            return
                                        }

                                        guard let appleIDToken = appleIDCredential.identityToken,
                                              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                                            print("❌ Unable to fetch identity token")
                                            return
                                        }

                                        authManager.signInWithApple(idToken: idTokenString, nonce: nonce)

                                    case .failure(let error):
                                        print("❌ Sign in with Apple failed: \(error.localizedDescription)")
                                    }
                                }
                                .signInWithAppleButtonStyle(.whiteOutline)
                                .frame(height: 32)
                            }
                        }
                        .padding(14)
                    }
                }
                .padding(.horizontal, 16)

                // MARK: - Share Link Card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Share")
                        .font(.caption)
                        .foregroundColor(Color.wmrTextSecondary)

                    Button {
                        // TODO: Hook up real share sheet with deep link
                        print("Share profile link tapped")
                    } label: {
                        HStack(alignment: .center, spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.wmrAccentBlue.opacity(0.18))

                                Image(systemName: "link")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color.wmrAccentBlue)
                            }
                            .frame(width: 36, height: 36)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Share your Watch Me Run link")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color.wmrTextPrimary)

                                Text("Send this to friends so they can follow your races.")
                                    .font(.caption)
                                    .foregroundColor(Color.wmrTextSecondary)
                                    .lineLimit(2)
                            }

                            Spacer()

                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color.wmrTextSecondary)
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.wmrSurface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(Color.wmrBorderSubtle, lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)

                // MARK: - Input Race
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your races")
                        .font(.caption)
                        .foregroundColor(Color.wmrTextSecondary)

                    Button {
                        isPresentingRaceInput = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Input Race")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                        }
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.orange.opacity(0.85))
                        )
                        .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)

                    // Upcoming races
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Upcoming")
                            .font(.caption)
                            .foregroundColor(Color.wmrTextSecondary)

                        VStack(spacing: 0) {
                            // Header row
                            HStack {
                                Text("Race")
                                    .font(.caption2)
                                    .foregroundColor(Color.wmrTextTertiary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text("Distance")
                                    .font(.caption2)
                                    .foregroundColor(Color.wmrTextTertiary)
                                    .frame(width: 70, alignment: .center)

                                Text("Date")
                                    .font(.caption2)
                                    .foregroundColor(Color.wmrTextTertiary)
                                    .frame(width: 110, alignment: .trailing)
                            }
                            .padding(.horizontal, 12)
                            .padding(.top, 8)
                            .padding(.bottom, 4)

                            Divider()
                                .background(Color.wmrBorderSubtle)

                            // Placeholder upcoming race
                            HStack {
                                Text("Peachtree Road Race")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color.wmrTextPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text("10 km")
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundColor(Color.wmrTextSecondary)
                                    .frame(width: 70, alignment: .center)

                                Text("July 4th, 2026")
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundColor(Color.wmrTextSecondary)
                                    .frame(width: 110, alignment: .trailing)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.wmrSurface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color.wmrBorderSubtle, lineWidth: 1)
                                )
                        )
                    }

                    // Past races
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Past")
                            .font(.caption)
                            .foregroundColor(Color.wmrTextSecondary)

                        VStack(spacing: 0) {
                            // Header row
                            HStack {
                                Text("Race")
                                    .font(.caption2)
                                    .foregroundColor(Color.wmrTextTertiary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text("Distance")
                                    .font(.caption2)
                                    .foregroundColor(Color.wmrTextTertiary)
                                    .frame(width: 70, alignment: .center)

                                Text("Date")
                                    .font(.caption2)
                                    .foregroundColor(Color.wmrTextTertiary)
                                    .frame(width: 110, alignment: .trailing)
                            }
                            .padding(.horizontal, 12)
                            .padding(.top, 8)
                            .padding(.bottom, 4)

                            Divider()
                                .background(Color.wmrBorderSubtle)

                            // Placeholder past race
                            HStack {
                                Text("NYC Marathon")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color.wmrTextPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text("26.2 M")
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundColor(Color.wmrTextSecondary)
                                    .frame(width: 70, alignment: .center)

                                Text("November 3rd, 2026")
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundColor(Color.wmrTextSecondary)
                                    .frame(width: 110, alignment: .trailing)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.wmrSurface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color.wmrBorderSubtle, lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal, 16)

                Spacer(minLength: 12)
            }
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .sheet(isPresented: $isPresentingRaceInput) {
            RaceInputSheet()
        }
    }
}

// MARK: - Sign in with Apple helpers

private func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length

    while remainingLength > 0 {
        var random: UInt8 = 0
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }

        if random < charset.count {
            result.append(charset[Int(random)])
            remainingLength -= 1
        }
    }

    return result
}

private func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    return hashedData.compactMap { String(format: "%02x", $0) }.joined()
}

struct RaceInputSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var raceName: String = ""
    @State private var raceDate: Date = Date()
    @State private var raceDistance: String = ""
    @State private var liveResultsLink: String = ""
    @State private var watchingLink: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Race") {
                    TextField("Race name", text: $raceName)

                    DatePicker("Race date & time",
                                selection: $raceDate,
                                displayedComponents: [.date, .hourAndMinute])
                }

                Section("Details") {
                    TextField("Distance (e.g. 5K, Half)", text: $raceDistance)
                }

                Section("Links") {
                    TextField("Live results link", text: $liveResultsLink)
                        .keyboardType(.URL)
                        .textContentType(.URL)

                    TextField("Watching link", text: $watchingLink)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                }
            }
            .navigationTitle("Input Race")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // TODO: Validate & save race to the user's account
                        dismiss()
                    }
                }
            }
        }
    }
}

struct MeView_Previews: PreviewProvider {
    static var previews: some View {
        MeView()
            .environmentObject(AuthManager())
            .environment(\.colorScheme, .dark)
            .background(Color.wmrBackground)
    }
}

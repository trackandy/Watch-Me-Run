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

private let userRaceDateFormatter: DateFormatter = {
    let df = DateFormatter()
    df.dateStyle = .medium
    df.timeStyle = .none
    return df
}()

private let userRaceDayFormatter: DateFormatter = {
    let df = DateFormatter()
    df.dateFormat = "MMM d"
    return df
}()

private let userRaceDateTimeFormatter: DateFormatter = {
    let df = DateFormatter()
    df.dateFormat = "MMM d, HH:mm"
    return df
}()

struct MeView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var raceStore: UserRaceStore
    @Environment(\.openURL) private var openURL
    @State private var isPresentingRaceInput = false
    @State private var isPresentingRunnerDetails = false
    @State private var currentNonce: String?
    @State private var raceBeingEdited: UserRace?

    // Notification settings for this user (owner / my races)
    @AppStorage("ownerPreRaceReminderEnabled") private var ownerPreRaceEnabled: Bool = true
    @AppStorage("ownerPreRaceHoursBefore") private var ownerPreRaceHoursBefore: Int = 6

    private var isLoggedIn: Bool {
        authManager.isLoggedIn
    }

    private var displayName: String {
        authManager.firebaseUser?.displayName ?? "Runner"
    }

    private var upcomingRaces: [UserRace] {
        raceStore.races
            .filter { !$0.isInPast }
            .sorted { $0.date > $1.date }
    }

    private var pastRaces: [UserRace] {
        raceStore.races
            .filter { $0.isInPast }
            .sorted { $0.date > $1.date }
    }

    private var shareProfileMessage: String {
        let uid = authManager.firebaseUser?.uid ?? "your-uid"
        let name = authManager.firebaseUser?.displayName

        if let name = name, !name.isEmpty {
            return "Follow \(name)'s races in Watch Me Run! Use this ID in the app: \(uid)"
        } else {
            return "Follow my races in Watch Me Run! Use this ID in the Watch Me Run app: \(uid)"
        }
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

                    ShareLink(item: shareProfileMessage) {
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

                    HStack(spacing: 10) {
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

                        Button {
                            isPresentingRunnerDetails = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "figure.run.circle")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("Runner Details")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                            }
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.wmrAccentBlue.opacity(0.85))
                            )
                            .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)
                    }

                    // Upcoming races
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Upcoming")
                            .font(.caption)
                            .foregroundColor(Color.wmrTextSecondary)

                        VStack(spacing: 0) {
                            // Header row
                            HStack(spacing: 6) {
                                Text("Race")
                                    .font(.caption2)
                                    .foregroundColor(Color.wmrTextTertiary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text("Distance")
                                    .font(.caption2)
                                    .foregroundColor(Color.wmrTextTertiary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                    .frame(width: 60, alignment: .center)

                                Text("Links")
                                    .font(.caption2)
                                    .foregroundColor(Color.wmrTextTertiary)
                                    .frame(width: 40, alignment: .center)

                                Text("Date")
                                    .font(.caption2)
                                    .foregroundColor(Color.wmrTextTertiary)
                                    .frame(width: 104, alignment: .trailing)
                            }
                            .padding(.horizontal, 12)
                            .padding(.top, 8)
                            .padding(.bottom, 4)

                            Divider()
                                .background(Color.wmrBorderSubtle)

                            if upcomingRaces.isEmpty {
                                HStack {
                                    Text("No upcoming races yet")
                                        .font(.system(size: 13, weight: .regular, design: .rounded))
                                        .foregroundColor(Color.wmrTextSecondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                            } else {
                                let groups = Dictionary(grouping: upcomingRaces) { race in
                                    Calendar.current.component(.year, from: race.date)
                                }
                                let sortedYears = groups.keys.sorted(by: >)
                                let lastYear = sortedYears.last ?? sortedYears[0]

                                ForEach(sortedYears, id: \.self) { year in
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(String(year))
                                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                                .foregroundColor(Color.wmrTextSecondary)
                                            Spacer()
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.top, 6)
                                        .padding(.bottom, 2)

                                        Divider()
                                            .background(Color.wmrBorderSubtle)
                                            .padding(.horizontal, 12)

                                        let racesForYear = groups[year]!.sorted { $0.date > $1.date }

                                        ForEach(Array(racesForYear.enumerated()), id: \.element.id) { index, race in
                                            let isSoonestUpcoming = (year == lastYear && index == racesForYear.count - 1)
                                            let hasLiveLink = (race.liveResultsURL != nil)
                                            let hasWatchLink = (race.watchURL != nil)

                                            HStack(spacing: 6) {
                                                Text(race.name)
                                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                                    .foregroundColor(Color.wmrTextPrimary)
                                                    .lineLimit(2)
                                                    .minimumScaleFactor(0.9)
                                                    .frame(maxWidth: .infinity, alignment: .leading)

                                                Text(race.distance)
                                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                                    .foregroundColor(Color.wmrTextSecondary)
                                                    .frame(width: 60, alignment: .center)

                                                HStack(spacing: 4) {
                                                    // Live results status (left)
                                                    Button {
                                                        if let url = race.liveResultsURL {
                                                            openURL(url)
                                                        }
                                                    } label: {
                                                        Image(systemName: "list.number")
                                                            .font(.system(size: 8, weight: .semibold))
                                                            .padding(2)
                                                            .background(
                                                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                                                    .fill(Color.gray.opacity(hasLiveLink ? 0.25 : 0.12))
                                                            )
                                                    }
                                                    .foregroundColor(hasLiveLink ? Color.green.opacity(0.9) : Color.gray.opacity(0.7))
                                                    .disabled(!hasLiveLink)

                                                    // Watching status (right)
                                                    Button {
                                                        if let url = race.watchURL {
                                                            openURL(url)
                                                        }
                                                    } label: {
                                                        Image(systemName: "tv")
                                                            .font(.system(size: 8, weight: .semibold))
                                                            .padding(2)
                                                            .background(
                                                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                                                    .fill(Color.gray.opacity(hasWatchLink ? 0.25 : 0.12))
                                                            )
                                                    }
                                                    .foregroundColor(hasWatchLink ? Color.green.opacity(0.9) : Color.gray.opacity(0.7))
                                                    .disabled(!hasWatchLink)
                                                }
                                                .frame(width: 40, alignment: .center)

                                                Text("\(userRaceDateTimeFormatter.string(from: race.date)) \(currentTimeZoneCode())")
                                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                                    .foregroundColor(Color.wmrTextSecondary)
                                                    .frame(width: 104, alignment: .trailing)
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                    .stroke(isSoonestUpcoming ? Color.yellow.opacity(0.9) : Color.clear,
                                                            lineWidth: 1.5)
                                            )
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                raceBeingEdited = race
                                            }
                                        }
                                    }
                                    .padding(.bottom, 4)
                                }
                            }
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
                            HStack(spacing: 6) {
                                Text("Race")
                                    .font(.caption2)
                                    .foregroundColor(Color.wmrTextTertiary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text("Distance")
                                    .font(.caption2)
                                    .foregroundColor(Color.wmrTextTertiary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                    .frame(width: 60, alignment: .center)

                                Text("Links")
                                    .font(.caption2)
                                    .foregroundColor(Color.wmrTextTertiary)
                                    .frame(width: 40, alignment: .center)

                                Text("Date")
                                    .font(.caption2)
                                    .foregroundColor(Color.wmrTextTertiary)
                                    .frame(width: 104, alignment: .trailing)
                            }
                            .padding(.horizontal, 12)
                            .padding(.top, 8)
                            .padding(.bottom, 4)

                            Divider()
                                .background(Color.wmrBorderSubtle)

                            if pastRaces.isEmpty {
                                HStack {
                                    Text("No past races yet")
                                        .font(.system(size: 13, weight: .regular, design: .rounded))
                                        .foregroundColor(Color.wmrTextSecondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                            } else {
                                let groups = Dictionary(grouping: pastRaces) { race in
                                    Calendar.current.component(.year, from: race.date)
                                }

                                ForEach(groups.keys.sorted(by: >), id: \.self) { year in
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(String(year))
                                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                                .foregroundColor(Color.wmrTextSecondary)
                                            Spacer()
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.top, 6)
                                        .padding(.bottom, 2)

                                        Divider()
                                            .background(Color.wmrBorderSubtle)
                                            .padding(.horizontal, 12)

                                        ForEach(groups[year]!.sorted(by: { $0.date > $1.date })) { race in
                                            let hasLiveLink = (race.liveResultsURL != nil)
                                            let hasWatchLink = (race.watchURL != nil)

                                            HStack(spacing: 6) {
                                                Text(race.name)
                                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                                    .foregroundColor(Color.wmrTextPrimary)
                                                    .lineLimit(2)
                                                    .minimumScaleFactor(0.9)
                                                    .frame(maxWidth: .infinity, alignment: .leading)

                                                Text(race.distance)
                                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                                    .foregroundColor(Color.wmrTextSecondary)
                                                    .frame(width: 60, alignment: .center)

                                                HStack(spacing: 4) {
                                                    // Live results status (left)
                                                    Button {
                                                        if let url = race.liveResultsURL {
                                                            openURL(url)
                                                        }
                                                    } label: {
                                                        Image(systemName: "list.number")
                                                            .font(.system(size: 8, weight: .semibold))
                                                            .padding(2)
                                                            .background(
                                                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                                                    .fill(Color.gray.opacity(hasLiveLink ? 0.25 : 0.12))
                                                            )
                                                    }
                                                    .foregroundColor(hasLiveLink ? Color.green.opacity(0.9) : Color.gray.opacity(0.7))
                                                    .disabled(!hasLiveLink)

                                                    // Watching status (right)
                                                    Button {
                                                        if let url = race.watchURL {
                                                            openURL(url)
                                                        }
                                                    } label: {
                                                        Image(systemName: "tv")
                                                            .font(.system(size: 8, weight: .semibold))
                                                            .padding(2)
                                                            .background(
                                                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                                                    .fill(Color.gray.opacity(hasWatchLink ? 0.25 : 0.12))
                                                            )
                                                    }
                                                    .foregroundColor(hasWatchLink ? Color.green.opacity(0.9) : Color.gray.opacity(0.7))
                                                    .disabled(!hasWatchLink)
                                                }
                                                .frame(width: 40, alignment: .center)

                                                Text("\(userRaceDateTimeFormatter.string(from: race.date)) \(currentTimeZoneCode())")
                                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                                    .foregroundColor(Color.wmrTextSecondary)
                                                    .frame(width: 104, alignment: .trailing)
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                raceBeingEdited = race
                                            }
                                        }
                                    }
                                    .padding(.bottom, 4)
                                }
                            }
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
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .sheet(isPresented: $isPresentingRaceInput) {
            RaceInputSheet { newRace in
                guard let uid = authManager.firebaseUser?.uid else {
                    print("❌ Cannot save race: user is not logged in in MeView.onSave")
                    return
                }
                print("➡️ MeView.onSave: attempting to save new race \(newRace.id) for uid \(uid)")
                Task {
                    // First, persist the race to Firestore via the store
                    await raceStore.addOrUpdate(newRace, for: uid)

                    // Then, handle the optional pre-race reminder based on settings
                    if ownerPreRaceEnabled {
                        let granted = await NotificationManager.shared.requestAuthorizationIfNeeded()
                        if granted {
                            // Cancel any existing reminder for this race (if it somehow existed)
                            NotificationManager.shared.cancelPreRaceDetailsReminder(
                                raceID: newRace.id,
                                ownerUID: uid
                            )
                            let hoursBefore = max(1, ownerPreRaceHoursBefore)
                            NotificationManager.shared.schedulePreRaceDetailsReminder(
                                raceID: newRace.id,
                                raceName: newRace.name,
                                raceStartDate: newRace.date,
                                ownerUID: uid,
                                hoursBefore: hoursBefore
                            )
                        }
                    } else {
                        // If the user turned off this reminder, make sure any old one is cancelled
                        NotificationManager.shared.cancelPreRaceDetailsReminder(
                            raceID: newRace.id,
                            ownerUID: uid
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $isPresentingRunnerDetails) {
            RunnerDetailsSheet()
        }
        .sheet(item: $raceBeingEdited) { race in
            RaceInputSheet(existingRace: race) { updatedRace in
                guard let uid = authManager.firebaseUser?.uid else {
                    print("❌ Cannot save race: user is not logged in in MeView.editSave")
                    return
                }
                print("➡️ MeView.editSave: attempting to save updated race \(updatedRace.id) for uid \(uid)")
                Task {
                    // Persist the updated race first
                    await raceStore.addOrUpdate(updatedRace, for: uid)

                    // Refresh or cancel the pre-race reminder according to settings
                    if ownerPreRaceEnabled {
                        let granted = await NotificationManager.shared.requestAuthorizationIfNeeded()
                        if granted {
                            NotificationManager.shared.cancelPreRaceDetailsReminder(
                                raceID: updatedRace.id,
                                ownerUID: uid
                            )
                            let hoursBefore = max(1, ownerPreRaceHoursBefore)
                            NotificationManager.shared.schedulePreRaceDetailsReminder(
                                raceID: updatedRace.id,
                                raceName: updatedRace.name,
                                raceStartDate: updatedRace.date,
                                ownerUID: uid,
                                hoursBefore: hoursBefore
                            )
                        }
                    } else {
                        NotificationManager.shared.cancelPreRaceDetailsReminder(
                            raceID: updatedRace.id,
                            ownerUID: uid
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Time zone code helper

private func currentTimeZoneCode() -> String {
    let abbr = TimeZone.current.abbreviation() ?? ""
    switch abbr {
    case "PST", "PDT":
        return "PT"
    case "MST", "MDT":
        return "MT"
    case "CST", "CDT":
        return "CT"
    case "EST", "EDT":
        return "ET"
    default:
        return abbr
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

struct RunnerDetailsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var userDetailsStore: UserDetailsStore

    @State private var isSearchable: Bool = true
    @State private var runnerName: String = ""
    @State private var primaryLocation: String = ""
    @State private var selectedSex: String = "N"
    @State private var birthDate: Date = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @State private var affiliation: String = ""

    private var ageDescription: String {
        let now = Date()
        let components = Calendar.current.dateComponents([.year], from: birthDate, to: now)
        let years = components.year ?? 0
        return years > 0 ? "\(years)" : "—"
    }

    var body: some View {
        NavigationStack {
            Form {
                // Visibility / searchability card
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(isOn: $isSearchable) {
                            Text("Searchable in Friends tab")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                        }

                        Text("If this is on, other users can find you by name or ID and follow your races in the Watching tab.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Visibility")
                }

                // Basic info card
                Section("Basic info") {
                    TextField("Name", text: $runnerName)
                        .textContentType(.name)
                    TextField("Primary location (e.g. Boulder, CO)", text: $primaryLocation)
                        .textContentType(.addressCityAndState)

                    Picker("Sex", selection: $selectedSex) {
                        Text("Male").tag("M")
                        Text("Female").tag("F")
                        Text("Non-binary / other").tag("N")
                    }
                    .pickerStyle(.segmented)
                }

                // Age & affiliation card
                Section("Age & affiliation") {
                    DatePicker("Birthday", selection: $birthDate, displayedComponents: .date)

                    HStack {
                        Text("Age")
                        Spacer()
                        Text(ageDescription)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)
                    }

                    TextField("Affiliation (team, club, etc.)", text: $affiliation)
                }
            }
            .onAppear {
                // Preload from existing details if available
                if let existing = userDetailsStore.details {
                    isSearchable = existing.searchable
                    runnerName = existing.name
                    primaryLocation = existing.location
                    selectedSex = existing.sex
                    if let birthday = existing.birthday {
                        birthDate = birthday
                    }
                    affiliation = existing.affiliation
                }
            }
            .navigationTitle("Runner Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // Wire these fields to Firestore users/{uid} via UserDetailsStore
                        guard let uid = authManager.firebaseUser?.uid else {
                            print("❌ RunnerDetailsSheet Save tapped but no logged-in user")
                            dismiss()
                            return
                        }

                        let trimmedName = runnerName.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedLocation = primaryLocation.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedAffiliation = affiliation.trimmingCharacters(in: .whitespacesAndNewlines)

                        let details = UserDetails(
                            id: uid,
                            searchable: isSearchable,
                            name: trimmedName,
                            location: trimmedLocation,
                            sex: selectedSex,
                            birthday: birthDate,
                            affiliation: trimmedAffiliation
                        )

                        print("✅ RunnerDetailsSheet Save tapped, saving to Firestore for uid \(uid)")
                        userDetailsStore.save(details, for: uid) { error in
                            if let error = error {
                                print("❌ Failed to save UserDetails for uid \(uid): \(error)")
                            } else {
                                print("✅ Successfully saved UserDetails for uid \(uid)")
                            }
                        }

                        dismiss()
                    }
                }
            }
        }
    }
}
struct RaceInputSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    let existingRace: UserRace?
    let onSave: (UserRace) -> Void

    @State private var raceName: String
    @State private var raceDate: Date
    @State private var raceDistance: String
    @State private var liveResultsLink: String
    @State private var watchingLink: String
    @State private var showingLinksInfo = false

    @State private var raceLocation: String
    @State private var meetPageLink: String
    @State private var selectedLevels: Set<String>
    @State private var instructionsText: String
    @State private var commentsText: String
    @State private var timeZoneIdentifier: String

    private var canOpenLiveResultsLink: Bool {
        let trimmed = liveResultsLink.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && URL(string: trimmed) != nil
    }

    private var canOpenWatchingLink: Bool {
        let trimmed = watchingLink.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && URL(string: trimmed) != nil
    }
    
    private var canOpenMeetPageLink: Bool {
        let trimmed = meetPageLink.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && URL(string: trimmed) != nil
    }

    init(existingRace: UserRace? = nil, onSave: @escaping (UserRace) -> Void) {
        self.existingRace = existingRace
        self.onSave = onSave
        _raceName = State(initialValue: existingRace?.name ?? "")
        _raceDate = State(initialValue: existingRace?.date ?? Date())
        _raceDistance = State(initialValue: existingRace?.distance ?? "")
        _liveResultsLink = State(initialValue: existingRace?.liveResultsURL?.absoluteString ?? "")
        _watchingLink = State(initialValue: existingRace?.watchURL?.absoluteString ?? "")

        _raceLocation = State(initialValue: existingRace?.location ?? "")
        _meetPageLink = State(initialValue: existingRace?.meetPageURL?.absoluteString ?? "")
        _selectedLevels = State(initialValue: Set(existingRace?.levels ?? []))
        _instructionsText = State(initialValue: existingRace?.instructions ?? "")
        _commentsText = State(initialValue: existingRace?.comments ?? "")
        _timeZoneIdentifier = State(initialValue: existingRace?.timeZoneIdentifier ?? TimeZone.current.identifier)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Race") {
                    TextField("Race name", text: $raceName)

                    DatePicker("Race date & time",
                               selection: $raceDate,
                               displayedComponents: [.date, .hourAndMinute])

                    Picker("Time zone", selection: $timeZoneIdentifier) {
                        Text("Eastern (ET)").tag("America/New_York")
                        Text("Central (CT)").tag("America/Chicago")
                        Text("Mountain (MT)").tag("America/Denver")
                        Text("Pacific (PT)").tag("America/Los_Angeles")
                    }
                }

                Section("Details") {
                    TextField("Distance (e.g. 5K, Half)", text: $raceDistance)
                    TextField("Location (e.g. New York, NY)", text: $raceLocation)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Level")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        let allLevels = ["Hobby Jogging", "High School", "Collegiate", "Professional"]
                        ForEach(allLevels, id: \.self) { level in
                            Toggle(isOn: Binding(
                                get: { selectedLevels.contains(level) },
                                set: { isOn in
                                    if isOn {
                                        selectedLevels.insert(level)
                                    } else {
                                        selectedLevels.remove(level)
                                    }
                                }
                            )) {
                                Text(level)
                            }
                        }
                    }
                }

                Section {
                    HStack(spacing: 8) {
                        TextField("Live results link", text: $liveResultsLink)
                            .keyboardType(.URL)
                            .textContentType(.URL)

                        Button {
                            let trimmed = liveResultsLink.trimmingCharacters(in: .whitespacesAndNewlines)
                            if let url = URL(string: trimmed) {
                                openURL(url)
                            }
                        } label: {
                            Image(systemName: "list.number")
                                .font(.system(size: 14, weight: .semibold))
                                .padding(6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(Color.gray.opacity(canOpenLiveResultsLink ? 0.25 : 0.12))
                                )
                        }
                        .foregroundColor(canOpenLiveResultsLink ? Color.accentColor : Color.gray.opacity(0.7))
                        .disabled(!canOpenLiveResultsLink)
                    }

                    HStack(spacing: 8) {
                        TextField("Watching link", text: $watchingLink)
                            .keyboardType(.URL)
                            .textContentType(.URL)

                        Button {
                            let trimmed = watchingLink.trimmingCharacters(in: .whitespacesAndNewlines)
                            if let url = URL(string: trimmed) {
                                openURL(url)
                            }
                        } label: {
                            Image(systemName: "tv")
                                .font(.system(size: 14, weight: .semibold))
                                .padding(6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(Color.gray.opacity(canOpenWatchingLink ? 0.25 : 0.12))
                                )
                        }
                        .foregroundColor(canOpenWatchingLink ? Color.accentColor : Color.gray.opacity(0.7))
                        .disabled(!canOpenWatchingLink)
                    }

                    HStack(spacing: 8) {
                        TextField("Meet page link", text: $meetPageLink)
                            .keyboardType(.URL)
                            .textContentType(.URL)

                        Button {
                            let trimmed = meetPageLink.trimmingCharacters(in: .whitespacesAndNewlines)
                            if let url = URL(string: trimmed) {
                                openURL(url)
                            }
                        } label: {
                            Image(systemName: "house")
                                .font(.system(size: 14, weight: .semibold))
                                .padding(6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(Color.gray.opacity(canOpenMeetPageLink ? 0.25 : 0.12))
                                )
                        }
                        .foregroundColor(canOpenMeetPageLink ? Color.accentColor : Color.gray.opacity(0.7))
                        .disabled(!canOpenMeetPageLink)
                    }
                } header: {
                    HStack {
                        Text("Links")
                        Spacer()
                        Button {
                            showingLinksInfo = true
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Extra info section after Links, before navigationTitle
                Section("Extra info") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Instructions for following")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextEditor(text: $instructionsText)
                            .frame(minHeight: 60)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Comments / goals / charity")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextEditor(text: $commentsText)
                            .frame(minHeight: 60)
                    }
                }
            }
            .navigationTitle("Input Race")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Links info", isPresented: $showingLinksInfo) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please paste links in here – most links likely start with https://\n\nTest links by tapping on the buttons")
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmedName = raceName.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedDistance = raceDistance.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedLive = liveResultsLink.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedWatching = watchingLink.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedLocation = raceLocation.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedMeet = meetPageLink.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedInstructions = instructionsText.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedComments = commentsText.trimmingCharacters(in: .whitespacesAndNewlines)

                        let liveURL = trimmedLive.isEmpty ? nil : URL(string: trimmedLive)
                        let watchURL = trimmedWatching.isEmpty ? nil : URL(string: trimmedWatching)
                        let meetURL = trimmedMeet.isEmpty ? nil : URL(string: trimmedMeet)

                        let levelsArray = Array(selectedLevels).sorted()

                        let newRace = UserRace(
                            id: existingRace?.id ?? UUID().uuidString,
                            name: trimmedName.isEmpty ? "Untitled race" : trimmedName,
                            distance: trimmedDistance,
                            date: raceDate,
                            liveResultsURL: liveURL,
                            watchURL: watchURL,
                            timeZoneIdentifier: timeZoneIdentifier,
                            location: trimmedLocation,
                            meetPageURL: meetURL,
                            levels: levelsArray,
                            instructions: trimmedInstructions.isEmpty ? nil : trimmedInstructions,
                            comments: trimmedComments.isEmpty ? nil : trimmedComments
                        )

                        onSave(newRace)
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
            .environmentObject(UserRaceStore())
            .environmentObject(UserDetailsStore())
            .environment(\.colorScheme, .dark)
            .background(Color.wmrBackground)
    }
}

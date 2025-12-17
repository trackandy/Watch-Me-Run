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
    @Environment(\.openURL) private var openURL
    @State private var isPresentingRaceInput = false
    @State private var currentNonce: String?
    @State private var userRaces: [UserRace] = []
    @State private var raceBeingEdited: UserRace?

    private var isLoggedIn: Bool {
        authManager.isLoggedIn
    }

    private var displayName: String {
        authManager.firebaseUser?.displayName ?? "Runner"
    }

    private var upcomingRaces: [UserRace] {
        userRaces
            .filter { !$0.isInPast }
            .sorted { $0.date > $1.date }
    }

    private var pastRaces: [UserRace] {
        userRaces
            .filter { $0.isInPast }
            .sorted { $0.date > $1.date }
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
                            HStack(spacing: 6) {
                                Text("Race")
                                    .font(.caption2)
                                    .foregroundColor(Color.wmrTextTertiary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text("Distance")
                                    .font(.caption2)
                                    .foregroundColor(Color.wmrTextTertiary)
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
                                                        Image(systemName: "questionmark.circle")
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
                                                        Image(systemName: "questionmark.circle")
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
                                                        Image(systemName: "questionmark.circle")
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
                                                        Image(systemName: "questionmark.circle")
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
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .sheet(isPresented: $isPresentingRaceInput) {
            RaceInputSheet { newRace in
                userRaces.append(newRace)
            }
        }
        .sheet(item: $raceBeingEdited) { race in
            RaceInputSheet(existingRace: race) { updatedRace in
                if let index = userRaces.firstIndex(where: { $0.id == updatedRace.id }) {
                    userRaces[index] = updatedRace
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

    private var canOpenLiveResultsLink: Bool {
        let trimmed = liveResultsLink.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && URL(string: trimmed) != nil
    }

    private var canOpenWatchingLink: Bool {
        let trimmed = watchingLink.trimmingCharacters(in: .whitespacesAndNewlines)
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
    }

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
                            Image(systemName: "arrow.up.right.square")
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
                            Image(systemName: "arrow.up.right.square")
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

                        let liveURL = trimmedLive.isEmpty ? nil : URL(string: trimmedLive)
                        let watchURL = trimmedWatching.isEmpty ? nil : URL(string: trimmedWatching)

                        let newRace = UserRace(
                            id: existingRace?.id ?? UUID().uuidString,
                            name: trimmedName.isEmpty ? "Untitled race" : trimmedName,
                            distance: trimmedDistance,
                            date: raceDate,
                            liveResultsURL: liveURL,
                            watchURL: watchURL
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
            .environment(\.colorScheme, .dark)
            .background(Color.wmrBackground)
    }
}

//
//  FeaturedMeetDetailView.swift
//  Watch Me Run
//
//  Created by Andy Kent on 1/3/26.
//

import SwiftUI
import FirebaseFirestore

struct FeaturedMeetDetailView: View {
    let featured: WMRFeaturedMeet
    let onClose: () -> Void

    @Environment(\.openURL) private var openURL
    @State private var events: [FeaturedEvent] = []
    @State private var isLoadingEvents: Bool = false
    @State private var watchedEventIDs: Set<String> = []

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d • h:mm a"
        return formatter.string(from: featured.date)
    }

    var body: some View {
        // Same yellow palette as the featured card
        let accentYellow = Color(red: 1.0, green: 0.9, blue: 0.2)      // bright yellow
        let darkYellow1  = Color(red: 0.35, green: 0.27, blue: 0.02)   // deep yellow/brown
        let darkYellow2  = Color(red: 0.45, green: 0.33, blue: 0.05)   // slightly lighter

        return GeometryReader { geo in
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()

                VStack {
                    Spacer() // push the card to the bottom

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Spacer()
                            Button(action: {
                                onClose()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(accentYellow.opacity(0.95))
                            }
                        }

                        Text("Featured Event")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(accentYellow.opacity(0.9))

                        Text(featured.name)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(accentYellow)
                            .multilineTextAlignment(.leading)

                        if let location = featured.location, !location.isEmpty {
                            Text(location)
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundColor(accentYellow.opacity(0.9))
                        }

                        Text(formattedDate)
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(accentYellow.opacity(0.95))
                            .padding(.top, 4)

                        // Button row reused in the larger card
                        HStack(spacing: 10) {
                            detailLinkButton(
                                systemName: "list.number",
                                urlString: featured.liveResultsURL,
                                accentYellow: accentYellow
                            )

                            detailLinkButton(
                                systemName: "tv.fill",
                                urlString: featured.watchURL,
                                accentYellow: accentYellow
                            )

                            detailLinkButton(
                                systemName: "house.fill",
                                urlString: featured.homeMeetURL,
                                accentYellow: accentYellow
                            )

                            Spacer(minLength: 8)
                        }
                        .padding(.top, 6)

                        Divider()
                            .background(accentYellow.opacity(0.4))
                            .padding(.vertical, 8)

                        // Events list for this featured meet
                        if isLoadingEvents {
                            Text("Loading events…")
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundColor(accentYellow.opacity(0.9))
                        } else if events.isEmpty {
                            Text("No events added yet.")
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundColor(accentYellow.opacity(0.7))
                        } else {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(events) { event in
                                    HStack(alignment: .center, spacing: 8) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(event.name)
                                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                                .foregroundColor(accentYellow.opacity(0.95))
                                                .lineLimit(1)

                                            HStack(spacing: 4) {
                                                if !event.rawDateString.isEmpty {
                                                    Text(event.rawDateString)
                                                        .font(.system(size: 11, weight: .regular, design: .rounded))
                                                        .foregroundColor(accentYellow.opacity(0.85))
                                                        .lineLimit(1)
                                                }

                                                if !event.timeDisplay.isEmpty {
                                                    if !event.rawDateString.isEmpty {
                                                        Text("•")
                                                            .font(.system(size: 11, weight: .regular, design: .rounded))
                                                            .foregroundColor(accentYellow.opacity(0.7))
                                                    }

                                                    Text(event.timeDisplay)
                                                        .font(.system(size: 11, weight: .medium, design: .rounded))
                                                        .foregroundColor(accentYellow.opacity(0.95))
                                                        .lineLimit(1)
                                                }
                                            }
                                        }

                                        Spacer(minLength: 8)

                                        Button(action: {
                                            if watchedEventIDs.contains(event.id) {
                                                watchedEventIDs.remove(event.id)
                                            } else {
                                                watchedEventIDs.insert(event.id)
                                            }
                                        }) {
                                            HStack(spacing: 4) {
                                                Image(systemName: watchedEventIDs.contains(event.id) ? "star.fill" : "star")
                                                    .font(.system(size: 13, weight: .semibold))

                                                Text("Watch")
                                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                            }
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(
                                                Capsule()
                                                    .fill(Color.black.opacity(watchedEventIDs.contains(event.id) ? 0.28 : 0.18))
                                            )
                                            .overlay(
                                                Capsule()
                                                    .stroke(accentYellow.opacity(watchedEventIDs.contains(event.id) ? 0.95 : 0.6), lineWidth: 0.9)
                                            )
                                            .foregroundColor(accentYellow.opacity(0.97))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(Color.black.opacity(0.18))
                                    )
                                }
                            }
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .frame(
                        width: geo.size.width * 0.94,
                        height: geo.size.height * 0.75,
                        alignment: .topLeading
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [darkYellow1, darkYellow2]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(accentYellow.opacity(0.7), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.5), radius: 18, x: 0, y: 10)
                    )
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                    .onAppear {
                        loadEventsIfNeeded()
                    }
                }
            }
        }
    }

    /// Small helper just like the featured card's buttons, but scoped to the detail view.
    private func detailLinkButton(systemName: String, urlString: String?, accentYellow: Color) -> some View {
        let trimmed: String? = {
            guard let raw = urlString else { return nil }
            let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            return s.isEmpty ? nil : s
        }()

        let isEnabled = trimmed != nil

        return Button(action: {
            guard let raw = trimmed else { return }

            if let directURL = URL(string: raw), directURL.scheme != nil {
                print("🔗 Opening featured detail URL (direct): \(raw)")
                openURL(directURL)
                return
            }

            if let httpsURL = URL(string: "https://" + raw) {
                print("🔗 Opening featured detail URL (https-prefixed): https://\(raw)")
                openURL(httpsURL)
                return
            }

            print("⚠️ Could not form a valid URL from featured detail link: \(raw)")
        }) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 34, height: 34)
                .background(
                    Circle()
                        .fill(accentYellow.opacity(isEnabled ? 0.22 : 0.06))
                )
                .overlay(
                    Circle()
                        .stroke(accentYellow.opacity(isEnabled ? 0.9 : 0.35), lineWidth: 0.9)
                )
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1.0 : 0.45)
        .disabled(!isEnabled)
    }
    private func loadEventsIfNeeded() {
        // Avoid reloading if we already have data or are in-flight
        if isLoadingEvents || !events.isEmpty {
            return
        }

        isLoadingEvents = true

        let db = Firestore.firestore()
        // Assumes `featured.id` matches the Firestore document ID in `featuredmeets`
        let eventsRef = db
            .collection("featuredmeets")
            .document(featured.id)
            .collection("events")

        eventsRef.getDocuments { snapshot, error in
            isLoadingEvents = false

            if let error = error {
                print("⚠️ Failed to load featured events: \(error.localizedDescription)")
                return
            }

            guard let snapshot = snapshot else {
                print("⚠️ No snapshot returned for featured events")
                return
            }

            let loaded: [FeaturedEvent] = snapshot.documents.map { doc in
                let name = doc.documentID

                var startDate: Date? = nil
                var rawDateString: String = ""

                if let ts = doc.get("date") as? Timestamp {
                    let date = ts.dateValue()
                    startDate = date

                    let df = DateFormatter()
                    df.dateFormat = "EEE MMM d"
                    rawDateString = df.string(from: date)
                } else if let d = doc.get("date") as? Date {
                    startDate = d

                    let df = DateFormatter()
                    df.dateFormat = "EEE MMM d"
                    rawDateString = df.string(from: d)
                } else if let s = doc.get("date") as? String {
                    rawDateString = s
                }

                return FeaturedEvent(
                    id: doc.documentID,
                    name: name,
                    startDate: startDate,
                    rawDateString: rawDateString
                )
            }

            self.events = loaded
            print("📥 Loaded \(loaded.count) events for featured meet id=\(featured.id)")
        }
    }
}

struct FeaturedEvent: Identifiable {
    let id: String
    let name: String
    let startDate: Date?
    let rawDateString: String

    var timeDisplay: String {
        guard let date = startDate else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

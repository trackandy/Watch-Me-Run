//
//  SettingsView.swift
//  Watch Me Run
//
//  Created by Andy Kent on 12/11/25.
//

//
//  SettingsView.swift
//  Watch Me Run
//
//  Created by Andy Kent on 12/9/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("filterSearchDockSide") private var dockSideRaw: String = DockSide.right.rawValue

    // Owner (my races) notification settings
    @AppStorage("ownerPreRaceReminderEnabled") private var ownerPreRaceEnabled: Bool = true
    @AppStorage("ownerPreRaceHoursBefore") private var ownerPreRaceHoursBefore: Int = 6

    // Watching (fans/friends) notification settings
    @AppStorage("watchingRemindersEnabled") private var watchingRemindersEnabled: Bool = true
    @AppStorage("watchingFirstMinutesBefore") private var watchingFirstMinutesBefore: Int = 20   // 0 = none
    @AppStorage("watchingSecondMinutesBefore") private var watchingSecondMinutesBefore: Int = 0   // 0 = none

    // Local UI state for pickers
    @State private var isShowingOwnerHoursPicker: Bool = false
    @State private var isShowingFirstMinutesPicker: Bool = false
    @State private var isShowingSecondHoursPicker: Bool = false

    private var dockSide: DockSide {
        DockSide(rawValue: dockSideRaw) ?? .right
    }

    // Options for the pickers
    private let ownerHoursOptions: [Int] = [6, 12, 18, 24]
    private let watchingFirstMinutesOptions: [Int] = [0, 5, 10, 20, 30, 60] // minutes, 0 = None
    private let watchingSecondHoursOptions: [Int] = [0, 6, 12, 24, 48]       // hours, 0 = None

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {

                // MARK: - Filter/Search Button Position
                VStack(alignment: .leading, spacing: 12) {
                    Text("Filter & Search Button Position")
                        .font(.caption)
                        .foregroundColor(Color.wmrTextSecondary)

                    HStack(spacing: 16) {
                        ForEach(DockSide.allCases) { side in
                            Button {
                                dockSideRaw = side.rawValue
                            } label: {
                                Text(side.label)
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        Capsule()
                                            .fill(dockSide == side
                                                  ? Color.wmrAccentBlue.opacity(0.25)
                                                  : Color.clear)
                                    )
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.wmrSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.wmrBorderSubtle, lineWidth: 1)
                        )
                )

                // MARK: - Notifications
                VStack(alignment: .leading, spacing: 12) {
                    Text("Notifications")
                        .font(.caption)
                        .foregroundColor(Color.wmrTextSecondary)

                    VStack(alignment: .leading, spacing: 16) {
                        // Owner / my races
                        VStack(alignment: .leading, spacing: 8) {
                            Text("For my races")
                                .font(.footnote)
                                .foregroundColor(Color.wmrTextSecondary)

                            HStack(spacing: 12) {
                                Text("Race setup reminder")
                                    .font(.footnote)
                                    .foregroundColor(Color.wmrTextPrimary)

                                Spacer()

                                Toggle("", isOn: $ownerPreRaceEnabled)
                                    .labelsHidden()
                            }

                            Button {
                                isShowingOwnerHoursPicker = true
                            } label: {
                                Text(ownerPreRaceLabel)
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        Capsule()
                                            .fill(ownerPreRaceEnabled
                                                  ? Color.wmrAccentBlue.opacity(0.25)
                                                  : Color.white.opacity(0.06))
                                    )
                                    .foregroundColor(ownerPreRaceEnabled ? .white : Color.wmrTextSecondary)
                            }
                            .buttonStyle(.plain)
                            .disabled(!ownerPreRaceEnabled)
                        }

                        Divider()
                            .background(Color.wmrBorderSubtle)

                        // Watching / fans & friends
                        VStack(alignment: .leading, spacing: 8) {
                            Text("For watched races")
                                .font(.footnote)
                                .foregroundColor(Color.wmrTextSecondary)

                            HStack(spacing: 12) {
                                Text("Remind me for races I’m watching")
                                    .font(.footnote)
                                    .foregroundColor(Color.wmrTextPrimary)

                                Spacer()

                                Toggle("", isOn: $watchingRemindersEnabled)
                                    .labelsHidden()
                            }

                            HStack(spacing: 16) {
                                // 1st notification (short lead, minutes)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("1st notification")
                                        .font(.footnote)
                                        .foregroundColor(Color.wmrTextSecondary)

                                    Button {
                                        isShowingFirstMinutesPicker = true
                                    } label: {
                                        Text(watchingFirstLabel)
                                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .frame(maxWidth: .infinity)
                                            .background(
                                                Capsule()
                                                    .fill(watchingRemindersEnabled
                                                          ? Color.wmrAccentBlue.opacity(watchingFirstMinutesBefore > 0 ? 0.25 : 0.15)
                                                          : Color.white.opacity(0.06))
                                            )
                                            .foregroundColor(watchingRemindersEnabled ? .white : Color.wmrTextSecondary)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(!watchingRemindersEnabled)
                                }

                                // 2nd notification (longer lead, hours)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("2nd notification")
                                        .font(.footnote)
                                        .foregroundColor(Color.wmrTextSecondary)

                                    Button {
                                        isShowingSecondHoursPicker = true
                                    } label: {
                                        Text(watchingSecondLabel)
                                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .frame(maxWidth: .infinity)
                                            .background(
                                                Capsule()
                                                    .fill(watchingRemindersEnabled
                                                          ? Color.white.opacity(0.12)
                                                          : Color.white.opacity(0.06))
                                            )
                                            .foregroundColor(watchingRemindersEnabled ? .white : Color.wmrTextSecondary)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(!watchingRemindersEnabled)
                                }
                            }

                            Text("Customize reminders for your own races and for races you’re watching. Watching reminders will fire before race start times when you’ve starred pros, friends, or meets.")
                                .font(.footnote)
                                .foregroundColor(Color.wmrTextTertiary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.wmrSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.wmrBorderSubtle, lineWidth: 1)
                        )
                )

                // MARK: - View Order
                VStack(alignment: .leading, spacing: 12) {
                    Text("View Order")
                        .font(.caption)
                        .foregroundColor(Color.wmrTextSecondary)

                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Label("Results", systemImage: "line.3.horizontal")
                                .font(.footnote)
                                .foregroundColor(Color.wmrTextPrimary)

                            Label("Watching", systemImage: "line.3.horizontal")
                                .font(.footnote)
                                .foregroundColor(Color.wmrTextPrimary)

                            Label("Me", systemImage: "line.3.horizontal")
                                .font(.footnote)
                                .foregroundColor(Color.wmrTextPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Text("In the future you’ll be able to rearrange the order of the Results, Watching, and Me tabs here.")
                            .font(.footnote)
                            .foregroundColor(Color.wmrTextTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.wmrSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.wmrBorderSubtle, lineWidth: 1)
                        )
                )

                // MARK: - About
                VStack(alignment: .leading, spacing: 12) {
                    Text("About")
                        .font(.caption)
                        .foregroundColor(Color.wmrTextSecondary)

                    Text("App creators Chris and Andy created this app in order to solve three main pain points of being a fan of running:\n\n1) Live results are hard to find.\n2) Figuring out when and how to follow your favorite athletes and meets is a struggle.\n3) Sending your racing schedule to all your friends and family is a hassle.\n\nChris ran at DePaul undergrad and then went to Georgia Tech for his Masters. Andy met Chris at GT, and Andy would go on to run at Colorado for grad school.")
                        .font(.footnote)
                        .foregroundColor(Color.wmrTextPrimary)
                        .multilineTextAlignment(.leading)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.wmrSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.wmrBorderSubtle, lineWidth: 1)
                        )
                )

                // MARK: - App Info
                VStack(alignment: .leading, spacing: 12) {
                    Text("App Info")
                        .font(.caption)
                        .foregroundColor(Color.wmrTextSecondary)

                    VStack(spacing: 8) {
                        HStack {
                            Text("Version")
                                .font(.footnote)
                                .foregroundColor(Color.wmrTextSecondary)
                            Spacer()
                            Text("1.0.0")
                                .font(.footnote)
                                .foregroundColor(Color.wmrTextPrimary)
                        }

                        HStack {
                            Text("Build")
                                .font(.footnote)
                                .foregroundColor(Color.wmrTextSecondary)
                            Spacer()
                            Text("100")
                                .font(.footnote)
                                .foregroundColor(Color.wmrTextPrimary)
                        }

                        HStack {
                            Text("Channel")
                                .font(.footnote)
                                .foregroundColor(Color.wmrTextSecondary)
                            Spacer()
                            Text("TestFlight (placeholder)")
                                .font(.footnote)
                                .foregroundColor(Color.wmrTextPrimary)
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.wmrSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.wmrBorderSubtle, lineWidth: 1)
                        )
                )

                Spacer()
            }
            .padding(16)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .background(Color.wmrBackground.ignoresSafeArea())
            .confirmationDialog("Race setup reminder", isPresented: $isShowingOwnerHoursPicker, titleVisibility: .visible) {
                ForEach(ownerHoursOptions, id: \.self) { hours in
                    Button("\(hours) hours before") {
                        ownerPreRaceHoursBefore = hours
                    }
                }
            }
            .confirmationDialog("1st notification timing", isPresented: $isShowingFirstMinutesPicker, titleVisibility: .visible) {
                ForEach(watchingFirstMinutesOptions, id: \.self) { minutes in
                    if minutes == 0 {
                        Button("None") {
                            watchingFirstMinutesBefore = 0
                        }
                    } else if minutes == 1 {
                        Button("1 minute before") {
                            watchingFirstMinutesBefore = 1
                        }
                    } else {
                        Button("\(minutes) minutes before") {
                            watchingFirstMinutesBefore = minutes
                        }
                    }
                }
            }
            .confirmationDialog("2nd notification timing", isPresented: $isShowingSecondHoursPicker, titleVisibility: .visible) {
                ForEach(watchingSecondHoursOptions, id: \.self) { hours in
                    if hours == 0 {
                        Button("None") {
                            watchingSecondMinutesBefore = 0
                        }
                    } else if hours == 1 {
                        Button("1 hour before") {
                            watchingSecondMinutesBefore = 60
                        }
                    } else {
                        Button("\(hours) hours before") {
                            watchingSecondMinutesBefore = hours * 60
                        }
                    }
                }
            }
        }
    }

    // MARK: - Label Helpers

    private var ownerPreRaceLabel: String {
        let hours = max(1, ownerPreRaceHoursBefore)
        return "\(hours) hours before race"
    }

    private var watchingFirstLabel: String {
        if watchingFirstMinutesBefore <= 0 {
            return "None"
        } else if watchingFirstMinutesBefore == 1 {
            return "1 minute before"
        } else {
            return "\(watchingFirstMinutesBefore) minutes before"
        }
    }

    private var watchingSecondLabel: String {
        if watchingSecondMinutesBefore <= 0 {
            return "None"
        }

        let hours = watchingSecondMinutesBefore / 60
        if hours == 1 {
            return "1 hour before"
        } else {
            return "\(hours) hours before"
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environment(\.colorScheme, .dark)
    }
}

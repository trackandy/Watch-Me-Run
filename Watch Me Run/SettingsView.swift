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

    private var dockSide: DockSide {
        DockSide(rawValue: dockSideRaw) ?? .right
    }

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

                    VStack(spacing: 8) {
                        HStack {
                            Text("1st race reminder")
                                .font(.footnote)
                                .foregroundColor(Color.wmrTextSecondary)
                            Spacer()
                            Text("20 minutes before")
                                .font(.footnote)
                                .foregroundColor(Color.wmrTextPrimary)
                        }

                        HStack {
                            Text("2nd race reminder")
                                .font(.footnote)
                                .foregroundColor(Color.wmrTextSecondary)
                            Spacer()
                            Text("None")
                                .font(.footnote)
                                .foregroundColor(Color.wmrTextPrimary)
                        }

                        Text("Later you’ll be able to customize timing for up to two race notifications (from 20 minutes to 48 hours before).")
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
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environment(\.colorScheme, .dark)
    }
}

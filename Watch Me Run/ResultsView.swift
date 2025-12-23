//
//  ResultsView.swift
//  Watch Me Run
//
//  Created by Andy Kent on 12/9/25.
//

import SwiftUI

struct ResultsView: View {
    @ObservedObject var store: MeetStore

    private let gridSpacing: CGFloat = 16

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 8) {
                // Section header for current meets, sitting on a raised platform
                HStack {
                    Text("Current Events")
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

                Text("Live Results, Stream Links, and Event Home Pages")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(Color.wmrTextSecondary)
                    .padding(.horizontal, 24)
                    .padding(.top, 4)

                if store.currentMeets.isEmpty {
                    Text("No current meets")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.top, 4)
                } else {
                    GeometryReader { geo in
                        let totalWidth = geo.size.width
                        let cardWidth: CGFloat = 140
                        // gutter = left gap = middle gap = right gap
                        let gutter = max((totalWidth - 2 * cardWidth) / 3, 0)

                        let sortedMeets = store.currentMeets.sorted {
                            if $0.priority != $1.priority {
                                return $0.priority.rawValue < $1.priority.rawValue
                            } else {
                                return $0.date < $1.date
                            }
                        }

                        LazyVGrid(
                            columns: [
                                GridItem(.fixed(cardWidth), spacing: gutter),
                                GridItem(.fixed(cardWidth), spacing: gutter)
                            ],
                            alignment: .leading,
                            spacing: gridSpacing // vertical spacing between rows
                        ) {
                            ForEach(sortedMeets) { meet in
                                MeetCardView(meet: meet)
                            }
                        }
                        .padding(.horizontal, gutter)
                        .padding(.top, 8)
                        .padding(.bottom, gridSpacing)
                    }
                    .frame(maxWidth: .infinity, minHeight: 0)
                }
            }
        }
        .onAppear {
            store.loadResultsFromFirebase()
        }
    }
}

struct ResultsColumn: View {
    let title: String
    let subtitle: String
    let meets: [Meet]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Column header
            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 2)

            // Content
            if meets.isEmpty {
                Text("No meets")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            } else {
                ForEach(meets) { meet in
                    MeetCardView(meet: meet)
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }
}

// MARK: - Preview

struct ResultsView_Previews: PreviewProvider {
    static var previews: some View {
        let store = MeetStore()
        // Optional: Uncomment this to use sample data in preview
        /*
        store.meets = SampleData.sampleMeets
        */

        return ResultsView(store: store)
            .previewLayout(.device)
    }
}

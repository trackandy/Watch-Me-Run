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

    private var columns: [GridItem] {
        [
            GridItem(.flexible(), spacing: gridSpacing),
            GridItem(.flexible(), spacing: gridSpacing)
        ]
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 8) {
                // Section header for current meets, sitting on a raised platform
                HStack {
                    Text("Current Meets")
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

                if store.currentMeets.isEmpty {
                    Text("No current meets")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.top, 8)
                } else {
                    LazyVGrid(columns: columns, alignment: .leading, spacing: gridSpacing) {
                        ForEach(store.currentMeets) { meet in
                            MeetCardView(meet: meet)
                        }
                    }
                    .padding(.horizontal, gridSpacing)
                    .padding(.vertical, gridSpacing)
                }
            }
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

//
//  MeetStore.swift
//  Watch Me Run
//
//  Created by Andy Kent on 12/9/25.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class MeetStore: ObservableObject {
    @Published var meets: [Meet] = []

    private var timerCancellable: AnyCancellable?

    // MARK: - Init

    init() {
        loadMeets()
        startAutoRefresh()
    }

    // MARK: - Public Helpers

    /// Meets sorted by priority (1 → 3), then alphabetically by name.
    var sortedMeets: [Meet] {
        meets.sorted {
            if $0.priority != $1.priority {
                return $0.priority.rawValue < $1.priority.rawValue
            }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    /// Meets whose start date is more than 6 days before today.
    var pastMeets: [Meet] {
        sortedMeets.filter { $0.status == .past }
    }

    /// Meets whose start date is within 6 days before today and 3 days after today.
    var currentMeets: [Meet] {
        sortedMeets.filter { $0.status == .current }
    }

    /// Meets whose start date is more than 3 days after today.
    var upcomingMeets: [Meet] {
        sortedMeets.filter { $0.status == .upcoming }
    }

    // MARK: - Loading

    func loadMeets() {
        // Load from bundled CSV named "meets.csv"
        guard let url = Bundle.main.url(forResource: "meets", withExtension: "csv") else {
            print("⚠️ Could not find meets.csv in bundle")
            meets = []
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let parsed = MeetCSVParser.parse(data: data)
            self.meets = parsed
            print("✅ Loaded \(parsed.count) meets from meets.csv")
        } catch {
            print("⚠️ Failed to load meets.csv: \(error)")
            meets = []
        }
    }

    // MARK: - Auto Refresh

    private func startAutoRefresh() {
        // Refresh every hour (3600 seconds)
        timerCancellable = Timer
            .publish(every: 3600, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.loadMeets()
            }
    }
}

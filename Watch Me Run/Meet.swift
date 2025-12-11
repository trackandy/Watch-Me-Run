//
//  Meet.swift
//  Watch Me Run
//
//  Created by Andy Kent on 12/9/25.
//

import Foundation

// MARK: - Priority & Status

enum MeetPriority: Int, Comparable, CaseIterable, Identifiable {
    case high = 1    // Priority 1
    case medium = 2  // Priority 2
    case low = 3     // Priority 3

    var id: Int { rawValue }

    var label: String {
        String(rawValue)
    }

    static func < (lhs: MeetPriority, rhs: MeetPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

enum MeetStatus {
    case past
    case current
    case upcoming
}

// MARK: - Meet Model

struct Meet: Identifiable {
    let id = UUID()
    let date: Date
    let name: String
    let level: String
    let priority: MeetPriority
    let liveResultsURL: URL?
    let watchURL: URL?

    /// Classify meet into Past / Current / Upcoming using:
    /// - Past:     start date > 6 days ago (earlier than now - 6 days)
    /// - Current:  start date < 6 days ago AND < 3 days in the future
    /// - Upcoming: start date > 3 days in the future
    var status: MeetStatus {
        let now = Date()
        let calendar = Calendar.current

        let sixDaysAgo = calendar.date(byAdding: .day, value: -6, to: now)!
        let threeDaysAhead = calendar.date(byAdding: .day, value: 3, to: now)!

        if date < sixDaysAgo {
            // More than 6 days before today
            return .past
        } else if date > threeDaysAhead {
            // More than 3 days in the future
            return .upcoming
        } else {
            // Between 6 days ago and 3 days ahead (inclusive)
            return .current
        }
    }
}

// MARK: - CSV Parser

struct MeetCSVParser {
    /// Expects a CSV with header row:
    /// Date,Name,Level,Priority,Live Results,Watch
    static func parse(data: Data) -> [Meet] {
        guard let raw = String(data: data, encoding: .utf8) else { return [] }

        let nonEmptyLines = raw
            .components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        guard let headerLine = nonEmptyLines.first else { return [] }

        let headers = splitCSVLine(headerLine).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        func index(_ name: String) -> Int? {
            headers.firstIndex { $0.caseInsensitiveCompare(name) == .orderedSame }
        }

        guard
            let dateIdx = index("Date"),
            let nameIdx = index("Name"),
            let levelIdx = index("Level"),
            let priorityIdx = index("Priority")
        else {
            print("⚠️ CSV missing required headers (Date, Name, Level, Priority)")
            return []
        }

        let liveIdx = index("Live Results") ?? index("LiveResults")
        let watchIdx = index("Watch")

        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "M/d/yy"   // Handles 11/20/25, 01/05/26, etc.

        var meets: [Meet] = []

        for line in nonEmptyLines.dropFirst() {
            let cols = splitCSVLine(line)
            if cols.count < headers.count { continue }

            let dateString = cols[dateIdx].trimmingCharacters(in: .whitespacesAndNewlines)
            guard let date = df.date(from: dateString) else {
                print("⚠️ Could not parse date: \(dateString)")
                continue
            }

            let name = cols[nameIdx].trimmingCharacters(in: .whitespacesAndNewlines)
            let level = cols[levelIdx].trimmingCharacters(in: .whitespacesAndNewlines)

            let priorityRaw = Int(cols[priorityIdx].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 2
            let priority = MeetPriority(rawValue: priorityRaw) ?? .medium

            let liveURL: URL? = liveIdx.flatMap { idx in
                guard idx < cols.count else { return nil }
                let s = cols[idx].trimmingCharacters(in: .whitespacesAndNewlines)
                return s.isEmpty ? nil : URL(string: s)
            }

            let watchURL: URL? = watchIdx.flatMap { idx in
                guard idx < cols.count else { return nil }
                let s = cols[idx].trimmingCharacters(in: .whitespacesAndNewlines)
                return s.isEmpty ? nil : URL(string: s)
            }

            let meet = Meet(
                date: date,
                name: name,
                level: level,
                priority: priority,
                liveResultsURL: liveURL,
                watchURL: watchURL
            )
            meets.append(meet)
        }

        // Sort by priority (1 → 3), then alphabetical by name
        return meets.sorted {
            if $0.priority != $1.priority {
                return $0.priority.rawValue < $1.priority.rawValue
            }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    // Simple CSV splitter with quoted-field support
    private static func splitCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false

        for char in line {
            if char == "\"" {
                inQuotes.toggle()
                continue
            }

            if char == "," && !inQuotes {
                result.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }

        result.append(current)
        return result
    }
}

// MARK: - Sample Data (for previews only)

struct SampleData {
    static var sampleMeets: [Meet] {
        let calendar = Calendar.current
        let now = Date()

        func date(_ daysFromNow: Int) -> Date {
            calendar.date(byAdding: .day, value: daysFromNow, to: now) ?? now
        }

        return [
            Meet(
                date: date(-10),
                name: "NCAA D1 Regionals",
                level: "Collegiate",
                priority: .high,
                liveResultsURL: URL(string: "https://example.com/ncaa-regionals-live"),
                watchURL: URL(string: "https://example.com/ncaa-regionals-watch")
            ),
            Meet(
                date: date(-1),
                name: "Foot Locker Nationals",
                level: "High School",
                priority: .medium,
                liveResultsURL: URL(string: "https://example.com/footlocker-live"),
                watchURL: URL(string: "https://example.com/footlocker-watch")
            ),
            Meet(
                date: date(0),
                name: "NYC Holiday Classic",
                level: "Club",
                priority: .low,
                liveResultsURL: URL(string: "https://example.com/nyc-holiday-live"),
                watchURL: nil
            ),
            Meet(
                date: date(4),
                name: "USATF Winter Invite",
                level: "Professional",
                priority: .medium,
                liveResultsURL: URL(string: "https://example.com/usatf-winter-live"),
                watchURL: URL(string: "https://example.com/usatf-winter-watch")
            ),
            Meet(
                date: date(10),
                name: "National Indoor Grand Prix",
                level: "Professional",
                priority: .high,
                liveResultsURL: URL(string: "https://example.com/indoor-gp-live"),
                watchURL: URL(string: "https://example.com/indoor-gp-watch")
            )
        ]
    }
}

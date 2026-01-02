//
//  UserRace.swift
//  Watch Me Run
//
//  Created by Andy Kent on 12/15/25.
//

import Foundation

struct UserRace: Identifiable, Hashable {
    let id: String        // Firebase document ID or local UUID
    var name: String
    var distance: String  // e.g. "10 km", "26.2 M"
    var date: Date        // canonical UTC date-time for the race

    // New metadata fields
    /// IANA time zone identifier for where the race takes place (e.g. "America/New_York").
    /// This lets us render local times correctly for runners and friends.
    var timeZoneIdentifier: String?

    /// Human-readable race location, e.g. "New York, NY".
    var location: String

    /// Optional URLs for following the race.
    var liveResultsURL: URL?
    var watchURL: URL?
    var meetPageURL: URL?   // home / meet page link

    /// Levels this race applies to (e.g. "Hobby Jogging", "High School", "Collegiate", "Professional").
    /// Backed by free-form strings for now so we can evolve later.
    var levels: [String]

    /// Optional special instructions for following along (e.g. "Download the race app…").
    var instructions: String?

    /// Optional comments/goals/charity info for the race.
    var comments: String?

    init(
        id: String = UUID().uuidString,
        name: String,
        distance: String,
        date: Date,
        liveResultsURL: URL? = nil,
        watchURL: URL? = nil,
        timeZoneIdentifier: String? = TimeZone.current.identifier,
        location: String = "",
        meetPageURL: URL? = nil,
        levels: [String] = [],
        instructions: String? = nil,
        comments: String? = nil
    ) {
        self.id = id
        self.name = name
        self.distance = distance
        self.date = date
        self.liveResultsURL = liveResultsURL
        self.watchURL = watchURL
        self.timeZoneIdentifier = timeZoneIdentifier
        self.location = location
        self.meetPageURL = meetPageURL
        self.levels = levels
        self.instructions = instructions
        self.comments = comments
    }

    var isInPast: Bool {
        date < Date()
    }
}

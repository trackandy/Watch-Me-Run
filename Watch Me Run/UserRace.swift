//
//  UserRace.swift
//  Watch Me Run
//
//  Created by Andy Kent on 12/15/25.
//

import Foundation

struct UserRace: Identifiable, Hashable {
    let id: String        // we’ll use this for future Firebase IDs or local UUIDs
    var name: String
    var distance: String  // e.g. "10 km", "26.2 M"
    var date: Date
    var liveResultsURL: URL?
    var watchURL: URL?

    init(
        id: String = UUID().uuidString,
        name: String,
        distance: String,
        date: Date,
        liveResultsURL: URL? = nil,
        watchURL: URL? = nil
    ) {
        self.id = id
        self.name = name
        self.distance = distance
        self.date = date
        self.liveResultsURL = liveResultsURL
        self.watchURL = watchURL
    }

    var isInPast: Bool {
        date < Date()
    }
}

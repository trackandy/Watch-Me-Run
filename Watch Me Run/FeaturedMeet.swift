//
//  FeaturedMeet.swift
//  Watch Me Run
//
//  Created by Andy Kent on 1/3/26.
//

import Foundation

/// Model for a "featured" meet banner in the Results view.
/// Backed by documents in the Firestore `featuredmeets` collection.
struct WMRFeaturedMeet: Identifiable {
    let id: String              // Firestore document ID
    let name: String            // Meet name (e.g., "World XC Championships")
    let date: Date              // Start date/time for the overall featured meet
    let location: String?       // Optional location (e.g., "Belgrade, Serbia")
    let liveResultsURL: String? // Optional link to live results
    let watchURL: String?       // Optional link to livestream/coverage
    let homeMeetURL: String?    // Optional link to the meet home page

    /// Explicit initializer matching how `WMRFeaturedMeet` is constructed in `MeetStore`.
    init(
        id: String,
        name: String,
        date: Date,
        location: String? = nil,
        liveResultsURL: String? = nil,
        watchURL: String? = nil,
        homeMeetURL: String? = nil
    ) {
        self.id = id
        self.name = name
        self.date = date
        self.location = location
        self.liveResultsURL = liveResultsURL
        self.watchURL = watchURL
        self.homeMeetURL = homeMeetURL
    }
}

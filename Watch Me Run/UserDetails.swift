
//
//  UserDetails.swift
//  Watch Me Run
//
//  Created by Andy Kent on 1/2/26.
//

import Foundation
import FirebaseFirestore

/// Top-level user profile / runner details stored in `users/{uid}`.
///
/// This is separate from races, which live in `users/{uid}/races/{raceId}`.
struct UserDetails: Identifiable, Equatable {
    /// Firebase Auth UID (used as the document ID)
    let id: String

    /// Can other users search for and follow this runner in the Watching tab?
    var searchable: Bool

    /// Runner’s display name.
    var name: String

    /// Primary location, e.g. "Boulder, CO".
    var location: String

    /// Sex: "M" (male), "F" (female), "N" (non-binary / other).
    var sex: String

    /// Runner’s birthday. We derive age from this on the client.
    var birthday: Date?

    /// Team / club / pro group / school.
    var affiliation: String

    // MARK: - Convenience computed properties

    /// Computed age in whole years, if birthday is set.
    var age: Int? {
        guard let birthday else { return nil }
        let now = Date()
        let components = Calendar.current.dateComponents([.year], from: birthday, to: now)
        return components.year
    }

    // MARK: - Initializers

    init(
        id: String,
        searchable: Bool = true,
        name: String = "",
        location: String = "",
        sex: String = "N",
        birthday: Date? = nil,
        affiliation: String = ""
    ) {
        self.id = id
        self.searchable = searchable
        self.name = name
        self.location = location
        self.sex = sex
        self.birthday = birthday
        self.affiliation = affiliation
    }

    /// Initialize from a Firestore document data dictionary.
    /// - Parameters:
    ///   - id: The document ID (should match the Firebase Auth UID).
    ///   - data: Firestore document data.
    init(id: String, data: [String: Any]) {
        self.id = id

        self.searchable = data["searchable"] as? Bool ?? true
        self.name = data["name"] as? String ?? ""
        self.location = data["location"] as? String ?? ""
        self.sex = data["sex"] as? String ?? "N"

        if let ts = data["birthday"] as? Timestamp {
            self.birthday = ts.dateValue()
        } else if let date = data["birthday"] as? Date {
            self.birthday = date
        } else {
            self.birthday = nil
        }

        self.affiliation = data["affiliation"] as? String ?? ""
    }

    // MARK: - Firestore serialization

    /// Convert to a Firestore-ready dictionary for `setData(_:merge:)`.
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "searchable": searchable,
            "name": name,
            "location": location,
            "sex": sex,
            "affiliation": affiliation
        ]

        if let birthday {
            dict["birthday"] = birthday
        }

        return dict
    }
}


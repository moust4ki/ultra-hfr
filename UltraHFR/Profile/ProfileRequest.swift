//
//  ProfileRequest.swift
//  UltraHFR
//

/// Showing a member's profile from a message.
struct ProfileRequest: Identifiable, Hashable {
    var profileID: Int
    var pseudo: String
    var id: Int { profileID }
}

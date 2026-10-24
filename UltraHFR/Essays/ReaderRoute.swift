//
//  ReaderRoute.swift
//  UltraHFR
//

/// Opening a topic at a given page (`Int.max`-like values open the last page).
struct ReaderRoute: Hashable {
    let topic: EssayTopic
    let page: Int

    static let lastPage = 99_999
}

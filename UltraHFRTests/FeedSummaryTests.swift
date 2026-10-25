import Foundation
import Testing
@testable import UltraHFR

@MainActor
@Suite("Fil")
struct FeedSummaryTests {
    private func position(_ topic: Int, page: Int, pageCount: Int, daysAgo: Double) -> ReadingPosition {
        let position = ReadingPosition(topicID: topic, categoryID: 1, title: "t\(topic)", page: page, pageCount: pageCount, postID: topic * 10, postAuthor: "a")
        position.updatedAt = Date.now.addingTimeInterval(-daysAgo * 24 * 3600)
        return position
    }

    @Test func resumesTheLatestUnfinishedReadingOfTheWeek() {
        let finished = position(1, page: 10, pageCount: 10, daysAgo: 0.1)
        let unfinished = position(2, page: 3, pageCount: 5, daysAgo: 1)
        let old = position(3, page: 1, pageCount: 9, daysAgo: 8)
        #expect(FeedSummary.resume(in: [finished, unfinished, old])?.topicID == 2)
    }

    @Test func nothingToResumeWhenAllIsRead() {
        let finished = position(1, page: 10, pageCount: 10, daysAgo: 0.1)
        let old = position(3, page: 1, pageCount: 9, daysAgo: 8)
        #expect(FeedSummary.resume(in: [finished, old]) == nil)
    }

    @Test func markingReadEndsTheNews() {
        let unfinished = position(2, page: 3, pageCount: 5, daysAgo: 1)
        unfinished.lastPostAt = Date.now.addingTimeInterval(3600)
        #expect(unfinished.hasNews)
        unfinished.markRead()
        #expect(!unfinished.hasNews)
        #expect(unfinished.lastReadPost == nil)
        // Reopened on the last page, without a marker.
        #expect(unfinished.resumeRoute.page == TopicRoute.lastPage)
        #expect(unfinished.resumeRoute.newAfter == nil)
        #expect(FeedSummary.resume(in: [unfinished]) == nil)
    }
}

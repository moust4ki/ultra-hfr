import Foundation
import HFRKit
import SwiftData
import Testing
@testable import UltraHFR

@MainActor
@Suite("Position de lecture")
struct ReadingPositionRecorderTests {
    private let route = TopicRoute(title: "Blackwell", category: 1, topic: 1061629, page: 1)

    private func positions(in context: ModelContext) throws -> [ReadingPosition] {
        try context.fetch(FetchDescriptor<ReadingPosition>())
    }

    @Test func onlyMovesForwardLikeAFlag() throws {
        let container = try ModelContainer(for: ReadingPosition.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let recorder = ReadingPositionRecorder(context: context)

        recorder.record(topic: route, page: 350, pageCount: 697, post: 11_405_000, author: "Kaiju")
        // Going back to an older page keeps the last message read.
        recorder.record(topic: route, page: 2, pageCount: 697, post: 11_000_000, author: "Grumly")
        var saved = try #require(try positions(in: context).first)
        #expect(saved.page == 350)
        #expect(saved.postID == 11_405_000)
        #expect(saved.postAuthor == "Kaiju")

        recorder.record(topic: route, page: 351, pageCount: 698, post: 11_405_100, author: "Xixou2")
        saved = try #require(try positions(in: context).first)
        #expect(saved.page == 351)
        #expect(saved.pageCount == 698)
        #expect(try positions(in: context).count == 1)
    }

    @Test func listsTellTheFilWhatIsNew() throws {
        let container = try ModelContainer(for: ReadingPosition.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let recorder = ReadingPositionRecorder(context: context)
        recorder.record(topic: route, page: 350, pageCount: 350, post: 11_405_000, author: "Kaiju")
        var saved = try #require(try positions(in: context).first)
        #expect(!saved.hasNews)

        let later = Date.now.addingTimeInterval(3600)
        let listed = TopicSummary(
            id: 1061629, title: "Blackwell", path: "/hfr/Hardware/2D-3D/blackwell-sujet_1061629_1.htm",
            pageCount: 352, author: "Xixou2", lastPost: LastPost(author: "Grumly", date: later, path: "/hfr/Hardware/2D-3D/blackwell-sujet_1061629_352.htm")
        )
        let other = TopicSummary(id: 42, title: "Autre", path: "/hfr/Hardware/autre-sujet_42_1.htm", pageCount: 9, author: "x")
        recorder.noteListed([listed, other])
        saved = try #require(try positions(in: context).first)
        #expect(saved.unreadPages == 2)
        #expect(saved.lastPostAt == later)
        #expect(saved.hasNews)
        // Topics never read are not added.
        #expect(try positions(in: context).count == 1)
    }

    @Test func markedReadDoesNotGoBack() throws {
        let container = try ModelContainer(for: ReadingPosition.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let recorder = ReadingPositionRecorder(context: context)
        recorder.record(topic: route, page: 10, pageCount: 50, post: 11_000_000, author: "Kaiju")
        var saved = try #require(try positions(in: context).first)
        saved.markRead()
        #expect(saved.page == 50)

        // « Première page » from the Fil: the position stays at the end.
        recorder.record(topic: route, page: 1, pageCount: 50, post: 10_000_000, author: "Grumly")
        saved = try #require(try positions(in: context).first)
        #expect(saved.page == 50)
        #expect(!saved.hasNews)

        // Reading the last page moves it again, to the message.
        recorder.record(topic: route, page: 50, pageCount: 50, post: 11_900_000, author: "Xixou2")
        saved = try #require(try positions(in: context).first)
        #expect(saved.postID == 11_900_000)
    }

    @Test func readingOlderPagesKeepsTheNews() throws {
        let container = try ModelContainer(for: ReadingPosition.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let recorder = ReadingPositionRecorder(context: context)
        recorder.record(topic: route, page: 350, pageCount: 350, post: 11_405_000, author: "Kaiju")
        // A list says something was posted on the same page since.
        let listed = TopicSummary(
            id: 1061629, title: "Blackwell", path: "/hfr/Hardware/2D-3D/blackwell-sujet_1061629_1.htm",
            pageCount: 350, author: "Xixou2",
            lastPost: LastPost(author: "Grumly", date: .now.addingTimeInterval(60), path: "/hfr/Hardware/2D-3D/blackwell-sujet_1061629_350.htm")
        )
        recorder.noteListed([listed])
        #expect(try positions(in: context).first?.hasNews == true)

        // Reading page 2 again does not hide it, nor an older page count.
        recorder.record(topic: route, page: 2, pageCount: 2, post: 11_000_000, author: "Grumly")
        let saved = try #require(try positions(in: context).first)
        #expect(saved.hasNews)
        #expect(saved.pageCount == 350)
    }

    @Test func remembersTheLockForTheFil() throws {
        let container = try ModelContainer(for: ReadingPosition.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        var locked = route
        locked.isLocked = true
        ReadingPositionRecorder(context: context).record(topic: locked, page: 1, pageCount: 1, post: 1, author: "a")
        #expect(try positions(in: context).first?.isLocked == true)
    }

    @Test func listsOpenOnTheLastMessageReadWithTheMarkerWhenThereIsMore() throws {
        let position = ReadingPosition(topicID: 1061629, categoryID: 1, title: "Blackwell", page: 350, pageCount: 350, postID: 11_405_000, postAuthor: "Kaiju")
        let topic = TopicSummary(id: 1061629, title: "Blackwell", path: "/hfr/Hardware/2D-3D/blackwell-sujet_1061629_1.htm", pageCount: 352, author: "Xixou2")
        let route = TopicRowModel(topic: topic, position: position).route(category: 1)
        #expect(route.page == 350)
        #expect(route.anchor == 11_405_000)
        #expect(route.newAfter == 11_405_000)
    }
}

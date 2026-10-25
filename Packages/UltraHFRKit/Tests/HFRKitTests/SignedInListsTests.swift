import Testing
@testable import HFRKit

/// Lists only a signed-in member sees, on pages saved with a real account and anonymized.
@Suite("Listes vues connecté")
struct SignedInListsTests {
    @Test func flagsAreGroupedByCategory() throws {
        let page = try FollowedTopicsParser.parse(html: Fixture.html("connecte-drapeaux"))
        #expect(page.groups.count == 13)
        #expect(page.topics.count == 91)
        #expect(page.groups.allSatisfy { !$0.title.isEmpty })
        // A category where every flag is read keeps its header, without rows.
        #expect(page.groups.count(where: { $0.topics.isEmpty }) == 3)
        #expect(page.groups.first?.categoryID == 1)
        // Every topic of « Mes drapeaux » is followed, with the place where reading stopped.
        #expect(page.topics.allSatisfy { $0.flag != nil && $0.flagPath != nil })
        #expect(Set(page.topics.map(\.id)).count == page.topics.count)
    }

    @Test func favoritesAloneAreFollowedToo() throws {
        let page = try FollowedTopicsParser.parse(html: Fixture.html("connecte-favoris"))
        #expect(page.topics.count == 5)
        #expect(page.topics.contains { $0.flag == .favorite })
    }

    @Test func conversationsTellWhatIsUnread() throws {
        let page = try ConversationListParser.parse(html: Fixture.html("connecte-mp-liste"))
        #expect(page.conversations.count == 50)
        #expect(page.unreadCount == 1)
        #expect(page.conversations.first?.isUnread == true)
        #expect(page.conversations.allSatisfy { $0.id.rawValue > 0 && !$0.interlocutor.isEmpty && !$0.title.isEmpty })
        #expect(page.conversations.allSatisfy { $0.path.contains("cat=prive") })
    }

    @Test func aTopicListIsNotAConversationList() {
        #expect(throws: HFRParsingError.self) {
            try ConversationListParser.parse(html: Fixture.html("liste-hardware-p1"))
        }
    }

    @Test func topicListsShowTheMembersFlags() throws {
        let list = try TopicListParser.parse(html: Fixture.html("connecte-liste-hardware"))
        let flagged = list.topics.filter { $0.flag != nil }
        #expect(flagged.count == 6)
        #expect(flagged.allSatisfy { $0.flagPath != nil })
        #expect(flagged.contains { $0.flag == .favorite })
        #expect(flagged.contains { $0.flag == .red })
    }

    @Test func aTopicSeenSignedInOffersTheVote() throws {
        let page = try TopicPageParser.parse(html: Fixture.html("connecte-sujet"))
        #expect(page.posts.count == 41)
        let poll = try #require(page.poll)
        #expect(poll.canVote)
        #expect(poll.options.count == 4)
        #expect(poll.formFields["hash_check"] != nil)
    }

    @Test func replyFormsCarryTheirFields() throws {
        for (name, category) in [("connecte-sujet-repondre", "1"), ("connecte-mp-repondre", "prive")] {
            let form = try #require(try HTMLFormParser.form(in: Fixture.html(name), named: "hop"))
            let names = Set(form.fields.map(\.name))
            #expect(names.isSuperset(of: ["content_form", "hash_check", "post", "cat", "sujet"]))
            #expect(form.fields.first { $0.name == "cat" }?.value == category)
            #expect(form.action.contains("bddpost.php"))
        }
    }

    @Test func tellsASignedInPageFromAVisitorOne() throws {
        for name in ["connecte-accueil", "connecte-drapeaux", "connecte-mp-liste", "connecte-sujet", "connecte-mp"] {
            #expect(SignedInPage.isSignedIn(try Fixture.html(name)), "\(name)")
        }
        for name in ["accueil", "liste-hardware-p1", "sujet-court-p1"] {
            #expect(!SignedInPage.isSignedIn(try Fixture.html(name)), "\(name)")
        }
    }
}

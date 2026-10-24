//
//  EssayTopic.swift
//  UltraHFR
//

import HFRKit

/// A real topic used by the lot 0 essays.
struct EssayTopic: Identifiable, Hashable {
    let title: String
    let detail: String
    let category: CategoryID
    let topic: TopicID

    var id: TopicID { topic }

    static let samples: [EssayTopic] = [
        EssayTopic(title: "Topic Blackwell - Nvidia Geforce RTX 5000", detail: "Hardware · environ 700 pages · sondage", category: 1, topic: 1061629),
        EssayTopic(title: "[topic unik] Nintendo SWITCH / SWITCH 2", detail: "Jeux vidéo · plus de 7 000 pages · images", category: 5, topic: 185457),
        EssayTopic(title: "~~ BlindTest ~~", detail: "Musique · près de 8 000 pages · spoilers", category: 13, topic: 45986),
        EssayTopic(title: "Musique - Ce que vous écoutez en ce moment", detail: "Musique · vidéos YouTube", category: 13, topic: 8177),
        EssayTopic(title: "[blabla@olympe] Le topic du modo", detail: "Programmation · plus de 27 000 pages", category: 10, topic: 37483),
    ]
}

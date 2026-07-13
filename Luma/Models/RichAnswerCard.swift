import Foundation

/// A rich preview card the agent can attach to a reply, similar to the
/// illustrated answer cards in Apple's own assistant concepts (a recipe, a
/// place, an object explainer). Stage 1 renders these from mock content —
/// there is no live web/tool lookup yet.
struct RichAnswerCard: Identifiable, Hashable {
    let id: UUID
    var symbolName: String
    var title: String
    var subtitle: String
    var sourceLabel: String
}

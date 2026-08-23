import SwiftUI

/// Standard status conditions offered as quick-pick options in AddEffectView, each
/// with an SF Symbol + color for display. Plain generic English condition names —
/// not trademarked or ruleset-specific (single descriptive words like "stunned"
/// aren't ownable; see project history for the research behind this). Icons are
/// Apple's own SF Symbols, licensed for in-app UI use on Apple platforms.
struct StandardCondition: Identifiable {
    var id: String { name }
    let name: String
    let symbolName: String
    let color: Color
}

enum ConditionLibrary {
    static let all: [StandardCondition] = [
        StandardCondition(name: "Blinded", symbolName: "eye.slash.fill", color: .gray),
        StandardCondition(name: "Charmed", symbolName: "heart.fill", color: .pink),
        StandardCondition(name: "Deafened", symbolName: "ear.fill", color: .gray),
        StandardCondition(name: "Frightened", symbolName: "exclamationmark.triangle.fill", color: .purple),
        StandardCondition(name: "Grappled", symbolName: "hand.raised.fill", color: .brown),
        StandardCondition(name: "Incapacitated", symbolName: "bolt.slash.fill", color: .gray),
        StandardCondition(name: "Invisible", symbolName: "circle.dashed", color: .cyan),
        StandardCondition(name: "Paralyzed", symbolName: "bolt.fill", color: .yellow),
        StandardCondition(name: "Poisoned", symbolName: "drop.fill", color: .green),
        StandardCondition(name: "Prone", symbolName: "arrow.down.circle.fill", color: .brown),
        StandardCondition(name: "Restrained", symbolName: "link", color: .orange),
        StandardCondition(name: "Stunned", symbolName: "star.fill", color: .yellow),
        StandardCondition(name: "Unconscious", symbolName: "moon.zzz.fill", color: .indigo),
        StandardCondition(name: "Exhausted", symbolName: "battery.25", color: .gray),
        StandardCondition(name: "Burning", symbolName: "flame.fill", color: .red),
        StandardCondition(name: "Bleeding", symbolName: "drop.triangle.fill", color: .red),
    ]

    /// Case-insensitive lookup by name, for badges that display an existing Effect
    /// (which only stores a name string, not a reference back to the condition).
    static func matching(name: String) -> StandardCondition? {
        all.first { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }
    }
}

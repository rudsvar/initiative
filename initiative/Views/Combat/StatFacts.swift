import SwiftUI

/// The small facts of a creature's stat block, in a compact grid under the top box:
/// type, speed, challenge, senses and the rest. Only the facts the block has are
/// shown. Read-only: the numbers that change in a fight are edited in their own rows.
struct StatFacts: View {
    let block: StatBlock

    /// The facts shown, in order. Initiative comes first: the modifier and the passive score.
    static func facts(for block: StatBlock) -> [(String, String)] {
        var list: [(String, String)] = [
            ("Initiative", "\(Format.signed(block.initiative.modifier)) (\(block.initiative.score))"),
            ("Type", "\(block.size) \(block.type), \(block.alignment)"),
            ("Speed", block.speed),
            ("CR", "\(block.challenge.cr) · \(block.challenge.xp) XP"),
        ]
        if let senses = block.senses { list.append(("Senses", senses)) }
        if let languages = block.languages { list.append(("Languages", languages)) }
        if let skills = block.skills { list.append(("Skills", skills)) }
        if let resistances = block.resistances { list.append(("Resistant", resistances)) }
        if let immunities = block.immunities { list.append(("Immune", immunities)) }
        if let vulnerabilities = block.vulnerabilities { list.append(("Vulnerable", vulnerabilities)) }
        if let conditions = block.conditionImmunities { list.append(("Cond. immune", conditions)) }
        return list
    }

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: Theme.Spacing.md, verticalSpacing: Theme.Spacing.xxs) {
            ForEach(Self.facts(for: block), id: \.0) { label, value in
                GridRow {
                    Text(label)
                        .font(Theme.Typography.label)
                        .foregroundColor(Theme.textTertiary)
                    Text(value)
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.textPrimary)
                }
            }
        }
    }
}

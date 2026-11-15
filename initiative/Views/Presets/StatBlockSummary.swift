import SwiftUI

/// A built-in SRD creature's full stat block, read-only, laid out to be scanned at
/// the table: the combat numbers in one strip, abilities in one row, and the rest
/// in compact cards. Nothing here is editable.
struct StatBlockSummary: View {
    let block: StatBlock

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            header
            combatStrip
            abilityRow
            detailsCard
            if !block.traits.isEmpty { entriesCard(title: "Traits", entries: block.traits) }
            if !block.actions.isEmpty { entriesCard(title: "Actions", entries: block.actions) }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(block.name).cardHeading()
            Text("\(block.size) \(block.type), \(block.alignment)")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.textSecondary)
            Text("CR \(block.challenge.cr) · \(block.challenge.xp) XP · PB \(signed(block.challenge.proficiencyBonus))")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sectionCard()
    }

    /// AC, initiative, hit points and speed, one tile each.
    private var combatStrip: some View {
        HStack(spacing: Theme.Spacing.sm) {
            tile("Armor", "\(block.armorClass)", detail: nil)
            tile("Initiative", signed(block.initiative.modifier), detail: "(\(block.initiative.score))")
            tile("Hit Points", "\(block.hitPoints.average)", detail: block.hitPoints.formula)
            tile("Speed", block.speed, detail: nil)
        }
        .sectionCard()
    }

    private var abilityRow: some View {
        HStack(alignment: .top, spacing: 0) {
            ability("STR", block.abilities.str)
            ability("DEX", block.abilities.dex)
            ability("CON", block.abilities.con)
            ability("INT", block.abilities.int)
            ability("WIS", block.abilities.wis)
            ability("CHA", block.abilities.cha)
        }
        .sectionCard()
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            if let skills = block.skills { detail("Skills", skills) }
            if let gear = block.gear { detail("Gear", gear) }
            detail("Senses", block.senses)
            detail("Languages", block.languages)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sectionCard()
    }

    private func entriesCard(title: String, entries: [StatBlock.Entry]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(title).sectionLabel()
            ForEach(entries, id: \.name) { entry in
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.name)
                        .font(Theme.Typography.bodyEmphasis)
                        .foregroundColor(Theme.textPrimary)
                    Text(entry.text)
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sectionCard()
    }

    private func tile(_ label: String, _ value: String, detail: String?) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(Theme.Typography.label)
                .foregroundColor(Theme.textTertiary)
            Text(value)
                .font(Theme.Typography.numeric(18))
                .foregroundColor(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            if let detail {
                Text(detail)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// One ability: name, score, modifier, and the save only when it differs.
    private func ability(_ label: String, _ value: StatBlock.Ability) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(Theme.Typography.label)
                .foregroundColor(Theme.textTertiary)
            Text("\(value.score)")
                .font(Theme.Typography.bodyEmphasis)
                .foregroundColor(Theme.textPrimary)
            Text(signed(value.modifier))
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.textSecondary)
            if value.save != value.modifier {
                Text("save \(signed(value.save))")
                    .font(Theme.Typography.label)
                    .foregroundColor(Theme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func detail(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.sm) {
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.textTertiary)
                .frame(width: 72, alignment: .leading)
            Text(value)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.textPrimary)
        }
    }

    private func signed(_ n: Int) -> String {
        n >= 0 ? "+\(n)" : "\(n)"
    }
}

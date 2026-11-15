import SwiftUI

/// The full stat block of an SRD creature, as read-only form sections. Shown
/// under the three numbers on a built-in creature's detail screen, so the DM can
/// look up the rest at the table. Laid out densely: the stats a DM scans for
/// (AC, initiative, HP, abilities) sit in single rows, not one line each.
struct StatBlockSections: View {
    let block: StatBlock

    var body: some View {
        Section {
            Text("\(block.size) \(block.type), \(block.alignment)")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.textSecondary)

            HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                stat("AC", "\(block.armorClass)")
                stat("Init", "\(signed(block.initiative.modifier)) (\(block.initiative.score))")
                stat("HP", "\(block.hitPoints.average)")
            }
            .frame(maxWidth: .infinity)

            row("HP dice", block.hitPoints.formula)
            row("Speed", block.speed)
        } header: {
            Text("Stat Block")
        }
        .listRowBackground(Theme.surfaceRaised)

        Section("Abilities") {
            HStack(alignment: .top, spacing: 0) {
                ability("STR", block.abilities.str)
                ability("DEX", block.abilities.dex)
                ability("CON", block.abilities.con)
                ability("INT", block.abilities.int)
                ability("WIS", block.abilities.wis)
                ability("CHA", block.abilities.cha)
            }
            .frame(maxWidth: .infinity)
        }
        .listRowBackground(Theme.surfaceRaised)

        Section("Details") {
            if let skills = block.skills { row("Skills", skills) }
            if let gear = block.gear { row("Gear", gear) }
            row("Senses", block.senses)
            row("Languages", block.languages)
            row("CR", "\(block.challenge.cr) · \(block.challenge.xp) XP · PB \(signed(block.challenge.proficiencyBonus))")
        }
        .listRowBackground(Theme.surfaceRaised)

        if !block.traits.isEmpty {
            Section("Traits") {
                ForEach(block.traits, id: \.name) { entry in
                    entryView(entry)
                }
            }
            .listRowBackground(Theme.surfaceRaised)
        }

        if !block.actions.isEmpty {
            Section("Actions") {
                ForEach(block.actions, id: \.name) { entry in
                    entryView(entry)
                }
            }
            .listRowBackground(Theme.surfaceRaised)
        }
    }

    /// A label over a value, for the short numeric row (AC, Init, HP).
    private func stat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 0) {
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.textTertiary)
            Text(value)
                .font(Theme.Typography.bodyEmphasis)
                .foregroundColor(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity)
    }

    /// One ability column: name, score, modifier, and the save only when it differs.
    private func ability(_ label: String, _ value: StatBlock.Ability) -> some View {
        VStack(spacing: 0) {
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.textTertiary)
            Text("\(value.score)")
                .font(Theme.Typography.bodyEmphasis)
                .foregroundColor(Theme.textPrimary)
            Text(signed(value.modifier))
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.textSecondary)
            if value.save != value.modifier {
                Text("save \(signed(value.save))")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.sm) {
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.textTertiary)
            Spacer(minLength: Theme.Spacing.xs)
            Text(value)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }

    private func entryView(_ entry: StatBlock.Entry) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.name)
                .font(Theme.Typography.bodyEmphasis)
                .foregroundColor(Theme.textPrimary)
            Text(entry.text)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.textSecondary)
        }
    }

    private func signed(_ n: Int) -> String {
        n >= 0 ? "+\(n)" : "\(n)"
    }
}

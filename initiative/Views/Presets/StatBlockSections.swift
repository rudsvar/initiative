import SwiftUI

/// The full stat block of an SRD creature, as read-only form sections. Shown
/// under the three numbers on a built-in creature's detail screen, so the DM can
/// look up the rest at the table.
struct StatBlockSections: View {
    let block: StatBlock

    var body: some View {
        Section("Stat Block") {
            Text("\(block.size) \(block.type), \(block.alignment)")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.textSecondary)
        }
        .listRowBackground(Theme.surfaceRaised)

        Section("Combat") {
            row("Armor Class", "\(block.armorClass)")
            row("Initiative", "\(signed(block.initiative.modifier)) (\(block.initiative.score))")
            row("Hit Points", "\(block.hitPoints.average) (\(block.hitPoints.formula))")
            row("Speed", block.speed)
        }
        .listRowBackground(Theme.surfaceRaised)

        Section("Abilities") {
            ability("Str", block.abilities.str)
            ability("Dex", block.abilities.dex)
            ability("Con", block.abilities.con)
            ability("Int", block.abilities.int)
            ability("Wis", block.abilities.wis)
            ability("Cha", block.abilities.cha)
        }
        .listRowBackground(Theme.surfaceRaised)

        Section("Details") {
            if let skills = block.skills { row("Skills", skills) }
            if let gear = block.gear { row("Gear", gear) }
            row("Senses", block.senses)
            row("Languages", block.languages)
            row("Challenge", "\(block.challenge.cr) (\(block.challenge.xp) XP; PB \(signed(block.challenge.proficiencyBonus)))")
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

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.textSecondary)
            Spacer(minLength: Theme.Spacing.sm)
            Text(value)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }

    /// One ability per line: score and modifier, then the save when it differs.
    private func ability(_ label: String, _ value: StatBlock.Ability) -> some View {
        let saveNote = value.save == value.modifier ? "" : ", save \(signed(value.save))"
        return row(label, "\(value.score) (\(signed(value.modifier))\(saveNote))")
    }

    private func entryView(_ entry: StatBlock.Entry) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
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

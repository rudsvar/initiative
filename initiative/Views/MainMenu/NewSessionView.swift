import SwiftUI

/// Picker screen for starting a new session — replaces the earlier
/// confirmationDialog action sheet with a proper list screen matching the rest
/// of the app's styling, since the sheet felt out of place stacked in an
/// otherwise fully custom-themed app.
struct NewSessionView: View {
    let session: CombatSession
    let encounterStore: EncounterStore
    @Binding var path: NavigationPath

    // Read once per appearance rather than inside `body`: listEncounters() hits
    // disk, and body can re-run any number of times per frame.
    @State private var encounters: [Encounter] = []

    var body: some View {
        List {
            Section {
                Button(action: startFreshSession) {
                    row(
                        icon: "plus",
                        title: "Fresh Session",
                        subtitle: "Start empty and add combatants as you go"
                    )
                }
                .cardRowStyle()
                .cardRowLayout()
            }

            if !encounters.isEmpty {
                Section {
                    ForEach(encounters) { encounter in
                        Button(action: { startSession(from: encounter) }) {
                            row(
                                icon: "shield.lefthalf.filled",
                                title: encounter.name,
                                subtitle: entryDescription(for: encounter)
                            )
                        }
                        .cardRowStyle()
                        .cardRowLayout()
                    }
                } header: {
                    Text("From an Encounter")
                        .sectionLabel()
                        .listRowInsets(EdgeInsets(
                            top: Theme.Spacing.lg,
                            leading: Theme.Spacing.md,
                            bottom: Theme.Spacing.xs,
                            trailing: Theme.Spacing.md
                        ))
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .themedScreen()
        .navigationTitle("New Session")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { encounters = encounterStore.listEncounters() }
    }

    private func row(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(Theme.accent)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.Typography.rowTitle)
                    .foregroundColor(Theme.textPrimary)
                Text(subtitle)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.textTertiary)
            }

            Spacer()
        }
    }

    private func entryDescription(for encounter: Encounter) -> String {
        let creatures = encounter.entries.count
        let total = encounter.entries.reduce(0) { $0 + $1.count }
        let creatureWord = creatures == 1 ? "creature" : "creatures"
        return "\(creatures) \(creatureWord) · \(total) combatants"
    }

    private func startFreshSession() {
        session.reset()
        path.append(Route.combat)
    }

    private func startSession(from encounter: Encounter) {
        session.reset()
        for entry in encounter.entries {
            session.addCombatants(
                name: entry.name,
                initiative: nil,
                maxHP: entry.maxHP,
                armorClass: entry.armorClass,
                count: entry.count,
                initiativeBonus: entry.initiativeBonus ?? 0
            )
        }
        path.append(Route.combat)
    }
}

#Preview {
    NavigationStack {
        NewSessionView(session: CombatSession(), encounterStore: EncounterStore(), path: .constant(NavigationPath()))
    }
}

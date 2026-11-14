import SwiftUI

/// Picker screen for starting a new session — replaces the earlier
/// confirmationDialog action sheet with a proper list screen matching the rest
/// of the app's styling, since the sheet felt out of place stacked in an
/// otherwise fully custom-themed app.
struct NewSessionView: View {
    let session: CombatSession
    let encounterStore: EncounterStore
    @Binding var path: NavigationPath

    // Seeded eagerly rather than defaulting to `[]` and filling in via
    // `.onAppear` — see the matching note on `PresetListView`: an
    // empty-then-populated flip mounts `.searchable` for the first time on a
    // later render instead of the first one, which is what reads as the
    // search field's text doing a tiny resize on load.
    @State private var encounters: [Encounter]
    @State private var query = ""

    init(session: CombatSession, encounterStore: EncounterStore, path: Binding<NavigationPath>) {
        self.session = session
        self.encounterStore = encounterStore
        self._path = path
        _encounters = State(initialValue: encounterStore.listEncounters())
    }

    private var matches: [Encounter] {
        encounters.filter { ListSections.matchesAny(query: query, in: $0.searchableText) }
    }

    var body: some View {
        List {
            // Not filtered by the search query — starting fresh is always an
            // option regardless of what you typed looking for an encounter.
            Section {
                Button(action: startFreshSession) {
                    row(
                        icon: "plus",
                        title: "Fresh Session",
                        subtitle: "Start empty and add combatants as you go"
                    )
                }
                .buttonStyle(CardRowButtonStyle())
                .cardRowLayout()
            }

            // Split the same way the Encounters library itself does — the
            // user's own prepared encounters are what they'll reach for most
            // starting a session, not the built-ins mixed in among them.
            let groups = ListSections.split(matches, isBuiltIn: \.isBuiltIn)
            encounterSection("Yours", encounters: groups.mine)
            encounterSection("Included", encounters: groups.builtIn)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .appSearchable(text: $query, prompt: "Search encounters", isVisible: !encounters.isEmpty)
        .themedScreen()
        .navigationTitle("New Session")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { encounters = encounterStore.listEncounters() }
    }

    /// Hidden entirely when empty rather than shown as a bare header — same
    /// rule the Encounters/Creatures screens use for their own Yours/Included
    /// split.
    ///
    /// The title is a plain row inside the section, not `Section`'s own
    /// `header:` — a `List` in `.plain` style pins that header slot so it
    /// floats and follows the scroll instead of moving with its rows, which
    /// reads as a stray label stuck to the top of the screen. A row placed
    /// directly in the section's content scrolls normally like everything
    /// else, which is what a page-local grouping label should do.
    @ViewBuilder
    private func encounterSection(_ title: String, encounters sectionEncounters: [Encounter]) -> some View {
        if !sectionEncounters.isEmpty {
            Section {
                Text(title)
                    .sectionLabel()
                    .listRowInsets(EdgeInsets(
                        top: Theme.Spacing.lg,
                        leading: Theme.Spacing.md,
                        bottom: Theme.Spacing.xs,
                        trailing: Theme.Spacing.md
                    ))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                ForEach(sectionEncounters) { encounter in
                    Button(action: { startSession(from: encounter) }) {
                        row(
                            icon: "shield.lefthalf.filled",
                            title: encounter.name,
                            subtitle: entryDescription(for: encounter)
                        )
                    }
                    .buttonStyle(CardRowButtonStyle())
                    .cardRowLayout()
                }
            }
        }
    }

    private func row(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(Theme.Typography.iconRow)
                .foregroundColor(Theme.accent)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
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

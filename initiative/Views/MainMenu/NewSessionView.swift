import SwiftUI

/// Picker screen for starting a new session — replaces the earlier
/// confirmationDialog action sheet with a proper list screen matching the rest
/// of the app's styling, since the sheet felt out of place stacked in an
/// otherwise fully custom-themed app.
struct NewSessionView: View {
    let session: CombatSession
    let encounterStore: EncounterStore
    @Binding var path: NavigationPath

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            List {
                Button(action: startFreshSession) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Theme.accent)
                        Text("Fresh Session")
                            .font(.headline)
                            .foregroundColor(Theme.textPrimary)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .cardRowStyle()
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8))
                .listRowBackground(Color.clear)

                ForEach(encounterStore.listEncounters()) { encounter in
                    Button(action: { startSession(from: encounter) }) {
                        HStack {
                            Image(systemName: "shield.lefthalf.filled")
                                .foregroundColor(Theme.accent)
                            Text(encounter.name)
                                .font(.headline)
                                .foregroundColor(Theme.textPrimary)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .cardRowStyle()
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8))
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("New Session")
        .navigationBarTitleDisplayMode(.inline)
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

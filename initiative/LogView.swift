import SwiftUI

/// Feed of what's happened in combat (turns, damage, heals, adds/removes), grouped
/// by round, oldest round first, entries in chronological order within a round —
/// like a chat log, read top-to-bottom. Opens scrolled to the bottom (most recent
/// entry) since that's what you almost always want to see first. HP-affecting
/// entries (damage/heal/max-HP-increase/enable-tracking) can be swiped away —
/// deleting one recomputes the affected combatant's current/max HP from the
/// remaining entries. See CombatSession.deleteLogEntry/recomputeHP. Other entries
/// (turn changes, adds/removes, deaths) aren't deletable yet.
struct LogView: View {
    let session: CombatSession
    @Environment(\.dismiss) private var dismiss

    private var roundsAscending: [Int] {
        Set(session.log.map { $0.roundNumber }).sorted()
    }

    private func entries(forRound round: Int) -> [LogEntry] {
        session.log.filter { $0.roundNumber == round }
    }

    var body: some View {
        NavigationStack {
            Group {
                if session.log.isEmpty {
                    ContentUnavailableView(
                        "No Events Yet",
                        systemImage: "list.bullet.clipboard",
                        description: Text("Actions taken during combat appear here.")
                    )
                } else {
                    ScrollViewReader { proxy in
                        List {
                            ForEach(roundsAscending, id: \.self) { round in
                                Section("Round \(round)") {
                                    ForEach(entries(forRound: round)) { entry in
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(entry.text)
                                                .font(.subheadline)
                                            Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding(.vertical, 2)
                                        .id(entry.id)
                                        .swipeActions(edge: .trailing) {
                                            if entry.isDeletable {
                                                Button(role: .destructive) {
                                                    session.deleteLogEntry(entry.id)
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .onAppear {
                            if let lastId = session.log.last?.id {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    let session = CombatSession()
    session.addCombatant(name: "Goblin", initiative: 15, maxHP: 7)
    session.nextTurn()
    session.applyDamage(to: session.combatants[0].id, amount: 3)

    return LogView(session: session)
}

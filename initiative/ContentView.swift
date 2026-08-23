import SwiftUI

struct ContentView: View {
    let session: CombatSession
    let sessionStore: SessionStore
    let presetStore: PresetStore
    @Binding var path: NavigationPath

    @Environment(\.scenePhase) private var scenePhase
    @State private var pendingRemoveCombatant: Combatant?
    @State private var showAddCombatant = false
    @State private var showLog = false

    private var nameBinding: Binding<String> {
        Binding(get: { session.name }, set: { session.name = $0 })
    }

    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Text("Round \(session.roundNumber)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.accent)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                    .allowsHitTesting(false)

                List {
                    ForEach(session.sortedCombatants) { combatant in
                        CombatantRow(
                            combatant: combatant,
                            isCurrent: session.currentCombatant?.id == combatant.id
                        )
                        .contentShape(Rectangle())
                        .background(
                            NavigationLink(destination: CombatantDetailView(session: session, combatantId: combatant.id)) {
                                EmptyView()
                            }
                            .opacity(0)
                        )
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8))
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                pendingRemoveCombatant = combatant
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)

                if #available(iOS 26.0, *) {
                    GlassEffectContainer(spacing: 12) {
                        HStack(spacing: 12) {
                            Button(action: { session.previousTurn() }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                    Text("Previous")
                                }
                                .font(.system(size: 14, weight: .semibold))
                            }
                            .buttonStyle(.glass)
                            .disabled(!session.canGoToPreviousTurn)
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Button(action: { showLog = true }) {
                                Image(systemName: "list.bullet.clipboard")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .buttonStyle(.glass)
                            .frame(maxWidth: .infinity, alignment: .center)

                            Button(action: { session.nextTurn() }) {
                                HStack(spacing: 4) {
                                    Text("Next")
                                    Image(systemName: "chevron.right")
                                }
                                .font(.system(size: 14, weight: .semibold))
                            }
                            .buttonStyle(.glassProminent)
                            .tint(Theme.accent)
                            .disabled(session.sortedCombatants.isEmpty)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .padding(16)
                    }
                } else {
                    HStack(spacing: 12) {
                        Button(action: { session.previousTurn() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Previous")
                            }
                            .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(Theme.accent)
                        .disabled(!session.canGoToPreviousTurn)
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Button(action: { showLog = true }) {
                            Image(systemName: "list.bullet.clipboard")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(Theme.accent)
                        .frame(maxWidth: .infinity, alignment: .center)

                        Button(action: { session.nextTurn() }) {
                            HStack(spacing: 4) {
                                Text("Next")
                                Image(systemName: "chevron.right")
                            }
                            .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(Theme.accent)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .disabled(session.sortedCombatants.isEmpty)
                    }
                    .padding(16)
                    .background(Theme.background)
                    .borderTop(Theme.divider)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: backToMenu) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Menu")
                    }
                }
            }

            ToolbarItem(placement: .principal) {
                SelectAllTextField(text: nameBinding, placeholder: "Session Name")
                    .frame(width: 200)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { session.playerViewEnabled.toggle() }) {
                    Image(systemName: session.playerViewEnabled ? "eye.slash.fill" : "eye.fill")
                }
                .accessibilityLabel(session.playerViewEnabled ? "Showing approximate status (player view)" : "Showing exact status (DM view)")
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddCombatant = true }) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Combatant")
            }
        }
        .onDisappear { autosave() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                autosave()
            }
        }
        .confirmationDialog(
            "Remove \(pendingRemoveCombatant?.name ?? "")?",
            isPresented: Binding(
                get: { pendingRemoveCombatant != nil },
                set: { if !$0 { pendingRemoveCombatant = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                if let combatant = pendingRemoveCombatant {
                    session.removeCombatant(id: combatant.id)
                }
                pendingRemoveCombatant = nil
            }
            Button("Cancel", role: .cancel) {
                pendingRemoveCombatant = nil
            }
        }
        .sheet(isPresented: $showAddCombatant) {
            AddCombatantSheet(session: session, presetStore: presetStore, isPresented: $showAddCombatant)
        }
        .sheet(isPresented: $showLog) {
            LogView(session: session)
        }
    }

    private func backToMenu() {
        autosave()
        path.removeLast(path.count)
    }

    private func autosave() {
        guard !session.combatants.isEmpty else { return }
        sessionStore.save(session.makeRecord())
        sessionStore.setLastActiveSessionID(session.id)
    }
}

struct CombatantRow: View {
    let combatant: Combatant
    let isCurrent: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(combatant.name)
                            .font(.headline)
                            .foregroundColor(Theme.textPrimary)
                            .strikethrough(combatant.isDead)

                        if combatant.isDead {
                            Image(systemName: "skull.fill")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.black.opacity(0.7))
                                .clipShape(Circle())
                        }
                    }

                    // HP intentionally not shown here — main list stays spoiler-free
                    // even with the screen visible to players; see the combatant
                    // detail screen for HP (exact for the DM, or approximate with
                    // the eye-icon player-view toggle on).
                    Text("Init \(combatant.initiative)")
                        .font(.caption)
                        .foregroundColor(Theme.accent)
                        .fontWeight(.semibold)

                    // On its own row (not appended after Init/HP) so it lands at the
                    // same horizontal position across every row, regardless of
                    // whether HP text is present for a given combatant.
                    HStack(spacing: 6) {
                        LetterBadge(letter: "R", isOn: !combatant.reactionUsed, size: 14)
                        Text(combatant.reactionUsed ? "Reaction used" : "Reaction available")
                            .font(.caption)
                            .foregroundColor(combatant.reactionUsed ? Theme.divider : Theme.accent)
                    }
                }

                Spacer()

                if isCurrent {
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Theme.accent)
                    }
                }
            }

            if !combatant.visibleEffects.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(combatant.visibleEffects) { effect in
                        let condition = ConditionLibrary.matching(name: effect.name)
                        HStack(spacing: 8) {
                            Image(systemName: condition?.symbolName ?? "sparkles")
                                .font(.caption)
                                .foregroundColor(condition?.color ?? Theme.accent)
                            Text(effect.name)
                                .font(.caption)
                                .foregroundColor(Theme.textTertiary)
                        }
                    }
                }
                .padding(8)
                .background(Theme.divider.opacity(0.3))
                .cornerRadius(4)
            }
        }
        .padding(12)
        .background(isCurrent ? Theme.divider.opacity(0.3) : Color.clear)
        .cornerRadius(8)
        .opacity(combatant.isDead ? 0.55 : 1)
    }
}

#Preview {
    NavigationStack {
        ContentView(session: CombatSession(), sessionStore: SessionStore(), presetStore: PresetStore(), path: .constant(NavigationPath()))
    }
}

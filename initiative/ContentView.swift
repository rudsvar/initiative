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
                // Deliberately in the body, not the toolbar's .principal slot: nav
                // bar principal-item centering is relative to leading/trailing
                // button widths, not the true screen center — with a leading "Menu"
                // (icon+text) and a trailing "Add" (icon-only) of unequal width,
                // that visibly skews it off the true phone-screen center. A
                // body-level .frame(maxWidth: .infinity) row is reliably centered
                // regardless of toolbar contents (same fix used for the bottom
                // bar's Log button).
                SelectAllTextField(text: nameBinding, placeholder: "Session Name")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 22)
                    .padding(.top, 8)

                Text("Round \(session.roundNumber)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.accent)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)
                    .padding(.bottom, 4)
                    .allowsHitTesting(false)

                List {
                    ForEach(session.sortedCombatants) { combatant in
                        CombatantRow(
                            combatant: combatant,
                            isCurrent: session.currentCombatant?.id == combatant.id,
                            playerViewEnabled: session.playerViewEnabled
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

                            HStack(spacing: 8) {
                                Button(action: { showLog = true }) {
                                    Image(systemName: "list.bullet.clipboard")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .buttonStyle(.glass)

                                Button(action: { session.playerViewEnabled.toggle() }) {
                                    Image(systemName: session.playerViewEnabled ? "eye.slash.fill" : "eye.fill")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .buttonStyle(.glass)
                                .accessibilityLabel(session.playerViewEnabled ? "Showing approximate status (player view)" : "Showing exact status (DM view)")
                            }
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

                        HStack(spacing: 8) {
                            Button(action: { showLog = true }) {
                                Image(systemName: "list.bullet.clipboard")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(Theme.accent)

                            Button(action: { session.playerViewEnabled.toggle() }) {
                                Image(systemName: session.playerViewEnabled ? "eye.slash.fill" : "eye.fill")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(Theme.accent)
                            .accessibilityLabel(session.playerViewEnabled ? "Showing approximate status (player view)" : "Showing exact status (DM view)")
                        }
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
    let playerViewEnabled: Bool

    private var hasStatusRow: Bool {
        combatant.currentHP != nil || combatant.armorClass != nil
    }

    @ViewBuilder
    private var healthText: some View {
        if let current = combatant.currentHP, let max = combatant.maxHP {
            if playerViewEnabled {
                let band = StatusBand.health(current: current, max: max)
                Text(band.label).foregroundColor(band.color)
            } else {
                Text("\(current)/\(max) HP").foregroundColor(Theme.textSecondary)
            }
        }
    }

    @ViewBuilder
    private var armorClassText: some View {
        if let ac = combatant.armorClass {
            if playerViewEnabled {
                let band = StatusBand.armorClass(ac)
                Text(band.label).foregroundColor(band.color)
            } else {
                Text("AC \(ac)").foregroundColor(Theme.textSecondary)
            }
        }
    }

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

                    Text("Init \(combatant.initiative)")
                        .font(.caption)
                        .foregroundColor(Theme.accent)
                        .fontWeight(.semibold)

                    if hasStatusRow {
                        HStack(spacing: 8) {
                            healthText
                            armorClassText
                        }
                        .font(.caption)
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

            // Glance-at-a-glance list, not the detail screen — but still a short
            // label (e.g. "Stunned") alongside the icon in each chip, not bare
            // symbols alone. Reaction-used is just another status chip among the
            // rest, not a special text callout. Each status gets its own small
            // rounded chip, laid out via FlowLayout so several sit side by side
            // and wrap to the next line on overflow instead of clipping. Only
            // shown when there's something active — absence implies "none".
            if combatant.reactionUsed || !combatant.visibleEffects.isEmpty {
                FlowLayout(horizontalSpacing: 6, verticalSpacing: 6) {
                    if combatant.reactionUsed {
                        StatusChip(symbolName: "hand.tap", label: "Used", color: Theme.textTertiary)
                    }
                    ForEach(combatant.visibleEffects) { effect in
                        let condition = ConditionLibrary.matching(name: effect.name)
                        StatusChip(symbolName: condition?.symbolName ?? "sparkles", label: effect.name, color: condition?.color ?? Theme.accent)
                    }
                }
            }
        }
        .padding(12)
        .background(isCurrent ? Theme.divider.opacity(0.3) : Color.clear)
        .cornerRadius(8)
        .opacity(combatant.isDead ? 0.55 : 1)
    }
}

/// A single status symbol in its own small rounded, darker box — used for both
/// reaction-used and effect condition icons in the combatant list, laid out via
/// FlowLayout so several can sit side by side and wrap instead of clipping.
private struct StatusChip: View {
    let symbolName: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbolName)
                .font(.system(size: 12))
            Text(label)
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Theme.divider.opacity(0.4))
        .cornerRadius(6)
    }
}

#Preview {
    NavigationStack {
        ContentView(session: CombatSession(), sessionStore: SessionStore(), presetStore: PresetStore(), path: .constant(NavigationPath()))
    }
}

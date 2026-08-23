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
                                Button(action: { session.playerViewEnabled.toggle() }) {
                                    Image(systemName: session.playerViewEnabled ? "eye.slash.fill" : "eye.fill")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .buttonStyle(.glass)
                                .accessibilityLabel(session.playerViewEnabled ? "Showing approximate status (player view)" : "Showing exact status (DM view)")

                                Button(action: { showLog = true }) {
                                    Image(systemName: "list.bullet.clipboard")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .buttonStyle(.glass)
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
                            Button(action: { session.playerViewEnabled.toggle() }) {
                                Image(systemName: session.playerViewEnabled ? "eye.slash.fill" : "eye.fill")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(Theme.accent)
                            .accessibilityLabel(session.playerViewEnabled ? "Showing approximate status (player view)" : "Showing exact status (DM view)")

                            Button(action: { showLog = true }) {
                                Image(systemName: "list.bullet.clipboard")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(Theme.accent)
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
                // Icon-only (no "Menu" text): saves space and, just as importantly,
                // makes this item the same width as the trailing Add button below —
                // .principal centers relative to leading/trailing button widths, not
                // the true screen center, so two single-icon buttons of equal width
                // is what lets the session name/round below land dead center.
                Button(action: backToMenu) {
                    Image(systemName: "chevron.left")
                }
                .accessibilityLabel("Back to Menu")
            }

            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    SelectAllTextField(text: nameBinding, placeholder: "Session Name")
                        .frame(height: 20)
                    Text("Round \(session.roundNumber)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.accent)
                        .allowsHitTesting(false)
                }
                .frame(width: 200)
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

    // Measured explicitly rather than letting FlowLayout infer width from List's
    // row-sizing proposal: List can query a custom Layout's sizeThatFits with a
    // different (looser) width proposal than the one actually used to render the
    // row, which under-measures the wrapped height and clips the last row of
    // chips. Pinning FlowLayout to a known, stable width sidesteps the mismatch.
    @State private var rowWidth: CGFloat = 0

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
                // Big and on the far left, its own column — not a small caption
                // tucked under the name — so it reads immediately as the value the
                // list is actually sorted by, not just incidental info about the
                // combatant.
                Text("\(combatant.initiative)")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.accent)
                    .frame(width: 40, alignment: .center)

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
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear { rowWidth = geo.size.width }
                        .onChange(of: geo.size.width) { _, newWidth in rowWidth = newWidth }
                }
            )

            // Glance-at-a-glance list, not the detail screen — but still a short
            // label (e.g. "Stunned") alongside the icon in each chip, not bare
            // symbols alone. Reaction-used is just another status chip among the
            // rest, not a special text callout. Each status gets its own small
            // rounded chip, laid out via FlowLayout so several sit side by side
            // and wrap to the next line on overflow instead of clipping (see
            // rowWidth doc comment above for why width is pinned explicitly).
            // Only shown when there's something active — absence implies "none".
            if combatant.reactionUsed || !combatant.visibleEffects.isEmpty {
                FlowLayout(horizontalSpacing: 6, verticalSpacing: 6) {
                    if combatant.reactionUsed {
                        StatusChip(symbolName: "arrow.triangle.2.circlepath", label: "Reaction", color: Theme.textTertiary)
                    }
                    ForEach(combatant.visibleEffects) { effect in
                        let condition = ConditionLibrary.matching(name: effect.name)
                        StatusChip(symbolName: condition?.symbolName ?? "sparkles", label: effect.name, color: condition?.color ?? Theme.accent)
                    }
                }
                .frame(width: rowWidth > 0 ? rowWidth : nil, alignment: .leading)
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

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

                            Button(action: { showAddCombatant = true }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .buttonStyle(.glass)
                            .accessibilityLabel("Add Combatant")
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

                        Button(action: { showAddCombatant = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(Theme.accent)
                        .accessibilityLabel("Add Combatant")
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
            // Icon-only (no "Menu" text): keeps this item the same width as the
            // trailing hamburger button below, which is what lets .principal
            // center the session name/round on the true screen center.
            ToolbarItem(placement: .navigationBarLeading) {
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
                Menu {
                    Button {
                        session.playerViewEnabled.toggle()
                    } label: {
                        Label(
                            session.playerViewEnabled ? "Show DM View" : "Show Player View",
                            systemImage: session.playerViewEnabled ? "eye.slash.fill" : "eye.fill"
                        )
                    }
                    Button {
                        showLog = true
                    } label: {
                        Label("Log", systemImage: "list.bullet.clipboard")
                    }
                } label: {
                    Image(systemName: "line.3.horizontal")
                }
                .accessibilityLabel("Options")
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

    // Computed synchronously (not via GeometryReader + @State) so FlowLayout gets
    // a correct width on the very first layout pass. List rows are self-sizing
    // once, on first appearance — if the true width only became known a frame
    // later (as with a GeometryReader background), List had already committed a
    // too-short row height and never re-measured, clipping wrapped chip rows.
    // Screen width minus the row's own fixed insets is deterministic up front.
    private var rowWidth: CGFloat {
        UIScreen.main.bounds.width - 40 // 16 listRowInsets + 24 row padding
    }

    @ViewBuilder
    private var healthRow: some View {
        if let current = combatant.currentHP, let max = combatant.maxHP {
            let (text, color): (String, Color) = playerViewEnabled
                ? {
                    let band = StatusBand.health(current: current, max: max)
                    return (band.label, band.color)
                }()
                : ("\(current)/\(max)", Theme.textSecondary)
            HStack(spacing: 4) {
                Image(systemName: "heart.fill").font(.caption2)
                Text(text)
            }
            .foregroundColor(color)
        }
    }

    @ViewBuilder
    private var armorClassRow: some View {
        if let ac = combatant.armorClass {
            let (text, color): (String, Color) = playerViewEnabled
                ? {
                    let band = StatusBand.armorClass(ac)
                    return (band.label, band.color)
                }()
                : ("\(ac)", Theme.textSecondary)
            HStack(spacing: 4) {
                Image(systemName: "shield.fill").font(.caption2)
                Text(text)
            }
            .foregroundColor(color)
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

                Spacer()

                // Icon-led (heart/shield) instead of text labels ("14/20 HP"), and
                // left-aligned within their own column so the icons themselves
                // line up vertically regardless of how many digits each value has.
                VStack(alignment: .leading, spacing: 2) {
                    healthRow
                    armorClassRow
                }
                .font(.caption)
            }

            // Glance-at-a-glance list, not the detail screen — a short label (e.g.
            // "Stunned") alongside the icon in each chip, not bare symbols alone.
            // Reaction-used is just another status chip among the rest. FlowLayout
            // wraps to the next line on overflow instead of clipping.
            if combatant.reactionUsed || !combatant.visibleEffects.isEmpty {
                FlowLayout(horizontalSpacing: 6, verticalSpacing: 6) {
                    if combatant.reactionUsed {
                        StatusChip(symbolName: "arrow.uturn.left", label: "Reaction", color: Theme.textTertiary)
                    }
                    ForEach(combatant.visibleEffects) { effect in
                        let condition = ConditionLibrary.matching(name: effect.name)
                        StatusChip(symbolName: condition?.symbolName ?? "sparkles", label: effect.name, color: condition?.color ?? Theme.accent)
                    }
                }
                .frame(width: rowWidth, alignment: .leading)
            }
        }
        .padding(12)
        .background(isCurrent ? Theme.accent.opacity(0.22) : Theme.background)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isCurrent ? Theme.accent : Theme.divider, lineWidth: isCurrent ? 2 : 1)
        )
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

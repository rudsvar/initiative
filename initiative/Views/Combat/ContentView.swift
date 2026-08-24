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
                    .cardRowLayout()
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

            TurnControlBar(
                canGoBack: session.canGoToPreviousTurn,
                canAdvance: !session.sortedCombatants.isEmpty,
                onPrevious: { session.previousTurn() },
                onAdd: { showAddCombatant = true },
                onNext: { session.nextTurn() }
            )
        }
        .themedScreen()
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
                    SelectAllTextField(
                        text: nameBinding,
                        placeholder: "Session Name",
                        font: .preferredFont(forTextStyle: .headline).serif
                    )
                    .frame(height: 20)
                    Text("Round \(session.roundNumber)")
                        .font(Theme.Typography.label)
                        .textCase(.uppercase)
                        .tracking(0.9)
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

/// Previous / Add / Next, pinned below the initiative list. Written once with the
/// iOS 26 glass treatment applied conditionally, rather than as two near-identical
/// copies of the whole bar — the layout is the same either way, only the button
/// material differs.
private struct TurnControlBar: View {
    let canGoBack: Bool
    let canAdvance: Bool
    let onPrevious: () -> Void
    let onAdd: () -> Void
    let onNext: () -> Void

    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: Theme.Spacing.md) {
                content(glass: true)
            }
        } else {
            content(glass: false)
                .background(Theme.background)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Theme.border.opacity(0.5))
                        .frame(height: Theme.hairline)
                }
        }
    }

    private func content(glass: Bool) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            stepButton(
                label: "Previous",
                systemImage: "chevron.left",
                iconLeading: true,
                prominent: false,
                glass: glass
            ) { onPrevious() }
            .disabled(!canGoBack)
            .frame(maxWidth: .infinity, alignment: .leading)

            addButton(glass: glass)
                .frame(maxWidth: .infinity, alignment: .center)

            stepButton(
                label: "Next",
                systemImage: "chevron.right",
                iconLeading: false,
                prominent: true,
                glass: glass
            ) { onNext() }
            .disabled(!canAdvance)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(Theme.Spacing.lg)
    }

    @ViewBuilder
    private func stepButton(
        label: String,
        systemImage: String,
        iconLeading: Bool,
        prominent: Bool,
        glass: Bool,
        action: @escaping () -> Void
    ) -> some View {
        let content = Button(action: action) {
            HStack(spacing: Theme.Spacing.xs) {
                if iconLeading { Image(systemName: systemImage) }
                Text(label)
                if !iconLeading { Image(systemName: systemImage) }
            }
            .font(Theme.Typography.bodyEmphasis)
        }

        if glass, #available(iOS 26.0, *) {
            if prominent {
                content.buttonStyle(.glassProminent).tint(Theme.accent)
            } else {
                content.buttonStyle(.glass)
            }
        } else {
            content.foregroundColor(prominent ? Theme.accent : Theme.textSecondary)
        }
    }

    @ViewBuilder
    private func addButton(glass: Bool) -> some View {
        let content = Button(action: onAdd) {
            Image(systemName: "plus")
                .font(.system(size: 26, weight: .bold))
        }
        .accessibilityLabel("Add Combatant")

        if glass, #available(iOS 26.0, *) {
            content.buttonStyle(.glass)
        } else {
            content.foregroundColor(Theme.accent)
        }
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
        // 2 * Spacing.sm listRowInsets + 2 * Spacing.md cardRowStyle padding.
        UIScreen.main.bounds.width - (2 * Theme.Spacing.sm + 2 * Theme.Spacing.md)
    }

    @ViewBuilder
    private func statRow(systemImage: String, text: String, color: Color) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: systemImage)
                .font(.caption2)
                .frame(width: 12)
            Text(text)
        }
        .font(Theme.Typography.stat)
        .foregroundColor(color)
    }

    @ViewBuilder
    private var healthRow: some View {
        if let current = combatant.currentHP, let max = combatant.maxHP {
            if playerViewEnabled {
                let band = StatusBand.health(current: current, max: max)
                statRow(systemImage: "heart.fill", text: band.label, color: band.color)
            } else {
                statRow(systemImage: "heart.fill", text: "\(current)/\(max)", color: Theme.textSecondary)
            }
        }
    }

    @ViewBuilder
    private var armorClassRow: some View {
        if let ac = combatant.armorClass {
            if playerViewEnabled {
                let band = StatusBand.armorClass(ac)
                statRow(systemImage: "shield.fill", text: band.label, color: band.color)
            } else {
                statRow(systemImage: "shield.fill", text: "\(ac)", color: Theme.textSecondary)
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.md) {
                // Big and on the far left, its own column — not a small caption
                // tucked under the name — so it reads immediately as the value the
                // list is actually sorted by. Tabular figures keep the column from
                // shifting between one- and two-digit values. Only the current
                // combatant's number is accent-colored: gold marks exactly one
                // thing on this screen, and this is the screen's one thing.
                Text("\(combatant.initiative)")
                    .font(Theme.Typography.numeric(27))
                    .foregroundColor(isCurrent ? Theme.accent : Theme.textSecondary)
                    .frame(width: 40, alignment: .center)

                HStack(spacing: Theme.Spacing.xs + 2) {
                    Text(combatant.name)
                        .font(Theme.Typography.rowTitle)
                        .foregroundColor(Theme.textPrimary)
                        .strikethrough(combatant.isDead)

                    if combatant.isDead {
                        Image(systemName: "skull.fill")
                            .font(.caption2)
                            .foregroundColor(Theme.textPrimary)
                            .padding(Theme.Spacing.xs)
                            .background(Theme.background.opacity(0.8))
                            .clipShape(Circle())
                    }
                }

                Spacer(minLength: Theme.Spacing.sm)

                // Icon-led (heart/shield) instead of text labels ("14/20 HP"), and
                // left-aligned within their own column so the icons themselves
                // line up vertically regardless of how many digits each value has.
                VStack(alignment: .leading, spacing: 2) {
                    healthRow
                    armorClassRow
                }
            }

            // Glance-at-a-glance list, not the detail screen — a short label (e.g.
            // "Stunned") alongside the icon in each chip, not bare symbols alone.
            // Reaction-used is just another status chip among the rest. FlowLayout
            // wraps to the next line on overflow instead of clipping.
            if combatant.reactionUsed || !combatant.visibleEffects.isEmpty {
                FlowLayout {
                    if combatant.reactionUsed {
                        StatusChip(symbolName: "arrow.uturn.left", label: "Reaction", color: Theme.textTertiary)
                    }
                    ForEach(combatant.visibleEffects) { effect in
                        let condition = ConditionLibrary.matching(name: effect.name)
                        StatusChip(
                            symbolName: condition?.symbolName ?? "sparkles",
                            label: effect.name,
                            color: condition?.color ?? Theme.accent
                        )
                    }
                }
                .frame(width: rowWidth, alignment: .leading)
            }
        }
        .cardRowStyle(isHighlighted: isCurrent)
        .opacity(combatant.isDead ? 0.5 : 1)
    }
}

/// A single status in its own small chip — used for both reaction-used and effect
/// conditions in the combatant list, laid out via FlowLayout so several can sit
/// side by side and wrap instead of clipping. The chip takes its own color from
/// the condition's category (see `ConditionCategory`) at low opacity, so a row of
/// chips is legible as a group without any one of them competing with the accent.
private struct StatusChip: View {
    let symbolName: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: symbolName)
                .font(.system(size: 11))
            Text(label)
                .font(Theme.Typography.label)
        }
        .foregroundColor(color)
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, 5)
        .background(color.opacity(0.13))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                .stroke(color.opacity(0.28), lineWidth: Theme.hairline)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        ContentView(session: CombatSession(), sessionStore: SessionStore(), presetStore: PresetStore(), path: .constant(NavigationPath()))
    }
}

import SwiftUI

struct ContentView: View {
    let session: CombatSession
    let sessionStore: SessionStore
    @Binding var path: NavigationPath

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                List {
                    InlineAddCombatantRow(session: session)

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
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)

                HStack(spacing: 12) {
                    Button(action: { session.previousTurn() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Previous Turn")
                        }
                        .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(Theme.accent)
                    .disabled(!session.canGoToPreviousTurn)

                    Spacer()

                    Button(action: { session.nextTurn() }) {
                        HStack(spacing: 4) {
                            Text("Next Turn")
                            Image(systemName: "chevron.right")
                        }
                        .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(Theme.accent)
                    .disabled(session.sortedCombatants.isEmpty)
                }
                .padding(16)
                .background(Theme.background)
                .borderTop(Theme.divider)
            }
        }
        .navigationTitle("Initiative")
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
        }
        .onDisappear { autosave() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                autosave()
            }
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

struct InlineAddCombatantRow: View {
    let session: CombatSession
    @State private var name = ""
    @State private var initiativeText = ""
    @FocusState private var nameFieldFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            TextField("Name", text: $name)
                .focused($nameFieldFocused)
                .foregroundColor(Theme.textPrimary)
                .submitLabel(.done)
                .onSubmit { addCombatant() }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Theme.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Theme.divider, lineWidth: 1)
                )

            TextField("Initiative", text: $initiativeText)
                .keyboardType(.numberPad)
                .foregroundColor(Theme.accent)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .frame(width: 88)
                .background(Theme.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Theme.divider, lineWidth: 1)
                )

            Button(action: addCombatant) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Theme.accent)
            }
            .frame(width: 44, height: 44)
            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1)
        }
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8))
        .listRowBackground(Color.clear)
    }

    private func addCombatant() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        let initiative = Int(initiativeText) ?? Int.random(in: 1...20)
        session.addCombatant(name: trimmedName, initiative: initiative)

        name = ""
        initiativeText = ""
        nameFieldFocused = true
    }
}

struct CombatantRow: View {
    let combatant: Combatant
    let isCurrent: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(combatant.name)
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)

                    HStack(spacing: 8) {
                        Text("Init \(combatant.initiative)")
                            .font(.caption)
                            .foregroundColor(Theme.accent)
                            .fontWeight(.semibold)

                        if combatant.reactionUsed {
                            Label("Reaction used", systemImage: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(Theme.divider)
                        } else {
                            Label("Reaction available", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(Theme.accent)
                        }
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

            if !combatant.effects.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(combatant.effects) { effect in
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.caption)
                                .foregroundColor(Theme.accent)
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
    }
}

#Preview {
    NavigationStack {
        ContentView(session: CombatSession(), sessionStore: SessionStore(), path: .constant(NavigationPath()))
    }
}

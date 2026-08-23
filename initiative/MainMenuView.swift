import SwiftUI

struct MainMenuView: View {
    let session: CombatSession
    let sessionStore: SessionStore
    let presetStore: PresetStore
    let encounterStore: EncounterStore
    @Binding var path: NavigationPath

    @State private var showNewSessionChooser = false

    // Deliberately a stored, explicitly-refreshed @State rather than a computed
    // property: resumableSession() reads UserDefaults/disk, which @Observable
    // doesn't track, and MainMenuView is the NavigationStack's persistent root, so
    // popping back to it (e.g. after deleting a session) doesn't force a re-render
    // on its own — a computed property here would keep showing stale UI (a
    // "Resume" button that stayed red after its session was deleted, since body
    // never re-ran to notice). Refreshed on every appearance instead.
    @State private var canResume = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Theme.background
                .ignoresSafeArea()

            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 32) {
                        VStack(spacing: 4) {
                            Text("Initiative")
                                .font(.system(.largeTitle, design: .serif))
                                .fontWeight(.bold)
                                .foregroundColor(Theme.textPrimary)
                            Text("Combat Tracker")
                                .font(.subheadline)
                                .foregroundColor(Theme.textTertiary)
                        }
                        .multilineTextAlignment(.center)

                        VStack(spacing: 16) {
                            if canResume {
                                MenuButton(title: "Resume", systemImage: "play.circle.fill", isPrimary: true) {
                                    resume()
                                }
                            }

                            MenuButton(title: "New Session", systemImage: "plus.circle.fill") {
                                showNewSessionChooser = true
                            }

                            MenuButton(title: "Load Session", systemImage: "folder.fill") {
                                path.append(Route.sessionList)
                            }

                            MenuButton(title: "Encounters", systemImage: "shield.lefthalf.filled") {
                                path.append(Route.encounterList)
                            }

                            MenuButton(title: "Creatures", systemImage: "pawprint.fill") {
                                path.append(Route.presetList)
                            }
                        }
                        .padding(.horizontal, 32)
                    }
                    .padding(.vertical, 40)
                    .frame(minWidth: proxy.size.width, minHeight: proxy.size.height)
                }
            }

            // TEMPORARY: palette comparison, see Theme.swift's ThemePicker doc
            // comment. Must be last in the ZStack (topmost) — the GeometryReader/
            // ScrollView above fills the whole screen and would otherwise sit on
            // top of it in z-order and swallow the tap.
            ThemePicker()
                .foregroundColor(Theme.textTertiary)
                .padding()
        }
        .navigationBarHidden(true)
        .onAppear { canResume = sessionStore.resumableSession() != nil }
        .confirmationDialog("Start New Session", isPresented: $showNewSessionChooser, titleVisibility: .visible) {
            Button("Fresh Session") { startFreshSession() }
            ForEach(encounterStore.listEncounters()) { encounter in
                Button(encounter.name) { startSession(from: encounter) }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func resume() {
        guard let record = sessionStore.resumableSession() else { return }
        session.load(record)
        path.append(Route.combat)
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

private struct MenuButton: View {
    let title: String
    let systemImage: String
    var isPrimary: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.body)
                    .frame(width: 22, alignment: .center)
                Text(title)
                    .font(.body.weight(.semibold))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(minHeight: 44)
            .background(isPrimary ? Theme.accent : Theme.divider.opacity(0.2))
            .foregroundColor(isPrimary ? .white : Theme.textPrimary)
            .cornerRadius(10)
        }
    }
}

#Preview {
    NavigationStack {
        MainMenuView(session: CombatSession(), sessionStore: SessionStore(), presetStore: PresetStore(), encounterStore: EncounterStore(), path: .constant(NavigationPath()))
    }
}

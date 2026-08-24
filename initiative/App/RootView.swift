import SwiftUI

enum Route: Hashable {
    case combat
    case sessionList
    case presetList
    case encounterList
    case newSessionChooser
}

/// App-wide navigation root. Owns the single CombatSession, SessionStore,
/// PresetStore, and EncounterStore instances and the navigation path shared
/// across screens.
struct RootView: View {
    init() {
        Theme.applyNavigationBarAppearance()
    }

    @State private var session = CombatSession()
    @State private var sessionStore = SessionStore()
    @State private var presetStore = PresetStore()
    @State private var encounterStore = EncounterStore()
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            MainMenuView(
                session: session,
                sessionStore: sessionStore,
                presetStore: presetStore,
                path: $path
            )
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .combat:
                    ContentView(session: session, sessionStore: sessionStore, presetStore: presetStore, path: $path)
                case .sessionList:
                    SessionListView(session: session, sessionStore: sessionStore, path: $path)
                case .presetList:
                    PresetListView(presetStore: presetStore)
                case .encounterList:
                    EncounterListView(encounterStore: encounterStore, presetStore: presetStore)
                case .newSessionChooser:
                    NewSessionView(session: session, encounterStore: encounterStore, path: $path)
                }
            }
        }
        .onAppear { presetStore.seedDefaultsIfEmpty() }
        // Tavern Candlelight is a dark palette; forcing dark mode here makes every
        // system-provided color (Form/List default backgrounds, .primary/.secondary
        // text, placeholder text, native toolbar/nav bar chrome) follow suit
        // automatically instead of clashing with our dark background whenever the
        // device itself is in light mode. Screens still set Theme.background
        // explicitly where they want the exact warm-brown tint rather than the
        // system's neutral dark gray (see ContentView for the pattern).
        .preferredColorScheme(.dark)
        .tint(Theme.accent)
    }
}

#Preview {
    RootView()
}

import SwiftUI

enum Route: Hashable {
    case combat
    case sessionList
    case presetList
    case encounterList
}

/// App-wide navigation root. Owns the single CombatSession, SessionStore,
/// PresetStore, and EncounterStore instances and the navigation path shared
/// across screens.
struct RootView: View {
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
                encounterStore: encounterStore,
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
                }
            }
        }
        .onAppear { presetStore.seedDefaultsIfEmpty() }
    }
}

#Preview {
    RootView()
}

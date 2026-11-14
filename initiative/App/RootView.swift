import SwiftUI

enum Route: Hashable {
    case combat
    case sessionList
    case presetList
    case encounterList
    case newSessionChooser
    case appearance
    case combatantDetail(UUID)
}

/// App-wide navigation root. Owns the single CombatSession, SessionStore,
/// PresetStore, and EncounterStore instances and the navigation path shared
/// across screens.
struct RootView: View {
    init() {
        Theme.applyNavigationBarAppearance()
    }

    @State private var themeController = ThemeController.shared
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
                case .appearance:
                    AppearanceView(controller: themeController)
                case .combatantDetail(let combatantId):
                    CombatantDetailView(session: session, combatantId: combatantId)
                }
            }
        }
        // Runs on every launch, not just the first: built-in creatures and
        // encounters are permanent fixtures, so anything missing — new in this
        // version, or renamed away by the user — is put back.
        .onAppear {
            presetStore.installDefaults()
            encounterStore.installDefaults()
        }
        // Forcing the selected palette's appearance makes every system-provided
        // color (Form/List default backgrounds, .primary/.secondary text,
        // placeholder text, native toolbar chrome, the keyboard) follow it
        // automatically instead of clashing whenever the device's own setting
        // disagrees — which is why the palette declares an appearance rather than
        // the app hardcoding .dark: Parchment is light, and everything system-drawn
        // has to know that. Screens still set Theme.background explicitly where
        // they want the palette's exact tint rather than the system's neutral
        // gray (see ContentView for the pattern).
        .preferredColorScheme(Theme.colorScheme)
        .tint(Theme.accent)
    }
}

#Preview {
    RootView()
}

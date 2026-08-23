import SwiftUI

enum Route: Hashable {
    case combat
    case sessionList
}

/// App-wide navigation root. Owns the single CombatSession and SessionStore instances
/// and the navigation path shared by the menu and combat screens.
struct RootView: View {
    @State private var session = CombatSession()
    @State private var sessionStore = SessionStore()
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            MainMenuView(session: session, sessionStore: sessionStore, path: $path)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .combat:
                        ContentView(session: session, sessionStore: sessionStore, path: $path)
                    case .sessionList:
                        SessionListView(session: session, sessionStore: sessionStore, path: $path)
                    }
                }
        }
    }
}

#Preview {
    RootView()
}

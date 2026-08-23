import SwiftUI

struct MainMenuView: View {
    let session: CombatSession
    let sessionStore: SessionStore
    @Binding var path: NavigationPath

    private var hasAutosave: Bool {
        sessionStore.loadAutosave() != nil
    }

    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 4) {
                    Text("Initiative")
                        .font(.system(size: 34, weight: .bold, design: .serif))
                        .foregroundColor(Theme.textPrimary)
                    Text("Combat Tracker")
                        .font(.subheadline)
                        .foregroundColor(Theme.textTertiary)
                }

                VStack(spacing: 16) {
                    MenuButton(title: "Resume", systemImage: "play.circle.fill", isPrimary: true) {
                        resume()
                    }
                    .disabled(!hasAutosave)
                    .opacity(hasAutosave ? 1 : 0.4)

                    MenuButton(title: "New Session", systemImage: "plus.circle.fill") {
                        startNewSession()
                    }

                    MenuButton(title: "Load Session", systemImage: "folder.fill") {
                        path.append(Route.sessionList)
                    }
                }
                .padding(.horizontal, 32)

                Spacer()
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }

    private func resume() {
        guard let record = sessionStore.loadAutosave() else { return }
        session.load(record)
        path.append(Route.combat)
    }

    private func startNewSession() {
        session.reset()
        sessionStore.clearAutosave()
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
                    .font(.system(size: 18))
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(isPrimary ? Theme.accent : Theme.divider.opacity(0.2))
            .foregroundColor(isPrimary ? .white : Theme.textPrimary)
            .cornerRadius(10)
        }
    }
}

#Preview {
    NavigationStack {
        MainMenuView(session: CombatSession(), sessionStore: SessionStore(), path: .constant(NavigationPath()))
    }
}

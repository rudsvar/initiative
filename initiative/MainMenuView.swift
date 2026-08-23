import SwiftUI

struct MainMenuView: View {
    let session: CombatSession
    let sessionStore: SessionStore
    @Binding var path: NavigationPath

    private var canResume: Bool {
        sessionStore.resumableSession() != nil
    }

    var body: some View {
        ZStack {
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
                                startNewSession()
                            }

                            MenuButton(title: "Load Session", systemImage: "folder.fill") {
                                path.append(Route.sessionList)
                            }
                        }
                        .padding(.horizontal, 32)
                    }
                    .padding(.vertical, 40)
                    .frame(minWidth: proxy.size.width, minHeight: proxy.size.height)
                }
            }
        }
        .navigationBarHidden(true)
    }

    private func resume() {
        guard let record = sessionStore.resumableSession() else { return }
        session.load(record)
        path.append(Route.combat)
    }

    private func startNewSession() {
        session.reset()
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
        MainMenuView(session: CombatSession(), sessionStore: SessionStore(), path: .constant(NavigationPath()))
    }
}

import SwiftUI

struct MainMenuView: View {
    let session: CombatSession
    let sessionStore: SessionStore
    let presetStore: PresetStore
    @Binding var path: NavigationPath

    // Deliberately a stored, explicitly-refreshed @State rather than a computed
    // property: resumableSession() reads UserDefaults/disk, which @Observable
    // doesn't track, and MainMenuView is the NavigationStack's persistent root, so
    // popping back to it (e.g. after deleting a session) doesn't force a re-render
    // on its own — a computed property here would keep showing stale UI (a
    // "Resume" button that stayed red after its session was deleted, since body
    // never re-ran to notice). Refreshed on every appearance instead.
    @State private var canResume = false

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: Theme.Spacing.xxl) {
                    Spacer(minLength: 0)

                    Text("Instant Initiative")
                        .font(Theme.Typography.display)
                        .foregroundColor(Theme.textPrimary)
                        .multilineTextAlignment(.center)

                    VStack(spacing: Theme.Spacing.sm) {
                        // Exactly one filled, accent-colored button on the screen:
                        // whichever action the user most likely came here to take.
                        // Everything else is a quiet surface row, so the primary
                        // action is unmistakable without needing size or an icon
                        // treatment to shout about it.
                        if canResume {
                            MenuButton(title: "Resume", systemImage: "play.fill", isPrimary: true, action: resume)
                        } else {
                            MenuButton(title: "New Session", systemImage: "plus", isPrimary: true) {
                                path.append(Route.newSessionChooser)
                            }
                        }

                        if canResume {
                            MenuButton(title: "New Session", systemImage: "plus") {
                                path.append(Route.newSessionChooser)
                            }
                        }

                        MenuButton(title: "Load Session", systemImage: "clock.arrow.circlepath") {
                            path.append(Route.sessionList)
                        }

                        MenuButton(title: "Encounters", systemImage: "shield.lefthalf.filled") {
                            path.append(Route.encounterList)
                        }

                        MenuButton(title: "Creatures", systemImage: "pawprint") {
                            path.append(Route.presetList)
                        }

                        #if DEBUG
                        MenuButton(title: "Test Scenarios", systemImage: "ladybug") {
                            path.append(Route.scenarios)
                        }
                        #endif
                        MenuButton(title: "Appearance", systemImage: "paintpalette") {
                            path.append(Route.appearance)
                        }
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.vertical, Theme.Spacing.xxl)
                .frame(minWidth: proxy.size.width, minHeight: proxy.size.height)
            }
        }
        .themedScreen()
        .navigationBarHidden(true)
        .onAppear { canResume = sessionStore.resumableSession() != nil }
    }

    private func resume() {
        guard let record = sessionStore.resumableSession() else { return }
        session.load(record)
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
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: systemImage)
                    .font(Theme.Typography.iconRow)
                    .frame(width: 20, alignment: .center)

                Text(title)
                    .font(isPrimary ? Theme.Typography.rowTitle : Theme.Typography.body)

                Spacer()

                if !isPrimary {
                    Image(systemName: "chevron.right")
                        .font(Theme.Typography.iconControl)
                        .foregroundColor(Theme.textTertiary)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
            .frame(minHeight: 48)
            .foregroundColor(isPrimary ? Theme.accentForeground : Theme.textPrimary)
            .background(isPrimary ? Theme.accent : Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .stroke(isPrimary ? Color.clear : Theme.border.opacity(0.5), lineWidth: Theme.hairline)
            )
        }
    }
}

#Preview {
    NavigationStack {
        MainMenuView(session: CombatSession(), sessionStore: SessionStore(), presetStore: PresetStore(), path: .constant(NavigationPath()))
    }
}

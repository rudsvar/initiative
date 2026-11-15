#if DEBUG
import SwiftUI

/// Debug-only list of the test-only combats. Opening one replaces the current
/// session with that scenario and goes to the combat screen. Not in Release builds.
struct DebugScenariosView: View {
    let session: CombatSession
    @Binding var path: NavigationPath

    var body: some View {
        List {
            ForEach(TestCombats.scenarios.keys.sorted(), id: \.self) { name in
                Button(name) {
                    session.load(TestCombats.scenarios[name]!().makeRecord())
                    path.append(Route.combat)
                }
            }
        }
        .navigationTitle("Test Scenarios")
        .navigationBarTitleDisplayMode(.inline)
    }
}
#endif

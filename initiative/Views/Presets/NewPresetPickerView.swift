import SwiftUI

/// What "+" opens on Characters and Creatures: every saved character and creature
/// in the same list as the libraries, to copy from, plus a row to start from
/// nothing. Copying asks for a name first, exactly like Clone elsewhere. The kind
/// is the library the owner came from, so it is never asked.
struct NewPresetPickerView: View {
    let presetStore: PresetStore
    let characters: Bool
    /// Called after a copy or a new entry is saved, so the library reloads.
    let onChange: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var presets: [CreaturePreset]
    @State private var query = ""
    @State private var cloning: CreaturePreset?
    @State private var startingBlank = false

    init(presetStore: PresetStore, characters: Bool, onChange: @escaping () -> Void) {
        self.presetStore = presetStore
        self.characters = characters
        self.onChange = onChange
        _presets = State(initialValue: presetStore.listPresets())
    }

    private var noun: String { characters ? "Character" : "Creature" }

    private var matches: [CreaturePreset] {
        presets.filter { ListSections.matches(query: query, in: $0.searchableText) }
    }

    var body: some View {
        NavigationStack {
            Group {
                let groups = ListSections.split(matches, isBuiltIn: \.isBuiltIn)
                List {
                    Button(action: { startingBlank = true }) {
                        Label("New \(noun) from Scratch", systemImage: "plus")
                            .font(Theme.Typography.rowTitle)
                            .foregroundColor(Theme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(CardRowButtonStyle())
                    .cardRowLayout()

                    section("Yours", groups.mine)
                    section("Included", groups.builtIn)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
            .appSearchable(text: $query, prompt: "Search to copy from", isVisible: !presets.isEmpty)
            .themedScreen()
            .navigationTitle("New \(noun)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .navigationDestination(isPresented: $startingBlank) {
                CreatureDetailView(
                    presetStore: presetStore,
                    preset: CreaturePreset(name: "", isPlayer: characters),
                    onChange: { onChange(); dismiss() }
                )
            }
            .sheet(item: $cloning) { source in
                CloneNameSheet(
                    title: "Copy \(source.name)",
                    existingNames: presets.map(\.name)
                ) { newName, _ in
                    presetStore.clone(source, named: newName, isPlayer: characters)
                    onChange()
                    dismiss()
                }
            }
        }
    }

    @ViewBuilder
    private func section(_ title: String, _ items: [CreaturePreset]) -> some View {
        if !items.isEmpty {
            Section {
                Text(title)
                    .sectionLabel()
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                ForEach(items) { preset in
                    Button(action: { cloning = preset }) {
                        PresetRowLabel(preset: preset)
                    }
                    .buttonStyle(CardRowButtonStyle())
                    .cardRowLayout()
                }
            }
        }
    }
}

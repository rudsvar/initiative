import SwiftUI

/// Choose an existing character or creature to copy stats from. Searched and
/// split the same way as the libraries (`ListSections`), because a menu is
/// unusable once the built-in creatures are in it.
struct TemplatePickerView: View {
    let templates: [CreaturePreset]
    let onPick: (CreaturePreset?) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var matches: [CreaturePreset] {
        templates.filter { ListSections.matches(query: query, in: $0.searchableText) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if matches.isEmpty {
                    ContentUnavailableView.search(text: query)
                } else {
                    let groups = ListSections.split(matches, isBuiltIn: \.isBuiltIn)
                    List {
                        if query.isEmpty {
                            Button("None") { choose(nil) }
                                .buttonStyle(CardRowButtonStyle())
                                .cardRowLayout()
                        }
                        section("Yours", groups.mine)
                        section("Included", groups.builtIn)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .appSearchable(text: $query, prompt: "Search characters and creatures")
            .themedScreen()
            .navigationTitle("Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func choose(_ template: CreaturePreset?) {
        onPick(template)
        dismiss()
    }

    @ViewBuilder
    private func section(_ title: String, _ items: [CreaturePreset]) -> some View {
        if !items.isEmpty {
            Section {
                Text(title)
                    .sectionLabel()
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                ForEach(items) { template in
                    Button(action: { choose(template) }) {
                        Text(template.name)
                            .font(Theme.Typography.rowTitle)
                            .foregroundColor(Theme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(CardRowButtonStyle())
                    .cardRowLayout()
                }
            }
        }
    }
}

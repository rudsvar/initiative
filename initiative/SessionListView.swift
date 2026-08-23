import SwiftUI

struct SessionListView: View {
    let session: CombatSession
    let sessionStore: SessionStore
    @Binding var path: NavigationPath

    @State private var records: [SessionRecord] = []

    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()

            if records.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "folder")
                        .font(.system(size: 48))
                        .foregroundColor(Theme.divider)
                    Text("No saved sessions")
                        .font(.headline)
                        .foregroundColor(Theme.textSecondary)
                    Text("Sessions you save from the combat screen appear here")
                        .font(.subheadline)
                        .foregroundColor(Theme.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            } else {
                List {
                    ForEach(records) { record in
                        Button(action: { load(record) }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(record.name)
                                    .font(.headline)
                                    .foregroundColor(Theme.textPrimary)
                                Text("\(record.participants.count) participants · \(record.savedAt.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundColor(Theme.textTertiary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete(perform: deleteRecords)
                    .listRowBackground(Theme.background)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Load Session")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { records = sessionStore.listSavedSessions() }
    }

    private func load(_ record: SessionRecord) {
        session.load(record)
        path.append(Route.combat)
    }

    private func deleteRecords(at offsets: IndexSet) {
        for index in offsets {
            sessionStore.delete(id: records[index].id)
        }
        records = sessionStore.listSavedSessions()
    }
}

#Preview {
    NavigationStack {
        SessionListView(session: CombatSession(), sessionStore: SessionStore(), path: .constant(NavigationPath()))
    }
}

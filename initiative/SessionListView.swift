import SwiftUI

struct SessionListView: View {
    let session: CombatSession
    let sessionStore: SessionStore
    @Binding var path: NavigationPath

    @State private var records: [SessionRecord] = []
    @State private var pendingDeleteRecord: SessionRecord?

    var body: some View {
        Group {
            if records.isEmpty {
                ContentUnavailableView(
                    "No Saved Sessions",
                    systemImage: "folder",
                    description: Text("Sessions save automatically as you play and appear here.")
                )
            } else {
                List {
                    ForEach(records) { record in
                        Button(action: { load(record) }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(record.name)
                                    .font(.headline)
                                Text("\(record.participants.count) participants · \(record.savedAt.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .tint(.primary)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                pendingDeleteRecord = record
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Load Session")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { records = sessionStore.listSavedSessions() }
        .confirmationDialog(
            "Delete \"\(pendingDeleteRecord?.name ?? "")\"?",
            isPresented: Binding(
                get: { pendingDeleteRecord != nil },
                set: { if !$0 { pendingDeleteRecord = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let record = pendingDeleteRecord {
                    sessionStore.delete(id: record.id)
                    records = sessionStore.listSavedSessions()
                }
                pendingDeleteRecord = nil
            }
            Button("Cancel", role: .cancel) {
                pendingDeleteRecord = nil
            }
        }
    }

    private func load(_ record: SessionRecord) {
        session.load(record)
        sessionStore.setLastActiveSessionID(record.id)
        path.append(Route.combat)
    }
}

#Preview {
    NavigationStack {
        SessionListView(session: CombatSession(), sessionStore: SessionStore(), path: .constant(NavigationPath()))
    }
}

 import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Checklist.updatedAt, order: .reverse) private var checklists: [Checklist]
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                if checklists.isEmpty && viewModel.searchText.isEmpty && viewModel.selectedCategory == nil {
                    emptyStateView
                } else {
                    checklistListView
                }

                // FAB
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            viewModel.showingCreateSheet = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.accentColor)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("チェックリスト")
            .searchable(text: $viewModel.searchText, prompt: "検索")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button {
                            viewModel.selectedCategory = nil
                        } label: {
                            Label("すべて", systemImage: viewModel.selectedCategory == nil ? "checkmark" : "")
                        }

                        Divider()

                        ForEach(Category.allCases, id: \.self) { category in
                            Button {
                                viewModel.selectedCategory = category
                            } label: {
                                Label(category.description, systemImage: viewModel.selectedCategory == category ? "checkmark" : "")
                            }
                        }
                    } label: {
                        Label("フィルター", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingCreateSheet) {
                CreateChecklistView()
            }
            .sheet(isPresented: $viewModel.showingSettings) {
                SettingsView()
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checklist")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("チェックリストがありません")
                .font(.title2)
                .fontWeight(.medium)

            Text("右下の+ボタンから\n新しいチェックリストを作成しましょう")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var checklistListView: some View {
        List {
            let filtered = viewModel.filteredChecklists(checklists)

            if filtered.isEmpty {
                ContentUnavailableView(
                    "該当するチェックリストがありません",
                    systemImage: "magnifyingglass",
                    description: Text("検索条件を変更してください")
                )
            } else {
                ForEach(filtered) { checklist in
                    NavigationLink(destination: ChecklistDetailView(checklist: checklist)) {
                        ChecklistRowView(checklist: checklist)
                    }
                }
                .onDelete { indexSet in
                    viewModel.deleteChecklists(at: indexSet, from: checklists, modelContext: modelContext)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Checklist.self, inMemory: true)
}

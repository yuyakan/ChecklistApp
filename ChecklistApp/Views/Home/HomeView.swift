import SwiftUI
import CoreData
import WidgetKit

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var navigationState: NavigationState
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CDChecklist.updatedAt, ascending: false)],
        animation: .default
    ) private var checklists: FetchedResults<CDChecklist>
    @StateObject private var viewModel = HomeViewModel()
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // Neumorphic background
                Color.neumorphicBackground.ignoresSafeArea()

                if checklists.isEmpty && viewModel.searchText.isEmpty && viewModel.selectedCategory == nil {
                    emptyStateView
                } else {
                    checklistScrollView
                }

                if viewModel.isSelecting {
                    // Selection mode bottom bar
                    VStack {
                        Spacer()
                        selectionBottomBar
                    }
                } else {
                    // Neumorphic FAB
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            NeumorphicFAB {
                                viewModel.showingCreateSheet = true
                            }
                            .padding(NeumorphicSpacing.lg)
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $viewModel.searchText, prompt: "検索")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker(selection: $viewModel.selectedCategory) {
                            Text("すべて").tag(Category?.none)

                            Divider()

                            ForEach(Category.allCases, id: \.self) { category in
                                Text(category.description).tag(Category?.some(category))
                            }
                        } label: {
                            EmptyView()
                        }
                    } label: {
                        Image(systemName: viewModel.selectedCategory != nil ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .foregroundStyle(viewModel.selectedCategory != nil ? Color.accentOrangeStart : Color.neumorphicTextSecondary)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: NeumorphicSpacing.sm) {
                        if viewModel.isSelecting {
                            Button {
                                viewModel.exitSelectionMode()
                            } label: {
                                Text("キャンセル")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.neumorphicTextSecondary)
                            }
                        } else {
                            if !checklists.isEmpty {
                                Button {
                                    viewModel.isSelecting = true
                                } label: {
                                    Image(systemName: "trash.circle")
                                        .foregroundStyle(Color.neumorphicTextSecondary)
                                }
                            }

                            Button {
                                viewModel.showingSettings = true
                            } label: {
                                Image(systemName: "gearshape")
                                    .foregroundStyle(Color.neumorphicTextSecondary)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingCreateSheet) {
                CreateChecklistView()
            }
            .sheet(isPresented: $viewModel.showingSettings) {
                SettingsView()
            }
            .alert("チェックリストを削除", isPresented: $viewModel.showingDeleteConfirmation) {
                Button("削除", role: .destructive) {
                    viewModel.deleteSelectedChecklists(from: Array(checklists), context: viewContext)
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("\(viewModel.selectedChecklistIDs.count)件のチェックリストを削除しますか？この操作は取り消せません。")
            }
            .navigationDestination(for: NSManagedObjectID.self) { objectID in
                if let checklist = viewContext.object(with: objectID) as? CDChecklist {
                    ChecklistDetailView(checklist: checklist)
                }
            }
            .onChange(of: navigationState.selectedChecklistId) { _, newId in
                if let checklistId = newId,
                   let checklist = checklists.first(where: { $0.wrappedId == checklistId }) {
                    navigationPath.append(checklist.objectID)
                    navigationState.selectedChecklistId = nil
                }
            }
        }
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: NeumorphicSpacing.lg) {
            // Neumorphic icon container
            ZStack {
                Circle()
                    .fill(Color.neumorphicSurface)
                    .frame(width: 120, height: 120)
                    .neumorphicShadow()

                Image(systemName: "checklist")
                    .font(.system(size: 50))
                    .foregroundStyle(Color.orangeGradient)
            }

            Text("チェックリストがありません")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(Color.neumorphicTextPrimary)

            Text("右下の+ボタンから\n新しいチェックリストを作成しましょう")
                .font(.body)
                .foregroundStyle(Color.neumorphicTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(NeumorphicSpacing.xl)
    }

    // MARK: - Checklist Scroll View

    private var checklistScrollView: some View {
        ScrollView {
            let filtered = viewModel.filteredChecklists(Array(checklists))

            if filtered.isEmpty {
                // Empty search result
                VStack(spacing: NeumorphicSpacing.md) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.neumorphicTextTertiary)

                    Text("該当するチェックリストがありません")
                        .font(.headline)
                        .foregroundStyle(Color.neumorphicTextSecondary)

                    Text("検索条件を変更してください")
                        .font(.subheadline)
                        .foregroundStyle(Color.neumorphicTextTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 100)
            } else {
                LazyVStack(spacing: NeumorphicSpacing.md) {
                    ForEach(filtered, id: \.objectID) { checklist in
                        if viewModel.isSelecting {
                            Button {
                                viewModel.toggleSelection(checklist)
                            } label: {
                                HStack(spacing: NeumorphicSpacing.sm) {
                                    Image(systemName: viewModel.selectedChecklistIDs.contains(checklist.objectID) ? "checkmark.circle.fill" : "circle")
                                        .font(.title3)
                                        .foregroundStyle(viewModel.selectedChecklistIDs.contains(checklist.objectID) ? Color.accentOrangeStart : Color.neumorphicTextTertiary)

                                    ChecklistCardView(checklist: checklist)
                                }
                            }
                            .buttonStyle(.plain)
                        } else {
                            NavigationLink(value: checklist.objectID) {
                                ChecklistCardView(checklist: checklist)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    deleteChecklist(checklist)
                                } label: {
                                    Label("削除", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, NeumorphicSpacing.md)
                .padding(.top, NeumorphicSpacing.md)
                .padding(.bottom, 100) // Space for FAB
            }
        }
    }

    // MARK: - Selection Bottom Bar

    private var selectionBottomBar: some View {
        let count = viewModel.selectedChecklistIDs.count
        let filtered = viewModel.filteredChecklists(Array(checklists))
        let allSelected = !filtered.isEmpty && filtered.allSatisfy { viewModel.selectedChecklistIDs.contains($0.objectID) }

        return HStack {
            Button {
                if allSelected {
                    viewModel.selectedChecklistIDs.removeAll()
                } else {
                    viewModel.selectedChecklistIDs = Set(filtered.map { $0.objectID })
                }
            } label: {
                Text(allSelected ? "すべて解除" : "すべて選択")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.accentOrangeStart)
            }

            Spacer()

            Button {
                viewModel.showingDeleteConfirmation = true
            } label: {
                Image(systemName: "trash")
                    .font(.title3)
                    .foregroundStyle(count > 0 ? Color.statusError : Color.neumorphicTextTertiary)
            }
            .disabled(count == 0)
        }
        .padding(.horizontal, NeumorphicSpacing.lg)
        .padding(.vertical, NeumorphicSpacing.md)
        .background(
            Color.neumorphicSurface
                .shadow(color: Color.neumorphicDarkShadow, radius: 8, x: 0, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - Actions

    private func deleteChecklist(_ checklist: CDChecklist) {
        viewContext.delete(checklist)
        try? viewContext.save()
        WidgetKit.WidgetCenter.shared.reloadAllTimelines()
    }
}

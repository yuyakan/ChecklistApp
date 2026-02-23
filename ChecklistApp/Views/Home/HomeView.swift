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
                    Button {
                        viewModel.showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Color.neumorphicTextSecondary)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingCreateSheet) {
                CreateChecklistView()
            }
            .sheet(isPresented: $viewModel.showingSettings) {
                SettingsView()
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
                .padding(.horizontal, NeumorphicSpacing.md)
                .padding(.top, NeumorphicSpacing.md)
                .padding(.bottom, 100) // Space for FAB
            }
        }
    }

    // MARK: - Actions

    private func deleteChecklist(_ checklist: CDChecklist) {
        viewContext.delete(checklist)
        try? viewContext.save()
        WidgetKit.WidgetCenter.shared.reloadAllTimelines()
    }
}

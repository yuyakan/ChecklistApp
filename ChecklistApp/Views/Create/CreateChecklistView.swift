import SwiftUI
import CoreData
import WidgetKit

struct CreateChecklistView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CreateChecklistViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                // Neumorphic background
                Color.neumorphicBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Mode selector
                    modeSelector
                        .padding(.horizontal, NeumorphicSpacing.md)
                        .padding(.top, NeumorphicSpacing.md)

                    // Content for each mode
                    ScrollView {
                        VStack(spacing: NeumorphicSpacing.lg) {
                            switch viewModel.selectedMode {
                            case .manual:
                                ManualChecklistView(viewModel: viewModel)
                            case .photo:
                                PhotoInputView(viewModel: viewModel)
                            case .voice:
                                VoiceInputView(viewModel: viewModel)
                            case .text:
                                TextInputView(viewModel: viewModel)
                            case .aiGenerate:
                                AIGenerateView(viewModel: viewModel)
                            }
                        }
                        .padding(NeumorphicSpacing.md)
                    }
                }

                // Processing overlay
                if viewModel.isProcessing {
                    processingOverlay
                }
            }
            .navigationTitle("新規作成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundStyle(Color.neumorphicTextSecondary)
                }
            }
            .alert("エラー", isPresented: $viewModel.showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "不明なエラーが発生しました")
            }
            .sheet(isPresented: $viewModel.showingResult) {
                if let draft = viewModel.generatedDraft {
                    ChecklistPreviewView(draft: draft) { finalDraft in
                        saveDraft(finalDraft)
                    }
                    .iPadExpandedModalLayout()
                }
            }
        }
    }

    private var modeSelector: some View {
        NeumorphicSegmentedControl(
            options: CreateInputMode.allCases,
            selection: $viewModel.selectedMode,
            label: { $0.title },
            icon: { $0.icon }
        )
    }

    private var processingOverlay: some View {
        ZStack {
            Color.neumorphicBackground.opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: NeumorphicSpacing.lg) {
                // Neumorphic loading indicator
                ZStack {
                    Circle()
                        .fill(Color.neumorphicSurface)
                        .frame(width: 80, height: 80)
                        .neumorphicShadow()

                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(Color.accentOrangeStart)
                }

                Text("処理中...")
                    .font(.headline)
                    .foregroundStyle(Color.neumorphicTextPrimary)
            }
        }
    }

    private func saveDraft(_ draft: ChecklistDraft) {
        let checklist = draft.save(to: viewContext)
        do {
            try viewContext.save()
            print("[CloudKit Debug] CoreData save succeeded.")
            print("[CloudKit Debug] Checklist store: \(checklist.objectID.persistentStore?.url?.lastPathComponent ?? "nil")")
            print("[CloudKit Debug] Checklist objectID isTemporary: \(checklist.objectID.isTemporaryID)")
            for item in checklist.itemsArray {
                print("[CloudKit Debug] Item '\(item.wrappedName)' store: \(item.objectID.persistentStore?.url?.lastPathComponent ?? "nil")")
            }
        } catch {
            print("[CloudKit Debug] CoreData save FAILED: \(error)")
        }
        viewModel.reset()
        WidgetCenter.shared.reloadAllTimelines()

        dismiss()
    }
}

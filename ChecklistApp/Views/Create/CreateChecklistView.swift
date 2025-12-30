 import SwiftUI
import SwiftData

struct CreateChecklistView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CreateChecklistViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // モード選択タブ
                modeSelector

                Divider()

                // 各モードのコンテンツ
                ScrollView {
                    VStack(spacing: 20) {
                        switch viewModel.selectedMode {
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
                    .padding()
                }

                // 処理中インジケータ
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
                }
            }
            .alert("エラー", isPresented: $viewModel.showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "不明なエラーが発生しました")
            }
            .sheet(isPresented: $viewModel.showingResult) {
                if let checklist = viewModel.generatedChecklist {
                    ChecklistPreviewView(checklist: checklist) {
                        saveChecklist(checklist)
                    }
                }
            }
        }
    }

    private var modeSelector: some View {
        HStack(spacing: 0) {
            ForEach(CreateInputMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectedMode = mode
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: mode.icon)
                            .font(.title3)
                        Text(mode.title)
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(viewModel.selectedMode == mode ? Color.accentColor.opacity(0.1) : Color.clear)
                    .foregroundStyle(viewModel.selectedMode == mode ? .primary : .secondary)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    private var processingOverlay: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("処理中...")
                .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }

    private func saveChecklist(_ checklist: Checklist) {
        modelContext.insert(checklist)
        viewModel.reset()
        dismiss()
    }
}

#Preview {
    CreateChecklistView()
        .modelContainer(for: Checklist.self, inMemory: true)
}

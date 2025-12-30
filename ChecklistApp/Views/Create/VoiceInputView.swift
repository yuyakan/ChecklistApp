import SwiftUI

struct VoiceInputView: View {
    @ObservedObject var viewModel: CreateChecklistViewModel

    var body: some View {
        VStack(spacing: 20) {
            // 説明
            VStack(spacing: 8) {
                Image(systemName: "waveform")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)

                Text("音声からチェックリストを作成")
                    .font(.headline)

                Text("話した内容をリアルタイムで\nテキストに変換します")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()

            // 録音ボタン
            VStack(spacing: 20) {
                Button {
                    if viewModel.speechRecognitionService.isRecording {
                        viewModel.speechRecognitionService.stopRecording()
                    } else {
                        viewModel.speechRecognitionService.startRecording()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(viewModel.speechRecognitionService.isRecording ? Color.red : Color.accentColor)
                            .frame(width: 80, height: 80)

                        Image(systemName: viewModel.speechRecognitionService.isRecording ? "stop.fill" : "mic.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                    }
                }

                Text(viewModel.speechRecognitionService.isRecording ? "タップして停止" : "タップして録音開始")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // 認識されたテキスト
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("認識されたテキスト")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    if !viewModel.speechRecognitionService.transcribedText.isEmpty {
                        Button("クリア") {
                            viewModel.speechRecognitionService.transcribedText = ""
                        }
                        .font(.caption)
                    }
                }

                Text(viewModel.speechRecognitionService.transcribedText.isEmpty
                    ? "音声を認識すると、ここに表示されます"
                    : viewModel.speechRecognitionService.transcribedText)
                    .font(.body)
                    .foregroundStyle(viewModel.speechRecognitionService.transcribedText.isEmpty ? .tertiary : .primary)
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // 変換ボタン
            if !viewModel.speechRecognitionService.transcribedText.isEmpty
                && !viewModel.speechRecognitionService.isRecording {
                Button {
                    Task {
                        await viewModel.processVoiceInput()
                    }
                } label: {
                    Label("チェックリストに変換", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isProcessing)
            }

            // エラー表示
            if let error = viewModel.speechRecognitionService.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding()
            }

            Spacer()
        }
    }
}

#Preview {
    VoiceInputView(viewModel: CreateChecklistViewModel())
}

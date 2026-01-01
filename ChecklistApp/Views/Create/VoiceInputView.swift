import SwiftUI

struct VoiceInputView: View {
    @ObservedObject var viewModel: CreateChecklistViewModel

    var body: some View {
        VStack(spacing: NeumorphicSpacing.lg) {
            // Header card
            headerCard

            // Recording button
            recordingButton

            // Transcribed text card
            transcribedTextCard

            // Convert button
            if !viewModel.speechRecognitionService.transcribedText.isEmpty
                && !viewModel.speechRecognitionService.isRecording {
                NeumorphicAccentButton(
                    title: "チェックリストに変換",
                    icon: "sparkles",
                    action: {
                        Task {
                            await viewModel.processVoiceInput()
                        }
                    },
                    isDisabled: viewModel.isProcessing
                )
            }

            // Error display
            if let error = viewModel.speechRecognitionService.errorMessage {
                errorCard(message: error)
            }
        }
    }

    private var headerCard: some View {
        HStack(spacing: NeumorphicSpacing.sm) {
            Image(systemName: "waveform")
                .font(.title3)
                .foregroundStyle(Color.accentOrangeStart)

            VStack(alignment: .leading, spacing: 2) {
                Text("音声から作成")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.neumorphicTextPrimary)

                Text("話した内容をリアルタイムでテキストに変換")
                    .font(.caption)
                    .foregroundStyle(Color.neumorphicTextTertiary)
            }

            Spacer()
        }
        .padding(.vertical, NeumorphicSpacing.xs)
    }

    private var recordingButton: some View {
        VStack(spacing: NeumorphicSpacing.md) {
            Button {
                if viewModel.speechRecognitionService.isRecording {
                    viewModel.speechRecognitionService.stopRecording()
                } else {
                    viewModel.speechRecognitionService.startRecording()
                }
            } label: {
                ZStack {
                    // Pulse effect when recording (behind other elements)
                    Circle()
                        .stroke(Color.statusError.opacity(0.3), lineWidth: 3)
                        .frame(width: 110, height: 110)
                        .scaleEffect(viewModel.speechRecognitionService.isRecording ? 1.2 : 1.0)
                        .opacity(viewModel.speechRecognitionService.isRecording ? 0 : 1)
                        .animation(
                            viewModel.speechRecognitionService.isRecording
                                ? .easeInOut(duration: 1.0).repeatForever(autoreverses: false)
                                : .default,
                            value: viewModel.speechRecognitionService.isRecording
                        )
                        .opacity(viewModel.speechRecognitionService.isRecording ? 1 : 0)

                    // Outer ring
                    Circle()
                        .fill(Color.neumorphicSurface)
                        .frame(width: 100, height: 100)
                        .neumorphicShadow()

                    // Inner button
                    Circle()
                        .fill(viewModel.speechRecognitionService.isRecording
                            ? AnyShapeStyle(Color.statusError)
                            : AnyShapeStyle(Color.orangeGradient))
                        .frame(width: 70, height: 70)

                    Image(systemName: viewModel.speechRecognitionService.isRecording ? "stop.fill" : "mic.fill")
                        .font(.title)
                        .foregroundStyle(.white)
                }
                .frame(width: 140, height: 140)
            }
            .buttonStyle(.plain)

            Text(viewModel.speechRecognitionService.isRecording ? "タップして停止" : "タップして録音開始")
                .font(.subheadline)
                .foregroundStyle(Color.neumorphicTextSecondary)
                .frame(height: 20)
        }
        .padding(.vertical, NeumorphicSpacing.md)
    }

    private var transcribedTextCard: some View {
        VStack(alignment: .leading, spacing: NeumorphicSpacing.sm) {
            HStack {
                Text("認識されたテキスト")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.neumorphicTextSecondary)

                Spacer()

                if !viewModel.speechRecognitionService.transcribedText.isEmpty {
                    Button {
                        viewModel.speechRecognitionService.transcribedText = ""
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                            Text("クリア")
                        }
                        .font(.caption)
                        .foregroundStyle(Color.neumorphicTextTertiary)
                    }
                }
            }

            Text(viewModel.speechRecognitionService.transcribedText.isEmpty
                ? "音声を認識すると、ここに表示されます"
                : viewModel.speechRecognitionService.transcribedText)
                .font(.body)
                .foregroundStyle(
                    viewModel.speechRecognitionService.transcribedText.isEmpty
                        ? Color.neumorphicTextTertiary
                        : Color.neumorphicTextPrimary
                )
                .padding(NeumorphicSpacing.md)
                .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
                .background(Color.neumorphicBackground)
                .clipShape(RoundedRectangle(cornerRadius: NeumorphicRadius.md))
                .shadow(
                    color: Color.neumorphicDarkShadow,
                    radius: 2,
                    x: 1,
                    y: 1
                )
                .shadow(
                    color: Color.neumorphicLightShadow,
                    radius: 2,
                    x: -1,
                    y: -1
                )
        }
        .padding(NeumorphicSpacing.md)
        .background(Color.neumorphicSurface)
        .clipShape(RoundedRectangle(cornerRadius: NeumorphicRadius.lg))
        .neumorphicShadow()
    }

    private func errorCard(message: String) -> some View {
        HStack(spacing: NeumorphicSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.statusError)

            Text(message)
                .font(.caption)
                .foregroundStyle(Color.statusError)
        }
        .padding(NeumorphicSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.statusError.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: NeumorphicRadius.md))
    }
}

#Preview {
    ZStack {
        Color.neumorphicBackground.ignoresSafeArea()
        ScrollView {
            VoiceInputView(viewModel: CreateChecklistViewModel())
                .padding()
        }
    }
}

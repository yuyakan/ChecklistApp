import Foundation
 import SwiftUI
import PhotosUI
import UIKit
 import Combine

enum CreateInputMode: String, CaseIterable {
    case photo
    case voice
    case text
    case aiGenerate

    var title: String {
        switch self {
        case .photo:
            return "写真"
        case .voice:
            return "音声"
        case .text:
            return "テキスト"
        case .aiGenerate:
            return "AI生成"
        }
    }

    var icon: String {
        switch self {
        case .photo:
            return "camera.fill"
        case .voice:
            return "mic.fill"
        case .text:
            return "text.alignleft"
        case .aiGenerate:
            return "sparkles"
        }
    }
}

@MainActor
class CreateChecklistViewModel: ObservableObject {
    @Published var selectedMode: CreateInputMode = .text
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var showingError = false

    // 写真入力
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var selectedImage: UIImage?
    @Published var showingImagePicker = false
    @Published var showingCamera = false

    // テキスト入力
    @Published var inputText = ""

    // AI生成
    @Published var conditionText = ""

    // 抽出/生成結果
    @Published var extractedText = ""
    @Published var generatedChecklist: Checklist?
    @Published var showingResult = false

    let aiService = ChecklistAIService()
    let textRecognitionService = TextRecognitionService()
    let speechRecognitionService = SpeechRecognitionService()

    private var cancellables = Set<AnyCancellable>()

    init() {
        // SpeechRecognitionServiceの変更をViewModelに伝播
        speechRecognitionService.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    // MARK: - 写真処理

    func processSelectedPhoto() async {
        guard let photoItem = selectedPhotoItem else { return }

        isProcessing = true
        errorMessage = nil

        do {
            guard let data = try await photoItem.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                throw TextRecognitionError.invalidImage
            }

            selectedImage = image
            let recognizedText = try await textRecognitionService.recognizeText(from: image)
            extractedText = recognizedText

            // AIでチェックリストに変換
            let extraction = try await aiService.extractChecklist(from: recognizedText, source: .photo)
            generatedChecklist = aiService.createChecklist(from: extraction, source: .photo)
            showingResult = true

        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }

        isProcessing = false
    }

    func processCapturedImage(_ image: UIImage) async {
        isProcessing = true
        errorMessage = nil

        do {
            selectedImage = image
            let recognizedText = try await textRecognitionService.recognizeText(from: image)
            extractedText = recognizedText

            // AIでチェックリストに変換
            let extraction = try await aiService.extractChecklist(from: recognizedText, source: .photo)
            generatedChecklist = aiService.createChecklist(from: extraction, source: .photo)
            showingResult = true

        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }

        isProcessing = false
    }

    // MARK: - 音声処理

    func processVoiceInput() async {
        guard !speechRecognitionService.transcribedText.isEmpty else {
            errorMessage = "音声が認識されませんでした"
            showingError = true
            return
        }

        isProcessing = true
        errorMessage = nil

        do {
            let recognizedText = speechRecognitionService.transcribedText
            extractedText = recognizedText

            // AIでチェックリストに変換
            let extraction = try await aiService.extractChecklist(from: recognizedText, source: .voice)
            generatedChecklist = aiService.createChecklist(from: extraction, source: .voice)
            showingResult = true

        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }

        isProcessing = false
    }

    // MARK: - テキスト処理

    func processTextInput() async {
        guard !inputText.isEmpty else {
            errorMessage = "テキストを入力してください"
            showingError = true
            return
        }

        isProcessing = true
        errorMessage = nil

        do {
            extractedText = inputText

            // AIでチェックリストに変換
            let extraction = try await aiService.extractChecklist(from: inputText, source: .text)
            generatedChecklist = aiService.createChecklist(from: extraction, source: .text)
            showingResult = true

        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }

        isProcessing = false
    }

    // MARK: - AI生成

    func generateChecklistFromCondition() async {
        guard !conditionText.isEmpty else {
            errorMessage = "条件を入力してください"
            showingError = true
            return
        }

        isProcessing = true
        errorMessage = nil

        do {
            let generation = try await aiService.generateChecklist(for: conditionText)
            generatedChecklist = aiService.createChecklist(from: generation)
            showingResult = true

        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }

        isProcessing = false
    }

    // MARK: - リセット

    func reset() {
        selectedPhotoItem = nil
        selectedImage = nil
        inputText = ""
        conditionText = ""
        extractedText = ""
        generatedChecklist = nil
        showingResult = false
        errorMessage = nil
        speechRecognitionService.transcribedText = ""
    }
}

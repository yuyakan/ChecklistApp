import Foundation
import Vision
import UIKit
 import Combine

enum TextRecognitionError: LocalizedError {
    case invalidImage
    case recognitionFailed(String)
    case noTextFound

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "画像を読み込めませんでした"
        case .recognitionFailed(let message):
            return "テキスト認識に失敗しました: \(message)"
        case .noTextFound:
            return "画像からテキストを検出できませんでした"
        }
    }
}

@MainActor
class TextRecognitionService: ObservableObject {
    @Published var isProcessing = false
    @Published var recognizedText = ""
    @Published var errorMessage: String?

    func recognizeText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw TextRecognitionError.invalidImage
        }

        isProcessing = true
        defer { isProcessing = false }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: TextRecognitionError.recognitionFailed(error.localizedDescription))
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: TextRecognitionError.noTextFound)
                    return
                }

                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }

                if recognizedStrings.isEmpty {
                    continuation.resume(throwing: TextRecognitionError.noTextFound)
                    return
                }

                let text = recognizedStrings.joined(separator: "\n")
                continuation.resume(returning: text)
            }

            // 日本語と英語の認識に対応
            request.recognitionLanguages = ["ja-JP", "en-US"]
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: TextRecognitionError.recognitionFailed(error.localizedDescription))
            }
        }
    }

    func processImage(_ image: UIImage) async {
        errorMessage = nil
        do {
            recognizedText = try await recognizeText(from: image)
        } catch {
            errorMessage = error.localizedDescription
            recognizedText = ""
        }
    }
}

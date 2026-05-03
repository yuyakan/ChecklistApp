import Foundation
import Speech
import AVFoundation
import Combine

class SpeechRecognitionService: ObservableObject {
    @Published var transcribedText = ""
    @Published var isRecording = false
    @Published var errorMessage: String?

    private var speechRecognizer: SFSpeechRecognizer? {
        SFSpeechRecognizer(locale: Locale(identifier: AppLanguage.current.speechLocaleIdentifier))
    }
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var accumulatedText = ""

    init() {
        // 権限リクエストは録音開始時に行う
    }

    private func requestPermissionsAndStartRecording() {
        let speechStatus = SFSpeechRecognizer.authorizationStatus()

        switch speechStatus {
        case .notDetermined:
            // 音声認識の権限をリクエスト
            SFSpeechRecognizer.requestAuthorization { [weak self] status in
                DispatchQueue.main.async {
                    if status == .authorized {
                        self?.requestMicrophoneAndStartRecording()
                    } else {
                        self?.errorMessage = L10n.tr("音声認識の権限が必要です。設定アプリ > プライバシーとセキュリティ > 音声認識 で許可してください。")
                    }
                }
            }
        case .authorized:
            requestMicrophoneAndStartRecording()
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.errorMessage = L10n.tr("音声認識の権限がありません。設定アプリ > プライバシーとセキュリティ > 音声認識 で許可してください。")
            }
        @unknown default:
            break
        }
    }

    private func requestMicrophoneAndStartRecording() {
        let audioSession = AVAudioSession.sharedInstance()

        switch audioSession.recordPermission {
        case .undetermined:
            audioSession.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.beginRecording()
                    } else {
                        self?.errorMessage = L10n.tr("マイクの権限が必要です。設定アプリ > プライバシーとセキュリティ > マイク で許可してください。")
                    }
                }
            }
        case .granted:
            beginRecording()
        case .denied:
            DispatchQueue.main.async {
                self.errorMessage = L10n.tr("マイクの権限がありません。設定アプリ > プライバシーとセキュリティ > マイク で許可してください。")
            }
        @unknown default:
            break
        }
    }

    func startRecording() {
        // 既に録音中なら何もしない
        guard !isRecording else { return }

        // 権限確認とリクエスト
        requestPermissionsAndStartRecording()
    }

    private func beginRecording() {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            DispatchQueue.main.async {
                self.errorMessage = L10n.tr("音声認識が利用できません")
            }
            return
        }

        // 初期化
        accumulatedText = ""

        DispatchQueue.main.async {
            self.isRecording = true
            self.transcribedText = ""
            self.errorMessage = nil
        }

        startRecognitionSession()
    }

    private func startRecognitionSession() {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else { return }

        // 既存のタスクをクリーンアップ
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil

        do {
            // オーディオセッション設定
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            // リクエスト作成
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            self.recognitionRequest = request

            // 入力ノード設定（既にタップがあれば削除）
            let inputNode = audioEngine.inputNode
            inputNode.removeTap(onBus: 0)

            let recordingFormat = inputNode.outputFormat(forBus: 0)

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                request.append(buffer)
            }

            // エンジン開始
            if !audioEngine.isRunning {
                audioEngine.prepare()
                try audioEngine.start()
            }

            // 認識タスク開始
            recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
                guard let self = self else { return }

                DispatchQueue.main.async {
                    // 録音停止後のコールバックは無視
                    guard self.isRecording else { return }

                    if let result = result {
                        // 累積テキストと現在の認識結果を組み合わせる
                        let currentText = result.bestTranscription.formattedString
                        if self.accumulatedText.isEmpty {
                            self.transcribedText = currentText
                        } else {
                            self.transcribedText = self.accumulatedText + " " + currentText
                        }

                        // 認識が最終結果になった場合、累積して再開
                        if result.isFinal {
                            self.accumulatedText = self.transcribedText
                            self.restartRecognitionSession()
                        }
                    }

                    // エラーがあれば再開を試みる
                    if error != nil {
                        self.restartRecognitionSession()
                    }
                }
            }

        } catch {
            DispatchQueue.main.async {
                self.errorMessage = UserErrorMessageResolver.message(for: error, context: .speechRecognition)
                self.isRecording = false
            }
        }
    }

    private func restartRecognitionSession() {
        // 現在のリクエストを終了
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil

        // 少し遅延して再開
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self, self.isRecording else { return }
            self.startRecognitionSession()
        }
    }

    func stopRecording() {
        // 先にisRecordingをfalseに設定（コールバックでのテキスト上書きを防ぐ）
        isRecording = false

        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        recognitionTask?.cancel()
        recognitionTask = nil
    }
}

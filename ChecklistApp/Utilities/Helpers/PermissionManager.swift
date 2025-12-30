import Foundation
import AVFoundation
import Photos
import Speech
import UIKit
 import Combine

enum PermissionStatus {
    case notDetermined
    case authorized
    case denied
    case restricted
}

@MainActor
class PermissionManager: ObservableObject {
    @Published var cameraStatus: PermissionStatus = .notDetermined
    @Published var microphoneStatus: PermissionStatus = .notDetermined
    @Published var photoLibraryStatus: PermissionStatus = .notDetermined
    @Published var speechRecognitionStatus: PermissionStatus = .notDetermined

    init() {
        checkAllPermissions()
    }

    func checkAllPermissions() {
        checkCameraPermission()
        checkMicrophonePermission()
        checkPhotoLibraryPermission()
        checkSpeechRecognitionPermission()
    }

    // MARK: - Camera

    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            cameraStatus = .notDetermined
        case .authorized:
            cameraStatus = .authorized
        case .denied:
            cameraStatus = .denied
        case .restricted:
            cameraStatus = .restricted
        @unknown default:
            cameraStatus = .denied
        }
    }

    func requestCameraPermission() async -> Bool {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        cameraStatus = granted ? .authorized : .denied
        return granted
    }

    // MARK: - Microphone

    func checkMicrophonePermission() {
        switch AVAudioApplication.shared.recordPermission {
        case .undetermined:
            microphoneStatus = .notDetermined
        case .granted:
            microphoneStatus = .authorized
        case .denied:
            microphoneStatus = .denied
        @unknown default:
            microphoneStatus = .denied
        }
    }

    func requestMicrophonePermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                Task { @MainActor in
                    self.microphoneStatus = granted ? .authorized : .denied
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    // MARK: - Photo Library

    func checkPhotoLibraryPermission() {
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .notDetermined:
            photoLibraryStatus = .notDetermined
        case .authorized, .limited:
            photoLibraryStatus = .authorized
        case .denied:
            photoLibraryStatus = .denied
        case .restricted:
            photoLibraryStatus = .restricted
        @unknown default:
            photoLibraryStatus = .denied
        }
    }

    func requestPhotoLibraryPermission() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        switch status {
        case .authorized, .limited:
            photoLibraryStatus = .authorized
            return true
        default:
            photoLibraryStatus = .denied
            return false
        }
    }

    // MARK: - Speech Recognition

    func checkSpeechRecognitionPermission() {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .notDetermined:
            speechRecognitionStatus = .notDetermined
        case .authorized:
            speechRecognitionStatus = .authorized
        case .denied:
            speechRecognitionStatus = .denied
        case .restricted:
            speechRecognitionStatus = .restricted
        @unknown default:
            speechRecognitionStatus = .denied
        }
    }

    func requestSpeechRecognitionPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                Task { @MainActor in
                    self.speechRecognitionStatus = status == .authorized ? .authorized : .denied
                    continuation.resume(returning: status == .authorized)
                }
            }
        }
    }

    // MARK: - Helper

    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

 import SwiftUI
import PhotosUI
import UIKit

struct PhotoInputView: View {
    @ObservedObject var viewModel: CreateChecklistViewModel
    @State private var showingSourcePicker = false

    var body: some View {
        VStack(spacing: 20) {
            // 説明
            VStack(spacing: 8) {
                Image(systemName: "camera.viewfinder")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)

                Text("写真からチェックリストを作成")
                    .font(.headline)

                Text("レシピ、買い物メモ、手書きリストなどの\n写真からテキストを読み取ります")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()

            // 選択した画像の表示
            if let image = viewModel.selectedImage {
                VStack(spacing: 12) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 2)

                    Button("画像を変更") {
                        showingSourcePicker = true
                    }
                    .font(.subheadline)
                }
            } else {
                // 画像選択ボタン
                Button {
                    showingSourcePicker = true
                } label: {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 40))

                        Text("写真を選択")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            // 抽出されたテキストの表示
            if !viewModel.extractedText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("認識されたテキスト")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(viewModel.extractedText)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            Spacer()
        }
        .confirmationDialog("画像の取得方法", isPresented: $showingSourcePicker) {
            Button("カメラで撮影") {
                viewModel.showingCamera = true
            }

            Button("フォトライブラリから選択") {
                viewModel.showingImagePicker = true
            }
        }
        .photosPicker(
            isPresented: $viewModel.showingImagePicker,
            selection: $viewModel.selectedPhotoItem,
            matching: .images
        )
        .fullScreenCover(isPresented: $viewModel.showingCamera) {
            CameraView { image in
                Task {
                    await viewModel.processCapturedImage(image)
                }
            }
            .ignoresSafeArea()
        }
        .onChange(of: viewModel.selectedPhotoItem) { _, newValue in
            if newValue != nil {
                Task {
                    await viewModel.processSelectedPhoto()
                }
            }
        }
    }
}

// MARK: - Camera View

struct CameraView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.mediaTypes = ["public.image"]
        picker.showsCameraControls = false
        picker.delegate = context.coordinator

        // カメラビューを画面全体に拡大し、位置を調整
        let screenBounds = UIScreen.main.bounds
        let cameraAspectRatio: CGFloat = 4.0 / 3.0
        let cameraHeight = screenBounds.width * cameraAspectRatio
        let scale = screenBounds.height / cameraHeight
        // カメラビューを中央から下に移動して黒いバーを隠す
        let offsetY = (screenBounds.height - cameraHeight) / 2
        picker.cameraViewTransform = CGAffineTransform(translationX: 0, y: offsetY)
            .scaledBy(x: scale, y: scale)

        // カスタムオーバーレイを作成
        let overlayView = CameraOverlayView(frame: screenBounds)
        overlayView.onCapture = { picker.takePicture() }
        overlayView.onCancel = { context.coordinator.parent.dismiss() }
        overlayView.onFlashToggle = {
            switch picker.cameraFlashMode {
            case .auto: picker.cameraFlashMode = .on
            case .on: picker.cameraFlashMode = .off
            case .off: picker.cameraFlashMode = .auto
            @unknown default: picker.cameraFlashMode = .auto
            }
            return picker.cameraFlashMode
        }
        picker.cameraOverlayView = overlayView

        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onCapture(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Camera Overlay View

class CameraOverlayView: UIView {
    var onCapture: (() -> Void)?
    var onCancel: (() -> Void)?
    var onFlashToggle: (() -> UIImagePickerController.CameraFlashMode)?

    // 上部コントロールバー
    private let topBar: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .dark)
        let view = UIVisualEffectView(effect: blur)
        return view
    }()

    // 下部コントロールバー
    private let bottomBar: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .dark)
        let view = UIVisualEffectView(effect: blur)
        return view
    }()

    // 撮影ボタン（外側リング）
    private let captureButtonOuter: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 4
        view.layer.cornerRadius = 35
        return view
    }()

    // 撮影ボタン（内側）
    private let captureButtonInner: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .white
        button.layer.cornerRadius = 28
        return button
    }()

    // キャンセルボタン
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        button.tintColor = .white
        return button
    }()

    // フラッシュボタン
    private let flashButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        button.setImage(UIImage(systemName: "bolt.badge.automatic.fill", withConfiguration: config), for: .normal)
        button.tintColor = .yellow
        return button
    }()

    // フラッシュラベル
    private let flashLabel: UILabel = {
        let label = UILabel()
        label.text = "自動"
        label.font = .systemFont(ofSize: 12)
        label.textColor = .white
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .clear

        // 上部バー
        addSubview(topBar)
        topBar.translatesAutoresizingMaskIntoConstraints = false

        // 下部バー
        addSubview(bottomBar)
        bottomBar.translatesAutoresizingMaskIntoConstraints = false

        // フラッシュボタン
        let flashStack = UIStackView(arrangedSubviews: [flashButton, flashLabel])
        flashStack.axis = .vertical
        flashStack.alignment = .center
        flashStack.spacing = 2
        topBar.contentView.addSubview(flashStack)
        flashStack.translatesAutoresizingMaskIntoConstraints = false

        // 撮影ボタン
        bottomBar.contentView.addSubview(captureButtonOuter)
        captureButtonOuter.addSubview(captureButtonInner)
        captureButtonOuter.translatesAutoresizingMaskIntoConstraints = false
        captureButtonInner.translatesAutoresizingMaskIntoConstraints = false

        // キャンセルボタン
        bottomBar.contentView.addSubview(cancelButton)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // 上部バー
            topBar.topAnchor.constraint(equalTo: topAnchor),
            topBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            topBar.heightAnchor.constraint(equalToConstant: 100),

            // フラッシュ（右端に配置）
            flashStack.trailingAnchor.constraint(equalTo: topBar.trailingAnchor, constant: -20),
            flashStack.bottomAnchor.constraint(equalTo: topBar.bottomAnchor, constant: -12),

            // 下部バー
            bottomBar.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 140),

            // 撮影ボタン外側
            captureButtonOuter.centerXAnchor.constraint(equalTo: bottomBar.centerXAnchor),
            captureButtonOuter.centerYAnchor.constraint(equalTo: bottomBar.contentView.centerYAnchor),
            captureButtonOuter.widthAnchor.constraint(equalToConstant: 70),
            captureButtonOuter.heightAnchor.constraint(equalToConstant: 70),

            // 撮影ボタン内側
            captureButtonInner.centerXAnchor.constraint(equalTo: captureButtonOuter.centerXAnchor),
            captureButtonInner.centerYAnchor.constraint(equalTo: captureButtonOuter.centerYAnchor),
            captureButtonInner.widthAnchor.constraint(equalToConstant: 56),
            captureButtonInner.heightAnchor.constraint(equalToConstant: 56),

            // キャンセルボタン
            cancelButton.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 24),
            cancelButton.centerYAnchor.constraint(equalTo: captureButtonOuter.centerYAnchor)
        ])

        // アクション設定
        captureButtonInner.addTarget(self, action: #selector(capturePressed), for: .touchUpInside)
        captureButtonInner.addTarget(self, action: #selector(captureButtonDown), for: .touchDown)
        captureButtonInner.addTarget(self, action: #selector(captureButtonUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        cancelButton.addTarget(self, action: #selector(cancelPressed), for: .touchUpInside)
        flashButton.addTarget(self, action: #selector(flashPressed), for: .touchUpInside)
    }

    @objc private func capturePressed() {
        onCapture?()
    }

    @objc private func captureButtonDown() {
        UIView.animate(withDuration: 0.1) {
            self.captureButtonInner.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            self.captureButtonInner.backgroundColor = UIColor(white: 0.8, alpha: 1)
        }
    }

    @objc private func captureButtonUp() {
        UIView.animate(withDuration: 0.1) {
            self.captureButtonInner.transform = .identity
            self.captureButtonInner.backgroundColor = .white
        }
    }

    @objc private func cancelPressed() {
        onCancel?()
    }

    @objc private func flashPressed() {
        guard let mode = onFlashToggle?() else { return }

        let imageName: String
        let labelText: String
        let tintColor: UIColor

        switch mode {
        case .auto:
            imageName = "bolt.badge.automatic.fill"
            labelText = "自動"
            tintColor = .yellow
        case .on:
            imageName = "bolt.fill"
            labelText = "オン"
            tintColor = .yellow
        case .off:
            imageName = "bolt.slash.fill"
            labelText = "オフ"
            tintColor = .white
        @unknown default:
            imageName = "bolt.badge.automatic.fill"
            labelText = "自動"
            tintColor = .yellow
        }

        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        flashButton.setImage(UIImage(systemName: imageName, withConfiguration: config), for: .normal)
        flashButton.tintColor = tintColor
        flashLabel.text = labelText
    }
}

#Preview {
    PhotoInputView(viewModel: CreateChecklistViewModel())
}

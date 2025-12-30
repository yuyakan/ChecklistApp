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
        picker.delegate = context.coordinator
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

#Preview {
    PhotoInputView(viewModel: CreateChecklistViewModel())
}

import SwiftUI
import SwiftData
import CloudKit

struct ShareLinkView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let checklist: Checklist
    let share: CKShare

    @State private var isCopied = false
    @State private var showingShareSheet = false

    private var shareURL: URL? {
        share.url
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.neumorphicBackground.ignoresSafeArea()

                VStack(spacing: NeumorphicSpacing.lg) {
                    // アイコン
                    ZStack {
                        Circle()
                            .fill(Color.neumorphicSurface)
                            .frame(width: 100, height: 100)
                            .neumorphicShadow()

                        Image(systemName: "link.circle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(Color.orangeGradient)
                    }

                    // タイトル
                    Text("共有リンクを作成しました")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.neumorphicTextPrimary)

                    // チェックリスト名
                    Text(checklist.title)
                        .font(.headline)
                        .foregroundStyle(Color.neumorphicTextSecondary)
                        .padding(.horizontal, NeumorphicSpacing.md)
                        .padding(.vertical, NeumorphicSpacing.sm)
                        .background(Color.neumorphicSurface)
                        .clipShape(RoundedRectangle(cornerRadius: NeumorphicRadius.sm))

                    // URL表示
                    if let url = shareURL {
                        VStack(spacing: NeumorphicSpacing.sm) {
                            Text(url.absoluteString)
                                .font(.caption)
                                .foregroundStyle(Color.neumorphicTextTertiary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .padding(.horizontal, NeumorphicSpacing.md)
                        }
                    }

                    Spacer()

                    // ボタン
                    VStack(spacing: NeumorphicSpacing.md) {
                        // 共有ボタン
                        Button {
                            showingShareSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("リンクを共有")
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, NeumorphicSpacing.md)
                            .background(Color.orangeGradient)
                            .clipShape(RoundedRectangle(cornerRadius: NeumorphicRadius.md))
                        }

                        // コピーボタン
                        Button {
                            if let url = shareURL {
                                UIPasteboard.general.url = url
                                withAnimation {
                                    isCopied = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation {
                                        isCopied = false
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                Text(isCopied ? "コピーしました" : "リンクをコピー")
                            }
                            .font(.headline)
                            .foregroundStyle(Color.neumorphicTextPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, NeumorphicSpacing.md)
                            .background(Color.neumorphicSurface)
                            .clipShape(RoundedRectangle(cornerRadius: NeumorphicRadius.md))
                            .neumorphicShadow()
                        }

                        // 共有停止ボタン
                        Button(role: .destructive) {
                            Task {
                                await stopSharing()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "xmark.circle")
                                Text("共有を停止")
                            }
                            .font(.subheadline)
                            .foregroundStyle(Color.statusError)
                        }
                        .padding(.top, NeumorphicSpacing.sm)
                    }
                    .padding(.horizontal, NeumorphicSpacing.lg)
                    .padding(.bottom, NeumorphicSpacing.xl)
                }
                .padding(.top, NeumorphicSpacing.xl)
            }
            .navigationTitle("共有")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                    .foregroundStyle(Color.accentOrangeStart)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = shareURL {
                    ShareSheet(url: url, title: "「\(checklist.title)」を共有")
                }
            }
        }
    }

    private func stopSharing() async {
        do {
            try await CloudKitSharingService.shared.deleteSharedRecords(for: checklist)
            checklist.isShared = false
            try? modelContext.save()
            dismiss()
        } catch {
            print("共有停止エラー: \(error)")
        }
    }
}

// MARK: - Share Sheet for URL

struct ShareSheet: UIViewControllerRepresentable {
    var url: URL? = nil
    var text: String? = nil
    var title: String? = nil

    init(url: URL, title: String? = nil) {
        self.url = url
        self.title = title
    }

    init(text: String) {
        self.text = text
    }

    func makeUIViewController(context: Context) -> UIActivityViewController {
        var activityItems: [Any] = []

        if let url = url {
            activityItems.append(url)
        }
        if let text = text {
            activityItems.append(text)
        }

        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )

        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    let checklist = Checklist(title: "テストリスト", category: .shopping)
    // プレビュー用のダミーCKShareは作成できないため、実際のプレビューは困難
    Text("プレビューはダミーデータでは表示できません")
}

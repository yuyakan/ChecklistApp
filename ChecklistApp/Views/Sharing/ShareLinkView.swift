import SwiftUI

// MARK: - Share Sheet

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


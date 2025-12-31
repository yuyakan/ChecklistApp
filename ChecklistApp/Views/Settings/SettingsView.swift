 import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("defaultCategory") private var defaultCategory: String = Category.other.rawValue
    @AppStorage("appearanceMode") private var appearanceMode: String = "system"

    var body: some View {
        Form {
            // 外観設定
            Section {
                Picker("テーマ", selection: $appearanceMode) {
                    Text("システム設定に従う").tag("system")
                    Text("ライト").tag("light")
                    Text("ダーク").tag("dark")
                }
            } header: {
                Text("外観")
                    .padding(.top, 8)
            } footer: {
                Text("アプリの外観モードを設定します")
            }

            // デフォルト設定
            Section {
                Picker("デフォルトカテゴリ", selection: $defaultCategory) {
                    ForEach(Category.allCases, id: \.self) { category in
                        Label(category.description, systemImage: category.icon)
                            .tag(category.rawValue)
                    }
                }
            } header: {
                Text("デフォルト設定")
            } footer: {
                Text("新規チェックリスト作成時のデフォルトカテゴリを設定します")
            }
        }
    }
}

// MARK: - App Theme Modifier

struct AppThemeModifier: ViewModifier {
    @AppStorage("appearanceMode") private var appearanceMode: String = "system"

    func body(content: Content) -> some View {
        content
            .preferredColorScheme(colorScheme)
    }

    private var colorScheme: ColorScheme? {
        switch appearanceMode {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil
        }
    }
}

extension View {
    func applyAppTheme() -> some View {
        modifier(AppThemeModifier())
    }
}

#Preview {
    SettingsView()
}

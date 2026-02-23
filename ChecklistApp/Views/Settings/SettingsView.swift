import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("defaultCategory") private var defaultCategory: String = Category.other.rawValue
    @AppStorage("appearanceMode") private var appearanceMode: String = "system"

    var body: some View {
        NavigationStack {
            ZStack {
                Color.neumorphicBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: NeumorphicSpacing.md) {
                        // CloudKit Sharing section
                        cloudKitCard

                        // Appearance section
                        appearanceCard

                        // Default settings section
                        defaultSettingsCard
                    }
                    .padding(NeumorphicSpacing.md)
                }
            }
            .navigationTitle("設定")
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
        }
    }

    private var cloudKitCard: some View {
        VStack(alignment: .leading, spacing: NeumorphicSpacing.md) {
            Label("iCloud共有", systemImage: "icloud.fill")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.neumorphicTextPrimary)

            NavigationLink {
                SharedChecklistsView()
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: NeumorphicSpacing.xxs) {
                        Text("共有されたリスト")
                            .font(.subheadline)
                            .foregroundStyle(Color.neumorphicTextPrimary)
                        Text("他のユーザーから共有されたチェックリストを表示")
                            .font(.caption)
                            .foregroundStyle(Color.neumorphicTextTertiary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .foregroundStyle(Color.neumorphicTextTertiary)
                }
                .padding(.vertical, NeumorphicSpacing.xs)
            }
            .buttonStyle(.plain)

            Text("チェックリストを他のiCloudユーザーと共有できます。詳細画面のメニューから「iCloudで共有」を選択してください。")
                .font(.caption)
                .foregroundStyle(Color.neumorphicTextTertiary)
        }
        .padding(NeumorphicSpacing.md)
        .background(Color.neumorphicSurface)
        .clipShape(RoundedRectangle(cornerRadius: NeumorphicRadius.lg))
        .neumorphicShadow()
    }

    private var appearanceCard: some View {
        VStack(alignment: .leading, spacing: NeumorphicSpacing.md) {
            Label("外観", systemImage: "paintbrush.fill")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.neumorphicTextPrimary)

            VStack(alignment: .leading, spacing: NeumorphicSpacing.xs) {
                Text("テーマ")
                    .font(.caption)
                    .foregroundStyle(Color.neumorphicTextTertiary)

                HStack(spacing: NeumorphicSpacing.sm) {
                    ThemeOptionButton(
                        title: "自動",
                        icon: "gearshape",
                        isSelected: appearanceMode == "system"
                    ) {
                        appearanceMode = "system"
                    }

                    ThemeOptionButton(
                        title: "ライト",
                        icon: "sun.max.fill",
                        isSelected: appearanceMode == "light"
                    ) {
                        appearanceMode = "light"
                    }

                    ThemeOptionButton(
                        title: "ダーク",
                        icon: "moon.fill",
                        isSelected: appearanceMode == "dark"
                    ) {
                        appearanceMode = "dark"
                    }
                }
            }

            Text("アプリの外観モードを設定します")
                .font(.caption)
                .foregroundStyle(Color.neumorphicTextTertiary)
        }
        .padding(NeumorphicSpacing.md)
        .background(Color.neumorphicSurface)
        .clipShape(RoundedRectangle(cornerRadius: NeumorphicRadius.lg))
        .neumorphicShadow()
    }

    private var defaultSettingsCard: some View {
        VStack(alignment: .leading, spacing: NeumorphicSpacing.md) {
            Label("デフォルト設定", systemImage: "slider.horizontal.3")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.neumorphicTextPrimary)

            VStack(alignment: .leading, spacing: NeumorphicSpacing.xs) {
                Text("デフォルトカテゴリ")
                    .font(.caption)
                    .foregroundStyle(Color.neumorphicTextTertiary)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: NeumorphicSpacing.xs) {
                    ForEach(Category.allCases, id: \.self) { category in
                        DefaultCategoryButton(
                            category: category,
                            isSelected: defaultCategory == category.rawValue
                        ) {
                            defaultCategory = category.rawValue
                        }
                    }
                }
            }

            Text("新規チェックリスト作成時のデフォルトカテゴリを設定します")
                .font(.caption)
                .foregroundStyle(Color.neumorphicTextTertiary)
        }
        .padding(NeumorphicSpacing.md)
        .background(Color.neumorphicSurface)
        .clipShape(RoundedRectangle(cornerRadius: NeumorphicRadius.lg))
        .neumorphicShadow()
    }

}

struct ThemeOptionButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.caption)
                    .fontWeight(isSelected ? .medium : .regular)
            }
            .foregroundStyle(isSelected ? .white : Color.neumorphicTextSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, NeumorphicSpacing.sm)
            .background(themeBackground)
            .clipShape(RoundedRectangle(cornerRadius: NeumorphicRadius.sm))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var themeBackground: some View {
        if isSelected {
            Color.orangeGradient
        } else {
            Color.neumorphicBackground
        }
    }
}

struct DefaultCategoryButton: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: category.icon)
                    .font(.subheadline)
                Text(category.description)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? .white : Color.neumorphicTextSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, NeumorphicSpacing.sm)
            .background(categoryBackground)
            .clipShape(RoundedRectangle(cornerRadius: NeumorphicRadius.sm))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var categoryBackground: some View {
        if isSelected {
            Color.orangeGradient
        } else {
            Color.neumorphicBackground
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

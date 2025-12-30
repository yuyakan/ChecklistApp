# チェックリスト自動作成アプリ (ChecklistApp)

iOS 18以降対応のチェックリスト自動作成アプリです。写真、音声、テキスト入力からチェックリストを自動生成し、さらにAIによる条件ベースのチェックリスト作成が可能です。

## 機能

### 1. マルチモーダル入力からのチェックリスト変換

#### 写真入力
- カメラ撮影またはフォトライブラリから画像を選択
- Vision frameworkのテキスト認識で画像内のテキストを抽出
- 抽出したテキストをFoundation Modelsで解析し、チェックリスト項目に変換
- 使用例：料理レシピの材料写真 → 材料のチェックリスト

#### 音声入力
- Speech frameworkを使用したリアルタイム音声認識
- 認識したテキストをFoundation Modelsで解析
- 自然な話し言葉からチェックリスト項目を抽出

#### テキスト入力
- 自由形式のテキスト入力フィールド
- 箇条書き・段落・カンマ区切りなど様々な形式に対応
- Foundation Modelsで入力意図を解析し、適切なチェックリスト項目に変換

### 2. AI条件ベースのチェックリスト生成

テキスト入力フィールドで条件を入力すると、Foundation Modelsがコンテキストを理解し、適切なチェックリストを生成します。

**生成例：**
- 「カレーの材料」→ 玉ねぎ、にんじん、じゃがいも、豚肉、カレールー...
- 「引っ越しで必要な手続き」→ 転出届、転入届、電気・ガス・水道の手続き...
- 「キャンプの持ち物」→ テント、寝袋、ランタン、クーラーボックス...

### 3. チェックリスト管理

- チェックリスト一覧表示（カテゴリフィルタ、検索機能付き）
- 項目のチェック/未チェック切り替え
- 項目の追加・編集・削除・並び替え
- 進捗表示（プログレスバー）
- 共有機能

### 4. ウィジェット

ホーム画面に進行中のチェックリストの進捗を表示するウィジェットを追加できます。

## 技術スタック

- **言語**: Swift
- **最小対応OS**: iOS 18以降（AI機能はiOS 26以降）
- **UI**: SwiftUI
- **アーキテクチャ**: MVVM
- **データ永続化**: SwiftData
- **AI機能**: Swift Foundation Models (@Generable等) ※iOS 26以降のみ
- **画像認識**: Vision framework (VNRecognizeTextRequest)
- **音声認識**: Speech framework

## プロジェクト構成

```
Checklist/
├── Checklist.xcodeproj
├── ChecklistApp/
│   ├── App/
│   │   ├── ChecklistApp.swift          # アプリエントリーポイント
│   │   └── ContentView.swift           # ルートビュー
│   ├── Models/
│   │   ├── Checklist.swift             # チェックリストモデル
│   │   ├── ChecklistItem.swift         # チェックリスト項目モデル
│   │   ├── InputSource.swift           # 入力ソース・カテゴリ・優先度の定義
│   │   └── AIModels.swift              # AI生成用の構造体
│   ├── ViewModels/
│   │   ├── HomeViewModel.swift         # ホーム画面のViewModel
│   │   ├── CreateChecklistViewModel.swift  # 作成画面のViewModel
│   │   └── ChecklistDetailViewModel.swift  # 詳細画面のViewModel
│   ├── Views/
│   │   ├── Home/
│   │   │   ├── HomeView.swift          # ホーム画面
│   │   │   └── ChecklistRowView.swift  # リスト行ビュー
│   │   ├── Create/
│   │   │   ├── CreateChecklistView.swift   # 新規作成画面
│   │   │   ├── PhotoInputView.swift        # 写真入力
│   │   │   ├── VoiceInputView.swift        # 音声入力
│   │   │   ├── TextInputView.swift         # テキスト入力
│   │   │   ├── AIGenerateView.swift        # AI生成
│   │   │   └── ChecklistPreviewView.swift  # プレビュー画面
│   │   ├── Detail/
│   │   │   ├── ChecklistDetailView.swift   # 詳細画面
│   │   │   └── ChecklistItemRowView.swift  # 項目行ビュー
│   │   └── Settings/
│   │       └── SettingsView.swift      # 設定画面
│   ├── Services/
│   │   ├── ChecklistAIService.swift    # AI処理サービス
│   │   ├── TextRecognitionService.swift    # テキスト認識サービス
│   │   └── SpeechRecognitionService.swift  # 音声認識サービス
│   ├── Utilities/
│   │   ├── Extensions/
│   │   │   ├── Color+Extensions.swift
│   │   │   └── Date+Extensions.swift
│   │   └── Helpers/
│   │       └── PermissionManager.swift # 権限管理
│   └── Resources/
│       └── Assets.xcassets
├── ChecklistWidget/                    # ウィジェット拡張
│   └── ChecklistWidget.swift
└── README.md
```

## セットアップ

### 必要な環境
- Xcode 16以降
- iOS 18以降のシミュレーターまたは実機
- AI機能を使用する場合はiOS 26 beta以降が必要

### ビルド手順

1. `Checklist.xcodeproj` をXcodeで開く
2. ターゲットを「Checklist」に設定
3. ターゲットデバイスを選択（iOS 18以降）
4. **重要**: プロジェクト設定 > Info タブで以下の権限を追加:
   - `Privacy - Camera Usage Description`: 写真からチェックリストを作成するためにカメラを使用します
   - `Privacy - Microphone Usage Description`: 音声からチェックリストを作成するためにマイクを使用します
   - `Privacy - Speech Recognition Usage Description`: 音声をテキストに変換してチェックリストを作成するために音声認識を使用します
   - `Privacy - Photo Library Usage Description`: 写真からチェックリストを作成するためにフォトライブラリにアクセスします
5. Cmd + R でビルド・実行

### ウィジェットのセットアップ（既にターゲットがある場合）

ウィジェットターゲット (ChecklistWidget) のDeployment Targetを iOS 18 以降に設定してください。

## 注意事項

- **Foundation Models（AI機能）は iOS 26 以降でのみ利用可能です**
  - iOS 26未満のデバイスでは、AI機能は「利用不可」と表示されます
  - コードは条件付きコンパイル (`#if canImport(FoundationModels)`) で対応済み
- テキスト認識（Vision）と音声認識（Speech）は iOS 18 以降で利用可能です
- 音声認識はインターネット接続が必要な場合があります

## トラブルシューティング

### 「Multiple commands produce Info.plist」エラー

Xcodeプロジェクトに手動で Info.plist ファイルが含まれている場合に発生します。

**解決方法:**
1. ChecklistApp フォルダ内の `Info.plist` ファイルがあれば削除
2. プロジェクト設定 > Build Settings > Packaging > Info.plist File が空か確認
3. 権限設定は Info タブの Custom iOS Target Properties で追加

### その他のビルドエラー

1. Derived Data をクリア:
   - Xcode > Settings > Locations > Derived Data フォルダを開いて削除
2. Clean Build Folder: Cmd + Shift + K
3. 再度ビルド: Cmd + B

## ライセンス

MIT License

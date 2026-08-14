# Pixel Terrarium 開発規約

## モジュール境界

- `TerrariumCore` は Foundation だけに依存させる。
- `PixelTerrariumApp` が SwiftData と RealityKit を所有する。
- `PixelTerrariumWidget` から SwiftData を直接開かず、App Group の JSON スナップショットだけを読む。
- `Assets/Generated` の生成物は直接編集せず、`Scripts/Blender/generate_terrarium.py` から再生成する。

## 検証

- プロジェクト生成: `tuist generate --no-open`
- 単体テスト: `xcodebuild test -workspace PixelTerrarium.xcworkspace -scheme PixelTerrarium -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
- Lint: `swiftlint lint --strict`
- 素材検査: `Scripts/verify_assets.sh`

## Pull Requests

- PR のタイトルと本文は日本語で書く。
- PR のタイトルに `codex` を含めない。

# Pixel Terrarium

毎日少しずつ育つテラリウムを、アプリとホーム画面ウィジェットで眺める iOS 26 アプリです。

テラリウムごとに保存したシードから、苔、シダ、石、朽木、水滴の配置を決定的に生成します。
同じシードと育成状態からは同じ景色を再現するため、再起動やWidget更新で配置が変わりません。

## 必要環境

- Xcode 26.6 / Swift 6.3.3
- iOS 26.5 Simulator
- Tuist 4.202.8
- SwiftLint 0.65.0
- xcbeautify 3.2.1
- Blender 5.2.0 LTS

## プロジェクト生成

```sh
tuist generate --no-open
open PixelTerrarium.xcworkspace
```

## 共通外装の生成

Blenderはベルジャー型のガラス容器、金属製の台座、上部の蓋だけを生成します。
容器内の生態系は実行時にRealityKitで組み立てます。

```sh
./Scripts/generate_assets.sh
```

生成結果は`Assets/asset-manifest.json`のSHA-256、PNG寸法、三角形数と照合されます。

## 検証

```sh
swiftlint lint --strict
xcodebuild \
  -workspace PixelTerrarium.xcworkspace \
  -scheme PixelTerrarium \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test
```

`Scripts/verify_assets.sh`だけを実行すると、Blenderを再実行せずに生成済み素材を検査できます。

## デバッグ用の日付操作

Debugビルドの設定画面には「1日進める」と「現在日に戻す」があります。
日付を進めると、午前0時の水分消費と成長確定を待たずに確認できます。

## 設計資料

- [アーキテクチャ](Docs/architecture.md)
- [育成ルール](Docs/growth-rules.md)
- [3D素材パイプライン](Docs/asset-pipeline.md)

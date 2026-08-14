# 3D素材パイプライン

`Scripts/generate_assets.sh`はBlenderをバックグラウンド起動し、ベルジャー型の共通外装を決定的に生成します。

- `Assets/Generated/USDZ/terrarium_shell.usdz`：ガラス容器、台座、蓋の共通モデル
- `Assets/Generated/Preview/terrarium_shell.png`：外装の目視確認用画像
- `Assets/Blender/terrarium.blend`：再編集可能なBlenderファイル
- `Assets/asset-manifest.json`：サイズ、SHA-256、PNG寸法、三角形数

生成後は素材検査を行い、USDZをアプリのModelsリソースへ同期します。
現在の共通外装は6,936三角形で、検査上限は25,000三角形です。

苔、シダ、石、朽木、水滴はUSDZへ焼き込みません。
これらは`TerrariumLayoutGenerator`がシードと育成状態から配置し、RealityKitが実行時に描画します。
Widgetも固定PNGを持たず、同じレイアウトをSwiftUI Canvasで描画します。

生成物を直接編集せず、外装の形状や材質を変える場合は`Scripts/Blender/generate_terrarium.py`を修正して再生成します。

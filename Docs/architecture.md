# アーキテクチャ

`TerrariumCore` は Foundation のみに依存し、決定的な育成計算と Widget 用スナップショットを提供します。

アプリ本体は SwiftData と RealityKit を所有し、Widget は App Group の JSON だけを読み取ります。

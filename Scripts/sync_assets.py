#!/usr/bin/env python3
"""生成済み素材をApp/Widgetのリソースへ同期する。"""

from __future__ import annotations

import json
import shutil
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GENERATED = ROOT / "Assets" / "Generated"
APP_MODELS = ROOT / "App" / "Resources" / "Models"
WIDGET_CATALOG = ROOT / "Widget" / "Resources" / "Assets.xcassets"


def main() -> None:
    APP_MODELS.mkdir(parents=True, exist_ok=True)
    for stale_path in APP_MODELS.glob("terrarium_stage_*.usdz"):
        stale_path.unlink()
    for stale_path in WIDGET_CATALOG.glob("terrarium_stage_*.imageset"):
        shutil.rmtree(stale_path)

    for source in sorted((GENERATED / "USDZ").glob("terrarium_shell.usdz")):
        shutil.copy2(source, APP_MODELS / source.name)

    print("Synced shared shell USDZ model")


if __name__ == "__main__":
    main()

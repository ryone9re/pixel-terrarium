#!/usr/bin/env python3
"""素材個数・ハッシュ・PNG寸法・ポリゴン予算を検査する。"""

from __future__ import annotations

import hashlib
import json
import struct
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "Assets"
GENERATED = ASSETS / "Generated"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def png_size(path: Path) -> tuple[int, int]:
    data = path.read_bytes()[:24]
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"not a PNG: {path}")
    return struct.unpack(">II", data[16:24])


def main() -> None:
    manifest = json.loads((ASSETS / "asset-manifest.json").read_text(encoding="utf-8"))
    records = manifest["assets"]
    usdz = [record for record in records if record["kind"] == "shell-usdz"]
    pngs = [record for record in records if record["kind"] == "preview-png"]
    assert len(usdz) == 1, f"expected 1 shell USDZ, found {len(usdz)}"
    assert len(pngs) == 1, f"expected 1 preview PNG, found {len(pngs)}"

    for record in records:
        path = GENERATED / record["file"]
        assert path.exists(), f"missing {path}"
        assert path.stat().st_size > 0, f"empty {path}"
        assert sha256(path) == record["sha256"], f"hash mismatch {path}"
        if record["kind"] == "preview-png":
            assert png_size(path) == (1024, 1024), f"wrong dimensions {path}"
        else:
            assert record["triangleCount"] <= 25_000, f"triangle budget exceeded {path}"

    print("Verified shared shell USDZ and preview PNG")


if __name__ == "__main__":
    main()

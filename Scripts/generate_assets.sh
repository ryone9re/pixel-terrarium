#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
BLENDER_BIN=${BLENDER_BIN:-$(command -v blender)}

"$BLENDER_BIN" --background --python-exit-code 1 \
  --python "$ROOT_DIR/Scripts/Blender/generate_terrarium.py" \
  -- \
  --output-dir "$ROOT_DIR/Assets/Generated" \
  --blend-file "$ROOT_DIR/Assets/Blender/terrarium.blend"

python3 "$ROOT_DIR/Scripts/verify_assets.py"
python3 "$ROOT_DIR/Scripts/sync_assets.py"
rm -f "$ROOT_DIR/Assets/terrarium-contact-sheet.png"
xcrun swift "$ROOT_DIR/Scripts/make_app_icon.swift"

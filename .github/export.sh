#!/usr/bin/env bash
set -euo pipefail

godot=$1
destination=$2
mkdir -p "$destination"
destination=$(cd "$destination" && pwd)
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT

export_game() {
  local preset=$1 output=$2
  "$godot" --headless --export-release "$preset" "$output" 2>&1 | tee "$stage/export.log"
  # The headless dummy renderer can report an unreleased shader on shutdown.
  if grep -vE "^ERROR: [0-9]+ RID allocations of type .*RendererDummy.*DummyShaderE.* leaked at exit\.$" "$stage/export.log" | grep -E '(^|[[:space:]])(SCRIPT ERROR|SHADER ERROR|ERROR):'; then
    return 1
  fi
  test -s "$output"
}

for target in windows linux mac web; do
  mkdir -p "$stage/$target"
  case $target in
    windows)
      export_game "Windows Desktop" "$stage/$target/bluesim.exe"
      cp eeprom.bin "$stage/$target/"
      ;;
    linux)
      export_game "Linux" "$stage/$target/bluesim.x86_64"
      cp eeprom.bin "$stage/$target/"
      ;;
    mac)
      export_game "macOS" "$stage/$target/bluesim.zip"
      unzip -q "$stage/$target/bluesim.zip" -d "$stage/$target"
      rm "$stage/$target/bluesim.zip"
      cp eeprom.bin "$stage/$target/"
      ;;
    web) export_game "Web" "$stage/$target/index.html" ;;
  esac
  archive="$destination/bluesim-$target.zip"
  rm -f "$archive"
  (cd "$stage/$target" && zip -qry "$archive" .)
done

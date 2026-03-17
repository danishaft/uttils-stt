#!/usr/bin/env bash
set -euo pipefail

SCRIPT_PATH="$(readlink -f -- "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd -- "$(dirname -- "$SCRIPT_PATH")" && pwd)"
PYTHON_BIN="${PYTHON_BIN:-python3}"
VENV="${STT_VENV:-$HOME/.venvs/stt}"

if ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
  echo "Error: $PYTHON_BIN not found."
  exit 1
fi

"$PYTHON_BIN" -m venv "$VENV"
source "$VENV/bin/activate"

python -m pip install --upgrade pip setuptools wheel
python -m pip install --upgrade faster-whisper

cat <<EOF
STT environment is ready.
- Venv: $VENV
- Installed: faster-whisper

Next:
  python transcribe_faster_whisper.py --input audio.wav --out-dir ./output
EOF

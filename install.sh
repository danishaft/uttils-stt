#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
PYTHON_BIN="${PYTHON_BIN:-python3}"
VENV="${STT_VENV:-$HOME/.venvs/stt}"

umask 077

if ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
  echo "Error: $PYTHON_BIN not found."
  exit 1
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "Error: ffmpeg is required. Install it first, then retry."
  exit 1
fi

if ! "$PYTHON_BIN" -c 'import sys; raise SystemExit(sys.version_info < (3, 10))'; then
  echo "Error: Python 3.10 or newer is required."
  exit 1
fi

"$PYTHON_BIN" -m venv "$VENV"
source "$VENV/bin/activate"

python -m pip install --requirement "$SCRIPT_DIR/requirements.lock"

cat <<EOF
STT environment tools are ready.
- Venv: $VENV
- Installed: faster-whisper, yt-dlp

Next:
  $SCRIPT_DIR/transcribe.sh --url "https://youtube.com/watch?v=..."

Note:
  The first transcription will download model weights once.
EOF

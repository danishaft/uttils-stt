#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
VENV="${STT_VENV:-$HOME/.venvs/stt}"
MODEL="${STT_MODEL:-small}"
LANGUAGE="${STT_LANG:-auto}"
OUTPUT_ROOT="${STT_OUTPUT_ROOT:-$HOME/Transcripts}"

INPUT_MODE=""
INPUT_VALUE=""

umask 077

require_opt_value() {
  local opt_name="$1"
  local opt_value="${2:-}"
  if [[ -z "$opt_value" || "$opt_value" == --* ]]; then
    echo "Error: $opt_name requires a value."
    exit 1
  fi
  printf '%s' "$opt_value"
}

usage() {
  cat <<'EOF'
Usage:
  transcribe.sh --url <youtube_url> [--model small|medium|large-v3] [--lang en|auto] [--out <dir>]
  transcribe.sh --file <audio_or_video_file> [--model small|medium|large-v3] [--lang en|auto] [--out <dir>]

Examples:
  transcribe.sh --url "https://www.youtube.com/watch?v=abc123" --model medium --lang en
  transcribe.sh --file "/path/to/podcast.mp3" --model small

Outputs:
  <out>/<timestamp>-<title>/
    - audio.wav
    - transcript.txt
    - transcript.srt
    - segments.json
    - metadata.json
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --url)
      if [[ -n "$INPUT_MODE" ]]; then
        echo "Error: choose only one input mode (--url or --file)."
        exit 1
      fi
      INPUT_MODE="url"
      INPUT_VALUE="$(require_opt_value "$1" "${2:-}")"
      shift 2
      ;;
    --file)
      if [[ -n "$INPUT_MODE" ]]; then
        echo "Error: choose only one input mode (--url or --file)."
        exit 1
      fi
      INPUT_MODE="file"
      INPUT_VALUE="$(require_opt_value "$1" "${2:-}")"
      shift 2
      ;;
    --model)
      MODEL="$(require_opt_value "$1" "${2:-}")"
      shift 2
      ;;
    --lang|--language)
      LANGUAGE="$(require_opt_value "$1" "${2:-}")"
      shift 2
      ;;
    --out)
      OUTPUT_ROOT="$(require_opt_value "$1" "${2:-}")"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$INPUT_MODE" || -z "$INPUT_VALUE" ]]; then
  usage
  exit 1
fi

if [[ ! "$MODEL" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "Error: invalid model value: $MODEL"
  exit 1
fi

if [[ "$LANGUAGE" != "auto" && ! "$LANGUAGE" =~ ^[a-z]{2,3}(-[A-Za-z0-9]+)?$ ]]; then
  echo "Error: invalid language value: $LANGUAGE (use e.g. en, fr, or auto)"
  exit 1
fi

if [[ ! -x "$VENV/bin/python" ]]; then
  cat <<EOF
Error: STT environment is missing.
Run this first:
  $SCRIPT_DIR/install.sh
EOF
  exit 1
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "Error: ffmpeg is required. Install ffmpeg and retry."
  exit 1
fi

source "$VENV/bin/activate"

TMP_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

SOURCE_AUDIO=""
TITLE=""
SOURCE_URL=""

if [[ "$INPUT_MODE" == "url" ]]; then
  SOURCE_URL="$INPUT_VALUE"

  TITLE="$("$VENV/bin/python" -m yt_dlp --skip-download --print "%(title)s" "$SOURCE_URL" 2>/dev/null | head -n1 || true)"
  if [[ -z "$TITLE" ]]; then
    TITLE="youtube-audio"
  fi

  "$VENV/bin/python" -m yt_dlp -f "bestaudio/best" -o "$TMP_DIR/source.%(ext)s" "$SOURCE_URL"
  SOURCE_AUDIO="$(find "$TMP_DIR" -maxdepth 1 -type f -name "source.*" | head -n1)"
  if [[ -z "$SOURCE_AUDIO" ]]; then
    echo "Error: could not download source audio."
    exit 1
  fi
else
  if [[ ! -f "$INPUT_VALUE" ]]; then
    echo "Error: file not found: $INPUT_VALUE"
    exit 1
  fi
  SOURCE_AUDIO="$INPUT_VALUE"
  TITLE="$(basename -- "$INPUT_VALUE")"
fi

SAFE_TITLE="$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9._-]+/-/g; s/^-+//; s/-+$//; s/-{2,}/-/g')"
if [[ -z "$SAFE_TITLE" ]]; then
  SAFE_TITLE="audio"
fi
SAFE_TITLE="${SAFE_TITLE:0:80}"

STAMP="$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUTPUT_ROOT"
if [[ ! -w "$OUTPUT_ROOT" ]]; then
  echo "Error: output root is not writable: $OUTPUT_ROOT"
  exit 1
fi
RUN_DIR="$(mktemp -d "$OUTPUT_ROOT/${STAMP}-${SAFE_TITLE}-XXXXXX")"

WAV_PATH="$RUN_DIR/audio.wav"

echo "Preparing audio..."
ffmpeg -nostdin -y -i "$SOURCE_AUDIO" -ac 1 -ar 16000 "$WAV_PATH" -loglevel error

if [[ -n "$SOURCE_URL" ]]; then
  printf "%s\n" "$SOURCE_URL" > "$RUN_DIR/source_url.txt"
fi

echo "Transcribing with faster-whisper (model: $MODEL, lang: $LANGUAGE)..."
"$VENV/bin/python" "$SCRIPT_DIR/transcribe_faster_whisper.py" \
  --input "$WAV_PATH" \
  --out-dir "$RUN_DIR" \
  --model "$MODEL" \
  --language "$LANGUAGE"

cat <<EOF
Done.
Output directory:
  $RUN_DIR
Files:
  transcript.txt
  transcript.srt
  segments.json
  metadata.json
EOF

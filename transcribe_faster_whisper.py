#!/usr/bin/env python3
"""Transcribe audio files using faster-whisper model."""
import argparse
import json
import sys
from pathlib import Path

from faster_whisper import WhisperModel


def format_srt_time(seconds: float) -> str:
    """Convert seconds to SRT timestamp format."""
    total_ms = int(round(seconds * 1000))
    hours = total_ms // 3_600_000
    remainder = total_ms % 3_600_000
    minutes = remainder // 60_000
    remainder = remainder % 60_000
    secs = remainder // 1000
    ms = remainder % 1000
    return f"{hours:02}:{minutes:02}:{secs:02},{ms:03}"


def main() -> int:
    parser = argparse.ArgumentParser(description="Transcribe audio with faster-whisper")
    parser.add_argument("--input", required=True, help="Path to WAV file")
    parser.add_argument("--out-dir", required=True, help="Output directory")
    parser.add_argument("--model", default="small", help="Whisper model (tiny/small/medium/large-v3)")
    parser.add_argument("--language", default="auto", help="Language code (en, fr, etc.) or auto")
    args = parser.parse_args()

    input_path = Path(args.input)
    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    if not input_path.exists():
        print(f"Error: input file not found: {input_path}", file=sys.stderr)
        return 1

    # Load model and transcribe
    print(f"Loading model '{args.model}'...")
    model = WhisperModel(args.model)
    
    print(f"Transcribing {input_path.name}...")
    segments, info = model.transcribe(
        str(input_path),
        language=args.language if args.language != "auto" else None,
        beam_size=5,
        vad_filter=True,
    )

    # Write transcript.txt
    transcript_path = out_dir / "transcript.txt"
    with open(transcript_path, "w", encoding="utf-8") as f:
        for segment in segments:
            f.write(segment.text + "\n")

    print(f"Transcription complete: {transcript_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

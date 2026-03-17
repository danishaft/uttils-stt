#!/usr/bin/env python3
"""Transcribe audio files using faster-whisper model."""
import argparse
import json
import sys
from datetime import datetime, timezone
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

    # Collect segments for output
    segment_list = []
    
    # Write transcript.txt
    transcript_path = out_dir / "transcript.txt"
    with open(transcript_path, "w", encoding="utf-8") as f:
        for segment in segments:
            segment_list.append({
                "start": segment.start,
                "end": segment.end,
                "text": segment.text,
            })
            f.write(segment.text + "\n")

    # Write transcript.srt
    srt_path = out_dir / "transcript.srt"
    with open(srt_path, "w", encoding="utf-8") as f:
        for i, seg in enumerate(segment_list, 1):
            f.write(f"{i}\n")
            f.write(f"{format_srt_time(seg['start'])} --> {format_srt_time(seg['end'])}\n")
            f.write(f"{seg['text']}\n\n")

    # Write segments.json
    segments_path = out_dir / "segments.json"
    with open(segments_path, "w", encoding="utf-8") as f:
        json.dump(segment_list, f, indent=2)

    # Write metadata.json
    metadata = {
        "model": args.model,
        "language": info.language if hasattr(info, "language") else args.language,
        "duration": info.duration if hasattr(info, "duration") else 0,
        "transcribed_at": datetime.now(timezone.utc).isoformat(),
        "input_file": input_path.name,
        "segment_count": len(segment_list),
    }
    metadata_path = out_dir / "metadata.json"
    with open(metadata_path, "w", encoding="utf-8") as f:
        json.dump(metadata, f, indent=2)

    print(f"Transcription complete:")
    print(f"  {transcript_path}")
    print(f"  {srt_path}")
    print(f"  {segments_path}")
    print(f"  {metadata_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

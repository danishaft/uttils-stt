# stt

Transcribe YouTube videos or audio files to text + SRT subtitles using faster-whisper.

## Install

Requires `ffmpeg` first:

```bash
# Ubuntu/Debian
sudo apt install ffmpeg

# macOS
brew install ffmpeg
```

Then set up the environment:

```bash
./install.sh
```

This creates a virtual environment with `faster-whisper` and `yt-dlp`.

## Quick Start

```bash
# YouTube video
./transcribe.sh --url "https://youtube.com/watch?v=abc123" --model medium

# Local audio file
./transcribe.sh --file ~/podcast.mp3 --model small --lang en
```

## Output

Each transcription creates a timestamped folder:

```
~/Transcripts/20260314-120000-video-title/
├── audio.wav          # Converted audio (16kHz mono)
├── transcript.txt     # Plain text transcript
├── transcript.srt     # Subtitle file
├── segments.json      # Timestamped segments with confidence
└── metadata.json      # Model, language, duration info
```

## Options

| Flag | Description | Default |
|------|-------------|---------|
| `--url` | YouTube URL to transcribe | — |
| `--file` | Local audio/video file path | — |
| `--model` | Whisper model: tiny, small, medium, large-v3 | small |
| `--lang` | Language code (en, fr, de) or "auto" | auto |
| `--out` | Output directory root | ~/Transcripts |

## Models

| Model | Speed | Accuracy | RAM |
|-------|-------|----------|-----|
| tiny | ~32x | Low | ~1 GB |
| small | ~16x | Medium | ~2 GB |
| medium | ~6x | High | ~5 GB |
| large-v3 | 1x | Best | ~10 GB |

First run downloads model weights (~100MB–3GB depending on model).

## Examples

```bash
# English podcast, medium model
./transcribe.sh --url "https://youtube.com/watch?v=podcast123" --model medium --lang en

# German interview, small model
./transcribe.sh --file ~/interview.mp3 --model small --lang de

# Auto-detect language, large model for best accuracy
./transcribe.sh --file ~/meeting.wav --model large-v3
```

## License

MIT

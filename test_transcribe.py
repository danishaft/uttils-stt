import unittest

from transcribe_faster_whisper import format_srt_time


class FormatSrtTimeTests(unittest.TestCase):
    def test_formats_subseconds_minutes_and_hours(self) -> None:
        cases = {
            0: "00:00:00,000",
            61.234: "00:01:01,234",
            3_661.005: "01:01:01,005",
        }

        for seconds, expected in cases.items():
            with self.subTest(seconds=seconds):
                self.assertEqual(format_srt_time(seconds), expected)


if __name__ == "__main__":
    unittest.main()

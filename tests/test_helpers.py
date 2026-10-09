import os
from pathlib import Path
import shutil
import signal
import socket
import subprocess
import tempfile
import time
import unittest
from urllib.error import URLError
from urllib.request import urlopen


ROOT = Path(__file__).resolve().parents[1]


class HelperTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name) / "trip one"
        self.directory.mkdir()

    def zsh(self, code, *args):
        return subprocess.run(
            ["zsh", "-df", "-c", 'source "$1/zsh/conf.d/functions.zsh"; ' + code,
             "helper-test", str(ROOT), *args],
            cwd=self.directory,
            text=True,
            capture_output=True,
            timeout=10,
        )

    def test_proxy_urls_have_no_accent_characters(self):
        result = self.zsh('set_proxy proxy.example 8123; printf "%s\\n" "$http_proxy" "$https_proxy"')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.splitlines(), [
            "http://proxy.example:8123", "https://proxy.example:8123",
        ])

    def test_urlencode_handles_unicode_spaces_and_reserved_characters(self):
        result = self.zsh('source "$1/zsh/conf.d/aliases.zsh"; eval \'urlencode "$2"\'', "caffè +/?&")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "caff%C3%A8+%2B%2F%3F%26")

    def test_server_serves_text_and_binary_on_the_requested_port(self):
        (self.directory / "note.txt").write_text("caffè", encoding="utf-8")
        (self.directory / "blob.bin").write_bytes(b"\x00\xff\x80")
        with socket.socket() as reserved:
            reserved.bind(("127.0.0.1", 0))
            port = reserved.getsockname()[1]
        process = subprocess.Popen(
            ["zsh", "-df", "-c", 'source "$1/zsh/conf.d/functions.zsh"; open() { :; }; server "$2"',
             "helper-test", str(ROOT), str(port)],
            cwd=self.directory,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
        try:
            deadline = time.monotonic() + 5
            while True:
                try:
                    with urlopen(f"http://127.0.0.1:{port}/note.txt", timeout=0.5) as response:
                        self.assertEqual(response.read(), "caffè".encode("utf-8"))
                        self.assertEqual(response.headers.get_content_type(), "text/plain")
                    break
                except URLError:
                    if process.poll() is not None or time.monotonic() >= deadline:
                        self.fail("HTTP server did not start")
                    time.sleep(0.05)
            with urlopen(f"http://127.0.0.1:{port}/blob.bin", timeout=1) as response:
                self.assertEqual(response.read(), b"\x00\xff\x80")
                self.assertEqual(response.headers.get_content_type(), "application/octet-stream")
        finally:
            try:
                os.killpg(process.pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
            process.wait(timeout=5)

    @unittest.skipUnless(shutil.which("ffmpeg") and shutil.which("ffprobe"), "FFmpeg is required")
    def test_ffmpegjoin_groups_clips_in_order_with_quoted_paths(self):
        for name, color, frames in (
            ("01 dash-front.mp4", "red", 2),
            ("02 friend's-front.mp4", "blue", 3),
            ("01-back.mp4", "green", 4),
        ):
            subprocess.run([
                "ffmpeg", "-v", "error", "-f", "lavfi", "-i", f"color=c={color}:s=32x32:r=10",
                "-frames:v", str(frames), "-c:v", "mpeg4", name,
            ], cwd=self.directory, check=True, timeout=10)
        result = self.zsh("ffmpegjoin")
        self.assertEqual(result.returncode, 0, result.stderr)
        for camera, frames in (("front", 5), ("back", 4)):
            output = self.directory / f"trip one-{camera}.mp4"
            count = subprocess.check_output([
                "ffprobe", "-v", "error", "-count_frames", "-select_streams", "v:0",
                "-show_entries", "stream=nb_read_frames", "-of", "csv=p=0", str(output),
            ], text=True, timeout=10)
            self.assertEqual(int(count.strip()), frames)
            self.assertFalse((self.directory / f"{camera}.txt").exists())
        pixels = subprocess.check_output([
            "ffmpeg", "-v", "error", "-i", str(self.directory / "trip one-front.mp4"),
            "-f", "rawvideo", "-pix_fmt", "rgb24", "pipe:1",
        ], timeout=10)
        frame_size = 32 * 32 * 3
        for frame in range(5):
            red, _, blue = pixels[frame * frame_size:frame * frame_size + 3]
            self.assertGreater(red if frame < 2 else blue, blue if frame < 2 else red)
        self.assertFalse((self.directory / "trip one-left_repeater.mp4").exists())

    @unittest.skipUnless(shutil.which("ffmpeg"), "FFmpeg is required")
    def test_ffmpegjoin_reports_failure_and_keeps_the_input_list(self):
        (self.directory / "01-front.mp4").write_text("not a video")
        result = self.zsh("ffmpegjoin")
        self.assertNotEqual(result.returncode, 0)
        self.assertTrue((self.directory / "front.txt").exists())


if __name__ == "__main__":
    unittest.main()

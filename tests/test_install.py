import os
from pathlib import Path
import shutil
import stat
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


class InstallerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name) / "home"
        self.home.mkdir()
        self.bin = Path(self.temp.name) / "bin"
        self.bin.mkdir()
        self.env = os.environ.copy()
        self.env.pop("ZSH_CUSTOM", None)
        self.env.update(HOME=str(self.home), PATH=f"{self.bin}:/usr/bin:/bin")
        for directory in (
            "themes/powerlevel10k",
            "plugins/zsh-autosuggestions",
            "plugins/zsh-syntax-highlighting",
        ):
            (self.home / ".oh-my-zsh/custom" / directory).mkdir(parents=True)
        self.command("brew", 'if [ "$1" = shellenv ]; then exit "${SHELLENV_STATUS:-0}"; fi')
        self.command("curl", "exit 23")
        self.command("git", "exit 99")

    def command(self, name, body):
        path = self.bin / name
        path.write_text(f"#!/bin/sh\n{body}\n")
        path.chmod(0o755)

    def run_installer(self):
        return subprocess.run(
            ["/bin/bash", str(ROOT / "install.sh")],
            input="agent\n",
            text=True,
            capture_output=True,
            env=self.env,
            timeout=10,
        )

    def test_existing_backups_survive_and_reinstall_is_idempotent(self):
        target = self.home / ".zshrc"
        target.write_text("current config")
        backup = self.home / ".zshrc.backup"
        backup.write_text("first backup")
        collision = self.home / ".zshrc.backup.1"
        collision.symlink_to(self.home / "missing")

        result = self.run_installer()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(backup.read_text(), "first backup")
        self.assertTrue(collision.is_symlink())
        self.assertEqual((self.home / ".zshrc.backup.2").read_text(), "current config")
        self.assertEqual(target.resolve(), ROOT / "zsh/.zshrc")

        result = self.run_installer()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertFalse((self.home / ".zshrc.backup.3").exists())

    def test_new_secrets_are_private_even_with_permissive_umask(self):
        previous = os.umask(0o022)
        try:
            result = self.run_installer()
        finally:
            os.umask(previous)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(stat.S_IMODE((self.home / ".secrets").stat().st_mode), 0o600)

    def test_shellenv_failure_stops_setup(self):
        self.env["SHELLENV_STATUS"] = "42"
        result = self.run_installer()
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("Homebrew ready", result.stdout)
        self.assertFalse((self.home / ".dotfiles_profile").exists())

    def test_homebrew_download_failure_stops_setup(self):
        (self.bin / "brew").unlink()
        result = self.run_installer()
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("Homebrew ready", result.stdout)
        self.assertFalse((self.home / ".dotfiles_profile").exists())

    def test_oh_my_zsh_download_failure_stops_before_cloning(self):
        shutil.rmtree(self.home / ".oh-my-zsh")
        result = self.run_installer()
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("Installing Powerlevel10k", result.stdout)
        self.assertFalse((self.home / ".zshrc").exists())


if __name__ == "__main__":
    unittest.main()

#!/usr/bin/env python3
"""ui-test-and-publish.sh and build-release-dmg.sh against stubbed tools: nothing is really built,
uploaded, posted or tested."""
import json
from pathlib import Path
import shutil
import stat
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parent.parent
EXIT_TEMPFAIL = 75
SCRIPT_TIMEOUT_SECONDS = 60
DMG_NAME = "Focus-Bear-3.36-525-abc1234.dmg"
VERSION = "3.36"
BUILD = "525"
WEBHOOK = "https://cliq.zoho.com.au/api/v2/bots/releasebot/incoming"

INFO_PLIST = f"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleShortVersionString</key><string>{VERSION}</string>
<key>CFBundleVersion</key><string>{BUILD}</string>
</dict></plist>
"""

# Every stub appends its arguments to $CALLS so a test can see what ran.
STUBS = {
    "npx": """
echo "npx $*" >> "$CALLS"
case "$*" in
  *whoami*) [ -n "$WRANGLER_LOGGED_IN" ] && echo "| Focus Bear | 0123456789abcdef0123456789abcdef |" || echo "You are not authenticated." ;;
  *"r2 object put"*)
    while [ $# -gt 0 ]; do [ "$1" = "--file" ] && stat -f%z "$2" > "$UPLOADED_SIZE"; shift; done ;;
esac
""",
    "curl": """
echo "curl $*" >> "$CALLS"
case "$*" in
  *-fsSI*) printf 'HTTP/1.1 200 OK\\r\\ncontent-length: %s\\r\\n' "$(cat "$UPLOADED_SIZE")" ;;
  *zapikey*) cat > "$CLIQ_BODY"; echo "$*" > "$CLIQ_URL" ;;
esac
""",
    "xcodebuild": """
echo "xcodebuild $*" >> "$CALLS"
if [ "$1" = "-exportArchive" ]; then
  while [ $# -gt 0 ]; do [ "$1" = "-exportPath" ] && out="$2"; shift; done
  mkdir -p "$out/Focus Bear.app/Contents"
  cp "$INFO_PLIST_SOURCE" "$out/Focus Bear.app/Contents/Info.plist"
fi
""",
    "codesign": """
echo "codesign $*" >> "$CALLS"
[ "$1" = "-dvv" ] && echo "Authority=${SIGNING_AUTHORITY}" >&2
exit 0
""",
    "hdiutil": """
echo "hdiutil $*" >> "$CALLS"
for last; do :; done
touch "$last"
""",
}

# Stands in for build-release-dmg.sh in the publish tests: chatter first, the DMG's path last.
FAKE_DMG_BUILDER = f"""#!/bin/bash
echo "build-dmg $*" >> "$CALLS"
[ -n "$BUILD_FAILS" ] && exit 1
echo "archiving…"
head -c 4096 /dev/zero > "$1/{DMG_NAME}"
echo "$1/{DMG_NAME}"
"""


class StubbedRepoTestCase(unittest.TestCase):
    def setUp(self):
        self.folder = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.folder)
        self.repo = self.folder / "repo"
        (self.repo / "scripts").mkdir(parents=True)
        for script in ("ui-test-and-publish.sh", "build-release-dmg.sh"):
            shutil.copy(ROOT / "scripts" / script, self.repo / "scripts" / script)
        self.write_executable(self.repo / "scripts/run-ui-tests.sh",
                              '#!/bin/bash\necho "runner $*" >> "$CALLS"\nexit "${RUNNER_EXIT:-0}"\n')
        self.write_executable(self.repo / "scripts/fake-dmg-builder.sh", FAKE_DMG_BUILDER)
        git = ["git", "-C", str(self.repo)]
        subprocess.run(git + ["init", "-q"], check=True)
        subprocess.run(git + ["add", "."], check=True)
        subprocess.run(git + ["-c", "user.name=t", "-c", "user.email=t@example.com", "commit", "-qm", "init"],
                       check=True)
        self.bin = self.folder / "bin"
        self.bin.mkdir()
        for name, body in STUBS.items():
            self.write_executable(self.bin / name, "#!/bin/bash\n" + body)
        (self.folder / "Info.plist").write_text(INFO_PLIST)
        self.calls = self.folder / "calls.log"
        self.calls.touch()
        self.cliq_body = self.folder / "cliq-body.json"
        self.cliq_url = self.folder / "cliq-url.txt"

    @staticmethod
    def write_executable(path, text):
        path.write_text(text)
        path.chmod(path.stat().st_mode | stat.S_IXUSR)

    def run_in_repo(self, command, environment=None):
        env = {
            "PATH": f"{self.bin}:/usr/bin:/bin:/usr/sbin:/usr/local/bin:/opt/homebrew/bin",
            "HOME": str(self.folder),
            "TMPDIR": str(self.folder),
            "CALLS": str(self.calls),
            "UPLOADED_SIZE": str(self.folder / "uploaded-size"),
            "CLIQ_BODY": str(self.cliq_body),
            "CLIQ_URL": str(self.cliq_url),
            "INFO_PLIST_SOURCE": str(self.folder / "Info.plist"),
            "SIGNING_AUTHORITY": "Developer ID Application: Focus Bear Pty Ltd (TCUD568B3U)",
            "WRANGLER_LOGGED_IN": "1",
            "BUILD_DMG": "scripts/fake-dmg-builder.sh",
            "ZOHO_CLIQ_BACKEND_BOT_WEBHOOK": WEBHOOK,
            "ZOHO_CLIQ_API_KEY": "zapikey-abc",
        }
        env.update(environment or {})
        return subprocess.run(command, cwd=self.repo, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                              text=True, timeout=SCRIPT_TIMEOUT_SECONDS)

    def logged(self):
        return self.calls.read_text()


class PublishTests(StubbedRepoTestCase):
    def publish(self, *arguments, environment=None):
        return self.run_in_repo(["scripts/ui-test-and-publish.sh", *arguments], environment)

    def test_failed_tests_publish_nothing(self):
        result = self.publish(environment={"RUNNER_EXIT": "1"})
        self.assertEqual(result.returncode, 1)
        self.assertIn("nothing was published", result.stderr)
        self.assertNotIn("build-dmg", self.logged())
        self.assertNotIn("r2 object put", self.logged())
        self.assertFalse(self.cliq_body.exists())

    def test_tests_that_could_not_run_say_try_again(self):
        result = self.publish("--plan", "smoke", environment={"RUNNER_EXIT": str(EXIT_TEMPFAIL)})
        self.assertEqual(result.returncode, EXIT_TEMPFAIL)
        self.assertIn("runner --plan smoke", self.logged())
        self.assertNotIn("build-dmg", self.logged())

    def test_missing_cliq_key_stops_before_the_tests(self):
        result = self.publish(environment={"ZOHO_CLIQ_API_KEY": ""})
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("ZOHO_CLIQ_API_KEY is not set", result.stderr)
        self.assertNotIn("runner", self.logged())

    def test_logged_out_wrangler_stops_before_the_tests(self):
        result = self.publish(environment={"WRANGLER_LOGGED_IN": ""})
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("npx wrangler login", result.stderr)
        self.assertNotIn("runner", self.logged())

    def test_uncommitted_changes_stop_before_the_tests(self):
        runner = self.repo / "scripts/run-ui-tests.sh"
        runner.write_text(runner.read_text() + "# edited\n")
        result = self.publish()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("uncommitted changes", result.stderr)
        self.assertNotIn("runner", self.logged())

    def test_a_failed_build_publishes_nothing(self):
        result = self.publish(environment={"BUILD_FAILS": "1"})
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("building the DMG failed", result.stderr)
        self.assertNotIn("r2 object put", self.logged())
        self.assertFalse(self.cliq_body.exists())

    def test_passing_tests_upload_the_dmg_and_post_the_link(self):
        result = self.publish("--plan", "smoke")
        self.assertEqual(result.returncode, 0, result.stderr)
        key = f"mac/ui-tested/{DMG_NAME[:-4]}/{DMG_NAME}"
        logged = self.logged()
        self.assertIn(f"npx --yes wrangler r2 object put desktop-app-releases/{key} --file ", logged)
        self.assertIn("--content-type application/x-apple-diskimage --remote", logged)
        self.assertIn(f"{WEBHOOK}?zapikey=zapikey-abc", self.cliq_url.read_text())
        body = json.loads(self.cliq_body.read_text())
        self.assertEqual(body["channel"], "versionupdates")
        self.assertEqual(body["card"], {"title": f"Mac build {DMG_NAME[:-4]} passed the smoke UI tests",
                                        "theme": "modern-inline"})
        self.assertIn(f"Download: https://downloads.focusbear.io/{key}", body["message"])
        self.assertTrue(body["message"].startswith(f"*Mac build {DMG_NAME[:-4]} passed the smoke UI tests*\n"))
        self.assertNotIn("zapikey-abc", result.stdout + result.stderr)

    def test_dry_run_builds_but_uploads_and_posts_nothing(self):
        result = self.publish("--dry-run", environment={
            "ZOHO_CLIQ_BACKEND_BOT_WEBHOOK": "", "ZOHO_CLIQ_API_KEY": "", "WRANGLER_LOGGED_IN": ""})
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Dry run: would upload", result.stdout)
        self.assertIn("build-dmg", self.logged())
        self.assertNotIn("r2 object put", self.logged())
        self.assertFalse(self.cliq_body.exists())


class BuildReleaseDmgTests(StubbedRepoTestCase):
    def build(self, environment=None):
        return self.run_in_repo(["scripts/build-release-dmg.sh", str(self.folder / "work")], environment)

    def test_prints_the_signed_dmg_path_last(self):
        result = self.build()
        self.assertEqual(result.returncode, 0, result.stderr)
        dmg = Path(result.stdout.strip().splitlines()[-1])
        self.assertTrue(dmg.name.startswith(f"Focus-Bear-{VERSION}-{BUILD}-"), dmg)
        self.assertTrue(dmg.is_file())
        logged = self.logged()
        self.assertIn("xcodebuild archive", logged)
        self.assertIn("-configuration Release", logged)
        self.assertIn("-exportArchive", logged)
        self.assertIn("codesign -f -s Developer ID Application: Focus Bear Pty Ltd (TCUD568B3U)", logged)
        self.assertIn("not notarized", result.stderr)

    def test_an_app_not_signed_with_developer_id_is_refused(self):
        result = self.build({"SIGNING_AUTHORITY": "Apple Development: Someone (RRLSAS9FG4)"})
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Developer ID", result.stderr)
        self.assertNotIn("hdiutil", self.logged())


if __name__ == "__main__":
    unittest.main()

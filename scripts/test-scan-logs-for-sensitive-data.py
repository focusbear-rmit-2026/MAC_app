import importlib.util
import io
from datetime import datetime
from pathlib import Path
import sys
import tempfile
import unittest


sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("scanner", HERE / "scan-logs-for-sensitive-data.py")
scanner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(scanner)

# Shaped like a JWT, signed by nobody.
FAKE_JWT = "eyJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJ0ZXN0LXVzZXIifQ.c2lnbmF0dXJlLW5vdC1yZWFs"
FAKE_TASK = "Renew the passport for Lisbon"


def stamp(seconds=0):
    return f"2026-10-05 12:{seconds // 60:02d}:{seconds % 60:02d} - "


def scan_lines(*lines, since=None):
    text = [line + "\n" for line in lines]
    return scanner.scan([lambda: text], since)


class SecretTests(unittest.TestCase):
    def test_finds_each_kind_of_secret(self):
        report = scan_lines(
            stamp() + f"api call failed, accessToken is:- {FAKE_JWT}",
            stamp(1) + "Authorization: Bearer abc.DEF-123_xyz==",
            stamp(2) + '{"refresh_token": "v1.' + "R" * 60 + '"}',
            stamp(2) + '{"access_token": "opaque-access"}',
            stamp(3) + "using key sk-ant-" + "a" * 30,
            stamp(4) + '{"new_password": "correct horse"}',
            stamp(5) + "signed in as someone@example.com",
            stamp(6) + "open url https://example.org/cb?code=abc123&state=NOT_STARTED",
        )
        for category in ["jwt", "bearer-token", "auth0-refresh-token", "token-field", "api-key", "password",
                         "email", "url-secret-param"]:
            self.assertIn(category, report.counts, category)
        self.assertFalse(report.is_clean)

    def test_values_the_app_already_redacted_are_clean(self):
        report = scan_lines(
            stamp() + "Authorization: Bearer <redacted>",
            stamp(1) + '{"access_token":"<redacted>", "password": "<redacted>"}',
            stamp(2) + "signed in as <email:1a2b>",
            stamp(3) + "open url focusbear://x?code=<redacted>&event_title=<text:9f3c:len12>",
            stamp(4) + "PasswordRequireInSettings: true",
            stamp(5) + "hasToken = 0;",
        )
        self.assertTrue(report.is_clean, dict(report.counts))


class PersonalContentTests(unittest.TestCase):
    def test_finds_dumps_current_tasks_and_query_text(self):
        report = scan_lines(
            stamp() + "json is:- {",
            '    title = "Morning meds";',
            "}",
            stamp(1) + f'currentTask in is URL Safe to use:Optional("{FAKE_TASK}")',
            stamp(2) + "func:- open url focusbear://event-about-to-start?event_title=Dentist%20visit&start=1",
        )
        self.assertEqual(report.counts["structure-dump"], 1)
        self.assertEqual(report.counts["current-task"], 1)
        self.assertGreaterEqual(report.counts["content-field"], 2)

    def test_identifiers_and_prose_the_app_wrote_itself_are_not_content(self):
        report = scan_lines(
            stamp() + "closeAiBlockBuddyWindow called reason=left-blocked-item",
            stamp(1) + "Show menu Item Select Another Habit:- Reason: High Priority Habit Remaining",
            stamp(2) + "pep talk stream: finished=true reason=done bytes=1900",
        )
        self.assertTrue(report.is_clean, dict(report.counts))

    def test_content_found_once_is_found_again_where_no_pattern_would_see_it(self):
        report = scan_lines(
            stamp() + f'currentTask in is App Safe :Optional("{FAKE_TASK}")',
            stamp(1) + f"FocusButton: SendCmd >> SET|GOAL|{FAKE_TASK}",
            stamp(2) + "FocusButton: SendCmd >> SET|START|1500|<text:1a2b:len29>",
        )
        self.assertEqual(report.counts["content-echo"], 1)
        self.assertEqual(report.templates["content-echo"], {"FocusButton": 1})



class BrowsingTests(unittest.TestCase):
    def test_urls_and_window_titles_fail_the_scan(self):
        report = scan_lines(
            stamp() + "checkAppFromAi: Claude window title 'Planning notes' added to AI context",
            stamp(1) + "relevance verdict discarded for https://docs.example.org/d/1: superseded",
            stamp(2) + "focusTryToBlockUnwantedUrl:- youtube.com/watch?v=abc123",
        )
        self.assertEqual(report.counts["window-title"], 1)
        self.assertEqual(report.counts["browsing-url"], 2)
        self.assertFalse(report.is_clean)

    def test_sites_titles_and_app_requests_the_app_describes_are_clean(self):
        report = scan_lines(
            stamp() + "focusTryToBlockUnwantedUrl:- <site:youtube.com:1a2b> app=com.google.Chrome",
            stamp(1) + "checkAppFromAi: Claude window title <text:9f3c:len14> added to AI context",
            stamp(2) + "relevance verdict discarded for <site:docs.example.org:77aa>: superseded keyLive=true"
            " liveURL=nil keyTarget=<site:docs.example.org:77aa> liveTitle=nil keyTitle=<text:12ab:len9>",
            stamp(3) + "api call getConfigFile https://focus-bear.github.io/assets/config.json",
            stamp(4) + "api call getSettings https://api.focusbear.io/user/settings",
            stamp(5) + "launched /Applications/Focus Bear.app/Contents/MacOS/Focus Bear",
        )
        self.assertTrue(report.is_clean, dict(report.counts))


def history(*lines, exported_at="2026-10-05 12:30:00"):
    header = [f"{scanner.HISTORY_EXPORTED_AT}{exported_at}\n"] if exported_at else []
    return scanner.check_history(header + [line + "\n" for line in lines])


class HistoryTests(unittest.TestCase):
    def test_a_history_inside_the_window_passes(self):
        report = history("2026-10-05 12:00:00 blocked focusBlockUnwantedUrl url=\"https://example.org/a\"",
                         "2026-10-05 12:29:59 allowed focusTimer url=\"https://example.org/b\"")
        self.assertEqual(report.entries, 2)
        self.assertTrue(report.is_within_window)

    def test_an_entry_older_than_thirty_minutes_fails(self):
        report = history("2026-10-05 11:59:59 seen focusTryToBlockUnwantedUrl",
                         "2026-10-05 12:10:00 seen focusTryToBlockUnwantedUrl")
        self.assertEqual(report.too_old, 1)
        self.assertFalse(report.is_within_window)

    def test_a_file_without_the_export_header_is_a_usage_error(self):
        self.assertIsNone(history("2026-10-05 12:00:00 seen x", exported_at=None))
        with tempfile.TemporaryDirectory() as folder:
            log = Path(folder) / "Debug_Logs.txt"
            log.write_text(stamp() + "checkLogFileRotation\n")
            self.assertEqual(scanner.main(["--history", str(log)]), scanner.EXIT_USAGE)
            exported = Path(folder) / "browsing-history.log"
            exported.write_text(f"{scanner.HISTORY_EXPORTED_AT}2026-10-05 12:30:00\n2026-10-05 11:00:00 seen x\n")
            self.assertEqual(scanner.main(["--history", str(exported)]), scanner.EXIT_FOUND)


class ReportingTests(unittest.TestCase):
    def test_templates_name_the_log_call_and_never_hold_the_value(self):
        report = scan_lines(
            stamp() + f'currentTask in is URL Safe to use:Optional("{FAKE_TASK}")',
            stamp(1) + "func:- open url focusbear://event-about-to-start?event_title=Dentist",
            stamp(2) + "relevance verdict discarded for docs.example.org/x title='Secret plan'",
        )
        templates = [template for counter in report.templates.values() for template in counter]
        self.assertIn("currentTask in is URL Safe to use", templates)
        self.assertIn("open url focusbear", templates)
        for template in templates:
            for value in [FAKE_TASK, "Dentist", "Secret plan", "docs.example.org"]:
                self.assertNotIn(value, template)

    def test_since_skips_older_entries_and_their_continuation_lines(self):
        report = scan_lines(
            "2026-10-04 09:00:00 - json is:- {",
            '    title = "Old";',
            "2026-10-05 12:00:00 - ordinary line",
            since=datetime(2026, 10, 5),
        )
        self.assertEqual(report.entries_scanned, 1)
        self.assertTrue(report.is_clean)

    def test_main_exits_non_zero_on_findings_and_zero_when_clean(self):
        with tempfile.TemporaryDirectory() as folder:
            dirty = Path(folder) / "Debug_Logs.txt"
            dirty.write_text(stamp() + "signed in as someone@example.com\n")
            clean = Path(folder) / "Debug_Logs - 2026-10-01.txt"
            clean.write_text(stamp() + "checkLogFileRotation\n")
            self.assertEqual(scanner.main([str(dirty)]), scanner.EXIT_FOUND)
            self.assertEqual(scanner.main([str(clean)]), scanner.EXIT_CLEAN)
            self.assertEqual(scanner.main([str(clean), "--since", "yesterday"]), scanner.EXIT_USAGE)


    def test_reads_standard_input_and_scans_it_for_echoes_too(self):
        lines = [stamp() + f'currentTask in is App Safe :Optional("{FAKE_TASK}")\n',
                 stamp(1) + f"FocusButton: SendCmd >> SET|GOAL|{FAKE_TASK}\n"]
        original = sys.stdin
        sys.stdin = io.StringIO("".join(lines))
        try:
            source = scanner.file_source(Path(scanner.STDIN_PATH))
            report = scanner.scan([source])
        finally:
            sys.stdin = original
        self.assertEqual(report.counts["current-task"], 1)
        self.assertEqual(report.counts["content-echo"], 1)


if __name__ == "__main__":
    unittest.main()

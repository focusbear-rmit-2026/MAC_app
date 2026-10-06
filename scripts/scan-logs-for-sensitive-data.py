#!/usr/bin/env python3
"""Scan Focus Bear debug logs for secrets and personal content that must never be logged.

The app redacts secrets as it writes (`LogRedactor`) and keeps personal content out of its log
calls (`LogPrivacy`). This checks the result on real log files, read-only, so "the logs are
clean" is something measured rather than assumed.

It never prints a matched value: findings are reported as counts per category, plus (with
--templates) the static label of each offending line, which is enough to find the log call.

    scripts/scan-logs-for-sensitive-data.py                      # the default log folders
    scripts/scan-logs-for-sensitive-data.py --since "2026-10-05 12:34:30" --templates
    scripts/scan-logs-for-sensitive-data.py path/to/Debug_Logs.txt
    some-log-transform < Debug_Logs.txt | scripts/scan-logs-for-sensitive-data.py -
    scripts/scan-logs-for-sensitive-data.py --history <report>/logs/browsing-history.log

Browsing URLs and window titles are findings too: the log names only the site (`<site:host:ref>`)
and describes titles, while the full values live in the encrypted 30-minute browsing history.
`--history` checks an exported history instead: every entry within 30 minutes of its export time.

Exit status: 0 when nothing blocking was found, 1 when something was, 2 on a usage error.
"""

import argparse
from collections import Counter, defaultdict
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
import re
import sys

APP_SUPPORT = Path.home() / "Library" / "Application Support"
# Debug builds log under the development bundle id, Release under the production one.
DEFAULT_LOG_FOLDERS = [
    APP_SUPPORT / "com.App.EarnYourScreentime" / "Logs",
    APP_SUPPORT / "com.focusbear.screentime" / "Logs",
]
LOG_FILE_GLOB = "Debug_Logs*.txt"
STDIN_PATH = "-"
TIMESTAMP_FORMAT = "%Y-%m-%d %H:%M:%S"
TIMESTAMP_EXAMPLE = "2026-10-05 12:34:30"
ENTRY_START = re.compile(r"^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) - ")
TEMPLATE_LABEL_LENGTH = 40
# Log calls write `label:- value`, `label: value`, `label {dump}`, `label host/path`, `label?q=value`
# or `label >> CMD|value`; the label ends at the first of these.
TEMPLATE_CUT = re.compile(r""":|>>|["'\[{(<=?|]|\b(?:[A-Za-z0-9-]+\.)+[A-Za-z]{2,}\b""")
FUNC_PREFIX = re.compile(r"^func(?: call)?:-\s*")
# Shorter values (e.g. "Email", "Work") are too common to tell an echo from a coincidence.
MINIMUM_ECHO_LENGTH = 8
EXIT_CLEAN, EXIT_FOUND, EXIT_USAGE = 0, 1, 2
# Focus Bear's own services: requests the app made, not pages the user browsed (`LogPrivacy.appOwnedHosts`).
APP_OWNED_HOSTS = ["api.focusbear.io", "downloads.focusbear.io", "focus-bear.github.io"]
APP_OWNED_HOST = "(?:" + "|".join(re.escape(host) for host in APP_OWNED_HOSTS) + r")\b"
# Bundle and file names that look like `host.tld/path` in a file path (`Focus Bear.app/Contents`).
FILE_SUFFIXES = "app|appex|bundle|framework|dylib|plist|json|jsonl|txt|log|csv|swift|png|xcconfig|lproj|zip"
# `BrowsingHistory.retention` and the header its export writes.
HISTORY_WINDOW_MINUTES = 30
HISTORY_EXPORTED_AT = "# exported-at: "

# What `LogRedactor` and `LogPrivacy` leave behind (`<redacted>`, `<jwt>`, `<email:1a2b>`,
# `<text:1a2b:len14>`, `<dictionary keys=…>`, `<removed>`). A value written as one is not a leak.
# A value cut at "#" by a decoded deep link has its tail described as the URL fragment.
REDACTED_VALUE = re.compile(r"^#?<[^<>]*>$")
FLAG_VALUES = {"", "true", "false", "0", "1", "yes", "no", "nil", "null", "<null>", "none", "optional(nil)"}
# Enum-like values such as `reason=left-blocked-item` say which branch ran, not what the user wrote.
IDENTIFIER_VALUE = re.compile(r"^[a-z][a-z0-9]*(?:[-_.][a-z0-9]+)*$")
# Numbers and ISO dates, which `LogPrivacy.url` keeps readable on purpose.
NUMBER_OR_DATE_VALUE = re.compile(r"^(?:-?\d+(?:\.\d+)?|\d{4}-\d{2}-\d{2}(?:(?:[T +]|%20)[\d:.]+Z?)?)$")
QUOTED_OR_BARE_VALUE = r"""(#?<[^<>]*>|"(?:[^"\\]|\\.)*"|'[^']*'|[^\s,;&}\)]+)"""


def is_redacted(value: str) -> bool:
    stripped = value.strip().strip("\"'")
    return stripped.lower() in FLAG_VALUES or bool(REDACTED_VALUE.match(stripped))


def is_any_value(match: re.Match, group: int) -> bool:
    return not is_redacted(match.group(group))


def is_free_text_value(match: re.Match, group: int) -> bool:
    """Quoted strings always count. A bare value counts only in `key=value` form (URL queries,
    NSDictionary descriptions) and only when it is not an identifier: `Reason: High Priority`
    is prose a log call wrote itself, `reason=done` is an enum."""
    value = match.group(group)
    if is_redacted(value):
        return False
    if value[:1] in "\"'":
        return True
    separator = match.group(0)[: match.start(group) - match.start(0)].rstrip()
    return separator.endswith("=") and not IDENTIFIER_VALUE.match(value) and not NUMBER_OR_DATE_VALUE.match(value)


@dataclass(frozen=True)
class Category:
    name: str
    pattern: re.Pattern
    value_group: int = 0  # 0 means the whole match is the sensitive value
    accepts: object = is_any_value
    is_personal_content: bool = False  # its values are looked for elsewhere in the log (echoes)

    def findings(self, message: str):
        for match in self.pattern.finditer(message):
            if self.accepts(match, self.value_group):
                yield match


def _field(keys: str) -> re.Pattern:
    # `[A-Za-z_]` before the key keeps `title` from matching `tab_title` or `liveTitle`.
    return re.compile(r'(?i)(?<![A-Za-z_])"?(?:' + keys + r')"?\s*[:=]\s*' + QUOTED_OR_BARE_VALUE)


CATEGORIES = [
    Category("jwt", re.compile(r"eyJ[A-Za-z0-9_-]{4,}\.[A-Za-z0-9_-]{4,}\.[A-Za-z0-9_-]*")),
    Category("bearer-token", re.compile(r"(?i)\bbearer\s+([A-Za-z0-9\-._~+/<>:]+=*)"), 1),
    # Auth0 refresh tokens are opaque; the tenant issues them as `v1.` plus a long random string.
    Category("auth0-refresh-token", re.compile(r"\bv1\.[A-Za-z0-9_-]{40,}")),
    # OAuth codes, signed-URL signatures and credentials (S3 `X-Amz-*`), session ids, API keys.
    Category("url-secret-param", re.compile(
        r"""(?i)[?&;](?:code|sig|signature|x-amz-signature|x-amz-credential|x-amz-security-token|session_?id|"""
        r"""api_?key|key|secret|auth|[a-z_]*token)=(<[^<>]*>|[^&\s"'#]+)"""), 1),
    Category("token-field", _field(r"[a-z_]*_?token|[a-z]*Token|credentials?"), 1),
    Category("api-key", re.compile(
        r"\b(?:sk-(?:ant-)?[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{35}"
        r"|gh[pousr]_[A-Za-z0-9]{30,}|xox[abprs]-[A-Za-z0-9-]{10,})")),
    Category("api-key-field", _field(r"api[_-]?key|x-api-key|client[_-]?secret|secret[_-]?key|private[_-]?key"), 1),
    Category("password", _field(r"[a-z_]*password|[a-z]*Password"), 1),
    Category("email", re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}")),
    # Window titles come before content fields so `chat title: '…'` is counted once, as a title.
    Category("window-title", re.compile(r"""(?i)\b(?:window|chat|tab) title:?\s*(['"])(.+?)\1"""), 2),
    Category("window-title", _field(r"(?:tab|window|live|key|page)_?title"), 1),
    Category("browsing-url", re.compile(r"""\b(?:https?|file)://(?!""" + APP_OWNED_HOST + r""")[^\s"'<>]+""")),
    # The blocker logs most pages without a scheme: `youtube.com/watch?v=…`.
    Category("browsing-url", re.compile(
        r"""(?<![\w./@-])(?!""" + APP_OWNED_HOST + r""")(?:[A-Za-z0-9-]+\.)+(?!(?:""" + FILE_SUFFIXES
        + r""")/)[a-z]{2,}/[^\s"'<>,]*""")),
    # `currentTask … :Optional("…")`: the to-do the user is working on.
    Category("current-task", re.compile(r'(?i)current ?task[^:]*:\s*Optional\("((?:[^"\\]|\\.)*)"\)'), 1,
             is_personal_content=True),
    # Personal content as it appears in dumped JSON / NSDictionary descriptions and URL queries.
    Category("content-field", _field(
        r"(?:event|task|habit|todo|to_do|project|note)?_?title|notes?|description|reason|goal|intention|"
        r"brain_?dump|habit_?name|task_?name|summary|content|body|current_?tasks?|question|answer|"
        r"conversation|message|justification|query|search"), 1,
             accepts=is_free_text_value, is_personal_content=True),
]

# Log calls known to dump a whole structure the encryption design seals at rest (habit settings,
# device settings / block lists, AI request payloads).
DUMP_PREFIXES = re.compile(
    r"(?i)^(?:settings )?json is:- [\[{]|^User Local Device Settings:- [\[{]|json data for api is:- [\[{]")
DUMP_CATEGORY = "structure-dump"
ECHO_CATEGORY = "content-echo"


@dataclass
class Report:
    counts: Counter = field(default_factory=Counter)
    templates: dict = field(default_factory=lambda: defaultdict(Counter))
    entries_scanned: int = 0

    def add(self, category: str, template: str) -> None:
        self.counts[category] += 1
        self.templates[category][template] += 1

    @property
    def is_clean(self) -> bool:
        return not self.counts


def template_for(line: str) -> str:
    """The line's static label: everything before its first value, digits folded, so it never
    holds what was logged."""
    label = TEMPLATE_CUT.split(FUNC_PREFIX.sub("", line), 1)[0]
    label = re.sub(r"\d+", "N", label)
    return label[:TEMPLATE_LABEL_LENGTH].rstrip() or "<no label>"


def overlaps(span, claimed) -> bool:
    return any(span[0] < end and start < span[1] for start, end in claimed)


def findings_in(message: str, harvested=None):
    """Yields the category of every unredacted sensitive value in one log entry.

    `harvested` collects personal-content values so a second pass can find them echoed by other
    log calls that no pattern recognises.
    """
    first_line = message.split("\n", 1)[0]
    if DUMP_PREFIXES.search(first_line):
        yield DUMP_CATEGORY
    claimed = []
    for category in CATEGORIES:
        for match in category.findings(message):
            span = match.span(category.value_group)
            if overlaps(span, claimed):
                continue
            claimed.append(span)
            if category.is_personal_content and harvested is not None:
                harvested.add(match.group(category.value_group).strip("\"'"))
            yield category.name


def entries(lines, since=None):
    """Groups a log's lines into entries: a timestamped line plus the untimestamped lines after it."""
    timestamp, message = None, []
    for raw in lines:
        line = raw.rstrip("\n")
        start = ENTRY_START.match(line)
        if start:
            if message and (since is None or timestamp >= since):
                yield "\n".join(message)
            timestamp = datetime.strptime(start.group(1), TIMESTAMP_FORMAT)
            message = [line[start.end():]]
        elif message:
            message.append(line)
    if message and (since is None or timestamp >= since):
        yield "\n".join(message)


def echo_pattern(harvested):
    values = sorted((value for value in harvested if len(value) >= MINIMUM_ECHO_LENGTH), key=len, reverse=True)
    return re.compile("|".join(re.escape(value) for value in values)) if values else None


def scan(sources, since=None) -> Report:
    """Scans each source (a callable returning an iterable of lines) twice: once for patterns,
    then for personal content found by the first pass reappearing in entries it did not flag."""
    report = Report()
    harvested = set()
    flagged = set()
    for source_index, source in enumerate(sources):
        for entry_index, message in enumerate(entries(source(), since)):
            report.entries_scanned += 1
            template = template_for(message.split("\n", 1)[0])
            for category in findings_in(message, harvested):
                report.add(category, template)
                flagged.add((source_index, entry_index))
    echoes = echo_pattern(harvested)
    if echoes is None:
        return report
    for source_index, source in enumerate(sources):
        for entry_index, message in enumerate(entries(source(), since)):
            if (source_index, entry_index) not in flagged and echoes.search(message):
                report.add(ECHO_CATEGORY, template_for(message.split("\n", 1)[0]))
    return report


def log_files(paths):
    if paths:
        return [Path(path) for path in paths]
    files = []
    for folder in DEFAULT_LOG_FOLDERS:
        if folder.is_dir():
            files.extend(sorted(folder.glob(LOG_FILE_GLOB)))
    return files


def file_source(path: Path):
    if str(path) == STDIN_PATH:
        # Scanned twice (patterns, then echoes), and standard input can only be read once.
        lines = sys.stdin.readlines()
        return lambda: lines

    def read_lines():
        with open(path, encoding="utf-8", errors="replace") as handle:
            yield from handle
    return read_lines


@dataclass
class HistoryReport:
    entries: int = 0
    too_old: int = 0
    in_future: int = 0
    oldest_minutes: float = 0.0

    @property
    def is_within_window(self) -> bool:
        return not self.too_old and not self.in_future


# A clock change or a slow export can stamp an entry a moment after the header.
HISTORY_CLOCK_SKEW_SECONDS = 60
HISTORY_ENTRY_START = re.compile(r"^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) ")


def check_history(lines):
    """Checks an exported browsing history (`logs/browsing-history.log`): every entry inside the
    window before its `# exported-at:` time. Returns None when the header is missing."""
    exported_at = None
    report = HistoryReport()
    stamps = []
    for raw in lines:
        line = raw.rstrip("\n")
        if line.startswith(HISTORY_EXPORTED_AT):
            exported_at = datetime.strptime(line[len(HISTORY_EXPORTED_AT):].strip(), TIMESTAMP_FORMAT)
            continue
        start = HISTORY_ENTRY_START.match(line)
        if start:
            stamps.append(datetime.strptime(start.group(1), TIMESTAMP_FORMAT))
    if exported_at is None:
        return None
    for stamp in stamps:
        report.entries += 1
        age = (exported_at - stamp).total_seconds()
        report.oldest_minutes = max(report.oldest_minutes, age / 60)
        if age > HISTORY_WINDOW_MINUTES * 60:
            report.too_old += 1
        if age < -HISTORY_CLOCK_SKEW_SECONDS:
            report.in_future += 1
    return report


def print_history_report(path: Path, report: HistoryReport) -> None:
    print(f"{path}: {report.entries} entries, oldest {report.oldest_minutes:.1f} min before export "
          f"(window {HISTORY_WINDOW_MINUTES} min)")
    if report.too_old:
        print(f"    {report.too_old} entries older than the window")
    if report.in_future:
        print(f"    {report.in_future} entries after the export time")


def check_history_files(paths) -> int:
    status = EXIT_CLEAN
    for path in paths:
        report = check_history(file_source(Path(path))())
        if report is None:
            print(f"{path}: no '{HISTORY_EXPORTED_AT.strip()}' header; not a browsing history export", file=sys.stderr)
            return EXIT_USAGE
        print_history_report(Path(path), report)
        if not report.is_within_window:
            status = EXIT_FOUND
    return status


def print_report(report: Report, show_templates: bool) -> None:
    print(f"entries scanned: {report.entries_scanned}")
    if report.is_clean:
        print("no blocking findings")
    for category, count in report.counts.most_common():
        print(f"{category}: {count}")
        if not show_templates:
            continue
        for template, template_count in report.templates[category].most_common():
            print(f"    {template_count:6d}  {template}")


def parse_arguments(argv):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("paths", nargs="*",
                        help="log files, or - for standard input (default: every Debug_Logs*.txt in the app's log folders)")
    parser.add_argument("--since", help=f"only entries at or after this time, e.g. {TIMESTAMP_EXAMPLE}")
    parser.add_argument("--templates", action="store_true",
                        help="also print where each finding comes from (the line's label, never the value)")
    parser.add_argument("--history", action="store_true",
                        help=f"treat the paths as exported browsing histories and check that every entry is within "
                             f"{HISTORY_WINDOW_MINUTES} minutes of the export")
    return parser.parse_args(argv)


def main(argv=None) -> int:
    arguments = parse_arguments(argv)
    if arguments.history:
        if not arguments.paths:
            print("--history needs the exported file(s), e.g. <report>/logs/browsing-history.log", file=sys.stderr)
            return EXIT_USAGE
        return check_history_files(arguments.paths)
    try:
        since = datetime.strptime(arguments.since, TIMESTAMP_FORMAT) if arguments.since else None
    except ValueError:
        print(f"--since must look like {TIMESTAMP_EXAMPLE}", file=sys.stderr)
        return EXIT_USAGE
    files = log_files(arguments.paths)
    if not files:
        print("no log files found", file=sys.stderr)
        return EXIT_USAGE
    report = scan([file_source(path) for path in files], since)
    print_report(report, arguments.templates)
    return EXIT_CLEAN if report.is_clean else EXIT_FOUND


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""Scan Focus Bear's on-disk data for plaintext secrets and personal data. See check-at-rest.sh."""
import argparse
import fnmatch
import mmap
import plistlib
import re
import sys
from dataclasses import dataclass
from pathlib import Path

UI_TEST_DOMAIN = "com.App.EarnYourScreentime.uitests"
UI_TEST_SUFFIX = ".uitests"
SHARED_SUITE_BASE = "TCUD568B3U.group.com.focusbear.fbmac"
CANARY_PREFIX = "UI test at-rest"
# Header, payload and signature, each long enough that ordinary base64 text doesn't match.
JWT_PATTERN = rb"eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}"
# Written by builds before the at-rest work; their presence alone is a finding.
LEGACY_SHARED_KEYS = {
    "kUserdefaultsSharedAccessToken",
    "kUserdefaultsSharedUserEmail",
    "kUserdefaultsSharedUserName",
    "kUserdefaultsSharedLeaderboardUsername",
}
# Logs keep titles and URLs on purpose (LogRedactor strips secrets only), so only secrets count there.
LOGS_FOLDER = "Logs"
SECRET_KINDS = {"jwt", "email", "legacy-key"}
DOMAIN_PLACEHOLDER = "{domain}"
ALLOW_ANY_KIND = "*"


@dataclass(frozen=True)
class Finding:
    path: str
    kind: str
    where: str = ""


JWT_SEGMENT_UTF16 = rb"(?:[A-Za-z0-9_-]\x00){8,}"
JWT_PATTERN_UTF16 = rb"e\x00y\x00J\x00" + JWT_SEGMENT_UTF16 + rb"\.\x00" + JWT_SEGMENT_UTF16 + rb"\.\x00" + JWT_SEGMENT_UTF16


def literal(text):
    """A text literal as UTF-8 and as UTF-16LE (WebKit local storage and some caches use the latter)."""
    utf8 = re.escape(text.encode())
    utf16 = b"".join(re.escape(bytes([byte])) + rb"\x00" for byte in text.encode("ascii"))
    return [utf8, utf16]


def compile_patterns(email, secrets_only):
    raw = {"jwt": [JWT_PATTERN, JWT_PATTERN_UTF16]}
    if email:
        raw["email"] = literal(email)
    if not secrets_only:
        raw["canary"] = literal(CANARY_PREFIX)
    return {kind: [re.compile(p, re.IGNORECASE if kind == "email" else 0) for p in variants]
            for kind, variants in raw.items()}


def kinds_in_bytes(data, patterns):
    return {kind for kind, compiled in patterns.items() if any(p.search(data) for p in compiled)}


def walk_plist(value, key_path, patterns, found):
    if isinstance(value, dict):
        for key, child in value.items():
            walk_plist(child, f"{key_path}/{key}", patterns, found)
    elif isinstance(value, list):
        for index, child in enumerate(value):
            walk_plist(child, f"{key_path}[{index}]", patterns, found)
    elif isinstance(value, str):
        for kind in kinds_in_bytes(value.encode("utf-8", "surrogatepass"), patterns):
            found.append((key_path, kind))
    elif isinstance(value, (bytes, bytearray)):
        # Data values (archived objects, nested plists) show up base64-encoded in `defaults export`.
        for kind in kinds_in_bytes(bytes(value), patterns):
            found.append((key_path, kind))
        try:
            walk_plist(plistlib.loads(bytes(value)), key_path, patterns, found)
        except Exception:
            pass


def scan_preferences(path, rel, patterns, check_legacy_keys):
    if not path.is_file():
        return []
    try:
        with path.open("rb") as handle:
            root = plistlib.load(handle)
    except Exception:
        return [Finding(rel, "unreadable-plist")]
    findings = []
    if check_legacy_keys:
        findings += [Finding(rel, "legacy-key", key) for key in sorted(LEGACY_SHARED_KEYS & set(root))]
    found = []
    walk_plist(root, "", patterns, found)
    # Report each top-level key once per kind; the key name is what a fix needs.
    top = sorted({(where.split("/")[1].split("[")[0] if where else "", kind) for where, kind in found})
    findings += [Finding(rel, kind, key) for key, kind in top]
    return findings


def scan_file(path, rel, patterns):
    try:
        if path.stat().st_size == 0:
            return []
        with path.open("rb") as handle, mmap.mmap(handle.fileno(), 0, access=mmap.ACCESS_READ) as data:
            return [Finding(rel, kind) for kind in sorted(kinds_in_bytes(data, patterns))]
    except (OSError, ValueError):
        return [Finding(rel, "unreadable")]


def scan_tree(root, home, patterns, secret_patterns):
    findings = []
    if not root.exists():
        return findings
    for path in sorted(p for p in root.rglob("*") if p.is_file() and not p.is_symlink()):
        rel = str(path.relative_to(home))
        in_logs = LOGS_FOLDER in path.relative_to(root).parts[:1]
        findings += scan_file(path, rel, secret_patterns if in_logs else patterns)
    return findings


def load_allowlist(path, domain):
    entries = []
    if not path or not Path(path).is_file():
        return entries
    for line in Path(path).read_text().splitlines():
        line = line.split("#", 1)[0].strip()
        if not line:
            continue
        glob, _, kind = line.rpartition(" ")
        entries.append((glob.strip().replace(DOMAIN_PLACEHOLDER, domain), kind.strip()))
    return entries


def is_allowed(finding, allowlist):
    return any(fnmatch.fnmatch(finding.path, glob) and kind in (finding.kind, ALLOW_ANY_KIND)
               for glob, kind in allowlist)


def scan(home, domain, email, secrets_only):
    patterns = compile_patterns(email, secrets_only)
    secret_patterns = {k: v for k, v in patterns.items() if k in SECRET_KINDS}
    library = home / "Library"
    suite = SHARED_SUITE_BASE + (UI_TEST_SUFFIX if domain.endswith(UI_TEST_SUFFIX) else "")
    findings = []
    for name, legacy in ((domain, False), (suite, True)):
        path = library / "Preferences" / f"{name}.plist"
        findings += scan_preferences(path, str(path.relative_to(home)), patterns, legacy)
    for folder in ("Application Support", "Caches", "WebKit", "HTTPStorages"):
        findings += scan_tree(library / folder / domain, home, patterns, secret_patterns)
    cookies = library / "HTTPStorages" / f"{domain}.binarycookies"
    if cookies.is_file():
        findings += scan_file(cookies, str(cookies.relative_to(home)), secret_patterns)
    return findings


def main(argv=None):
    parser = argparse.ArgumentParser(description="Scan Focus Bear's on-disk data for plaintext.")
    parser.add_argument("--domain", default=UI_TEST_DOMAIN, help="bundle id to scan")
    parser.add_argument("--secrets-only", action="store_true", help="look only for JWTs and --email")
    parser.add_argument("--email", help="an email address that must not appear in plaintext")
    parser.add_argument("--allowlist", help="known findings to tolerate: '<glob> <kind>' per line")
    parser.add_argument("--home", default=str(Path.home()), help="home folder to scan (tests use a fixture)")
    args = parser.parse_args(argv)

    if not args.domain.endswith(UI_TEST_SUFFIX) and not args.secrets_only:
        print("Refusing a full scan of a non-UI-test domain; add --secrets-only.", file=sys.stderr)
        return 2

    home = Path(args.home).expanduser()
    allowlist = load_allowlist(args.allowlist, args.domain)
    findings = scan(home, args.domain, args.email, args.secrets_only)
    allowed = [f for f in findings if is_allowed(f, allowlist)]
    violations = [f for f in findings if not is_allowed(f, allowlist)]

    for finding in violations:
        print(f"FOUND   {finding.kind:<12} {finding.path}" + (f"  [{finding.where}]" if finding.where else ""))
    for finding in allowed:
        print(f"allowed {finding.kind:<12} {finding.path}" + (f"  [{finding.where}]" if finding.where else ""))
    unused = [f"{glob} {kind}" for glob, kind in allowlist
              if not any(fnmatch.fnmatch(f.path, glob) and kind in (f.kind, ALLOW_ANY_KIND) for f in findings)]
    for entry in unused:
        print(f"note    allowlist entry matched nothing (ratchet it down?): {entry}")
    print(f"check-at-rest: {len(violations)} finding(s), {len(allowed)} allowed, domain {args.domain}"
          + (" (secrets only)" if args.secrets_only else ""))
    return 1 if violations else 0


if __name__ == "__main__":
    sys.exit(main())

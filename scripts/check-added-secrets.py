#!/usr/bin/env python3
"""Fail when a diff ADDS something that looks like an API key or private key.

Reads a unified `git diff` on stdin and inspects only added lines, so it gates new commits without
baselining history. An OpenAI project key shipped in the Mac binary from May to September 2026
(Mac-App#2732): anything compiled into the app can be read back with `strings`, so keys belong in the
backend's secret store and nowhere in this repo.

Findings name the file, line and rule, never the matched value, so the CI log does not republish a leak.
Suppress a deliberate fake (a test fixture) with a `secret-scan-ignore` comment on the line.

Usage:  git diff origin/BASE...HEAD | check-added-secrets.py
Exit:   0 = clean, 1 = possible secret(s) added.
"""
import re
import sys

SUPPRESS = "secret-scan-ignore"
HUNK_HEADER = re.compile(r"^@@ -\d+(?:,\d+)? \+(?P<start>\d+)(?:,\d+)? @@")

RULES = {
    # sk-…, sk-proj-…, sk-svcacct-…, sk-ant-… (Anthropic). The lookbehind skips words ending in "sk-" ("task-…").
    "OpenAI/Anthropic secret key": re.compile(r"(?<![A-Za-z0-9_-])sk-(?:proj-|svcacct-|admin-|ant-)?[A-Za-z0-9_-]{20,}"),
    "AWS access key id": re.compile(r"\b(?:AKIA|ASIA)[0-9A-Z]{16}\b"),
    "GitHub token": re.compile(r"\b(?:gh[pousr]_[A-Za-z0-9]{36,}|github_pat_[A-Za-z0-9_]{50,})"),
    "Slack token": re.compile(r"\bxox[abprs]-[A-Za-z0-9-]{10,}"),
    "Google API key": re.compile(r"\bAIza[0-9A-Za-z_-]{35}\b"),
    "Stripe live secret key": re.compile(r"\b(?:sk|rk)_live_[0-9A-Za-z]{20,}"),
    "SendGrid API key": re.compile(r"\bSG\.[A-Za-z0-9_-]{22}\.[A-Za-z0-9_-]{43}\b"),
    "Private key": re.compile(r"-----BEGIN (?:RSA |EC |DSA |OPENSSH |PGP |ENCRYPTED )?PRIVATE KEY"),
}


def added_lines(diff_text):
    """Yield (path, line_number, text) for every added line in a unified diff."""
    path = None
    line_number = 0
    for line in diff_text.splitlines():
        if line.startswith("+++ "):
            path = line[6:] if line.startswith("+++ b/") else None
            continue
        hunk = HUNK_HEADER.match(line)
        if hunk:
            line_number = int(hunk.group("start"))
            continue
        if line.startswith("+"):
            yield path, line_number, line[1:]
            line_number += 1
        elif not line.startswith("-"):
            line_number += 1


def findings(diff_text):
    for path, line_number, text in added_lines(diff_text):
        if path is None or SUPPRESS in text:
            continue
        for rule, pattern in RULES.items():
            if pattern.search(text):
                yield path, line_number, rule


def main():
    found = list(findings(sys.stdin.read()))
    if not found:
        print("✅ No secrets in the added lines.")
        return 0
    print(f"❌ {len(found)} possible secret(s) added. Keys belong in the backend secret store, never in this")
    print("   repo or the app binary. If one was pushed, treat it as leaked: revoke it, then remove it.")
    print(f"   For a deliberate fake (test fixture), add `{SUPPRESS}` to the line.\n")
    for path, line_number, rule in found:
        print(f"::error file={path},line={line_number}::Possible {rule} added (value not shown)")
    return 1


if __name__ == "__main__":
    sys.exit(main())

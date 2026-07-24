#!/usr/bin/env python3
"""Flag newly-added hardcoded user-facing English strings in Swift.

Reads a unified `git diff` on stdin and inspects only ADDED lines, so it gates new code
without needing to baseline the ~1300 pre-existing hardcoded strings in this legacy codebase.
User-facing text belongs in config.json (read via configjson), not hardcoded in Swift — a
hardcoded string never gets translated to Spanish.

Flags a string literal that is:
  * assigned to a UI-text sink   (.stringValue/.title/.placeholderString/.toolTip/.messageText/
    .informativeText/.label = "…"), or
  * a SwiftUI text literal        (Text("…"), Button("…"), .help("…")), or
  * an inline config fallback     (… ?? "…")

…when the literal looks like natural language. Ignores logging, identifiers/keys, URLs, SF
Symbols, resource/font names, and any line with a `// i18n-ignore` suppression comment.

Usage:  git diff origin/BASE...HEAD -- '*.swift' | check-hardcoded-strings.py
Exit:   0 = clean, 1 = hardcoded string(s) found, 2 = bad input.
"""
import re
import sys

SUPPRESS = "i18n-ignore"

# String literal captured into group "s". (Swift has no raw-string ambiguity for our simple cases.)
_LIT = r'"(?P<s>(?:[^"\\]|\\.)*)"'
SINKS = [
    re.compile(r'\.(?:stringValue|title|placeholderString|toolTip|informativeText|messageText|headerText|label|stringVal)\s*=\s*' + _LIT),
    re.compile(r'\b(?:Text|Button)\s*\(\s*' + _LIT),
    re.compile(r'\.help\(\s*' + _LIT),
    re.compile(r'addButton\(withTitle:\s*' + _LIT),
    re.compile(r'\?\?\s*' + _LIT),  # inline config fallback
]

# Lines that are never UI text.
LINE_EXCLUDE = re.compile(r'\b(?:addLog|print|NSLog|os_log|Logger|debugPrint|assert(?:ionFailure)?|fatalError|precondition)\s*\(')
# Argument positions where a literal is a key/identifier, not display text.
KEY_ARG = re.compile(r'(?:forKey|withIdentifier|forResource|ofType|named|systemSymbolName|accessibilityDescription|contentsOfFile|forHTTPHeaderField|identifier)\s*:\s*"$')


def is_natural_language(text):
    """Heuristic: real prose/labels, not identifiers/URLs/symbols/format-only strings."""
    if "://" in text or text.startswith("http"):
        return False
    # strip Swift interpolations so "\(x)" doesn't count as content
    stripped = re.sub(r'\\\([^)]*\)', "", text).strip()
    if len(stripped) < 3:
        return False
    letters = re.findall(r'[A-Za-z]', stripped)
    if len(letters) < 3:
        return False
    # An identifier / symbol token: no spaces and dot/underscore separated (e.g. music.note.list,
    # some_key, viewDidLoad) — treat as non-UI.
    if " " not in stripped and re.fullmatch(r'[A-Za-z0-9_.\-]+', stripped) and (("." in stripped) or ("_" in stripped) or stripped[:1].islower()):
        return False
    return True


def parse_added_lines(diff_text):
    """Yield (path, added_line_text) for every '+' line in the diff."""
    path = None
    for line in diff_text.splitlines():
        if line.startswith("+++ b/"):
            path = line[6:]
        elif line.startswith("+") and not line.startswith("+++"):
            yield path, line[1:]


def find_hits(path, line):
    if not path or not path.endswith(".swift"):
        return []
    if SUPPRESS in line or LINE_EXCLUDE.search(line):
        return []
    hits = []
    for pattern in SINKS:
        for m in pattern.finditer(line):
            # Skip literals that are actually key/identifier arguments.
            if KEY_ARG.search(line[:m.start("s")]):
                continue
            text = m.group("s")
            if is_natural_language(text):
                hits.append(text)
    return hits


def main():
    diff_text = sys.stdin.read()
    if not diff_text.strip():
        print("✅ No Swift changes to check.")
        return 0

    findings = []
    for path, line in parse_added_lines(diff_text):
        for text in find_hits(path, line):
            findings.append((path, text, line.strip()))

    if not findings:
        print("✅ No newly-added hardcoded user-facing strings.")
        return 0

    print(f"❌ {len(findings)} newly-added hardcoded string(s). Move user-facing text into")
    print("   config.json (read via configjson) so it can be translated, or append")
    print(f"   `// {SUPPRESS}` to the line if it is genuinely not user-facing.\n")
    for path, text, line in findings:
        print(f"::error file={path}::Hardcoded string {text!r} — put it in config.json (or add // {SUPPRESS}). Line: {line}")
    return 1


if __name__ == "__main__":
    sys.exit(main())

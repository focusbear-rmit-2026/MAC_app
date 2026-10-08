#!/usr/bin/env python3
"""Lint for SecureStore's registry. See check-sensitive-defaults.sh."""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REGISTRY = ROOT / "FocusBear/Security/SensitiveKeyRegistry.swift"
SOURCE_DIRS = [ROOT / "FocusBear", ROOT / "FBHelper"]
# The store itself and the facade are the only code that may hand a registered key to UserDefaults.
EXEMPT = {REGISTRY, ROOT / "FocusBear/Security/SecureStore.swift", ROOT / "FocusBear/Security/SensitiveDefaults.swift"}
# A registry constant named `<name>Base` holds the unsuffixed key of a global `<name>` that gets the
# user id appended at sign-in; call sites use `<name>`, so both spellings count.
BASE_SUFFIX = "Base"
KEY_ENTRY = re.compile(r"\.(exact|userSuffixed)\(\s*([A-Za-z_]\w*)([^\n]*)")
FILE_ENTRY = re.compile(r"SensitiveFile\(fileName:\s*([A-Za-z_]\w*|\"[^\"]+\")")
EXCLUDING = re.compile(r"excluding:\s*\[([^\]]*)\]")
DECLARATION = re.compile(r"\b(?:let|var)\s+([A-Za-z_]\w*)\s*=\s*\"([^\"]+)\"")
KEY_LITERAL = re.compile(r"\"(k[A-Z]\w+)\"")
# Plaintext file I/O: String/Data(contentsOf:), .write(to:), FileHandle(forWritingTo:), createFile(atPath:).
PLAINTEXT_FILE_IO = re.compile(
    r"(?:contentsOf:|\.write\(to:|forWritingTo:|forUpdating:|copyItem\(at:|createFile\(atPath:)\s*([A-Za-z_]\w*)")


def swift_files():
    for directory in SOURCE_DIRS:
        yield from directory.rglob("*.swift")


def registry_entries(text):
    entries = []
    for match in KEY_ENTRY.finditer(text):
        excluded = EXCLUDING.search(match.group(3))
        names = [n.strip() for n in excluded.group(1).split(",") if n.strip()] if excluded else []
        entries.append((match.group(1), match.group(2), names))
    return entries


def check_defaults(sources, entries):
    problems = []
    identifiers = set()
    for _, name, _ in entries:
        identifiers.add(name)
        if name.endswith(BASE_SUFFIX):
            identifiers.add(name[: -len(BASE_SUFFIX)])
    if not identifiers:
        return problems
    alternation = "|".join(sorted(identifiers))
    direct = re.compile(r"UserDefaults\.standard\.\w+\([^)]*forKey(?:Path)?:[^)]*\b(" + alternation + r")\b")
    for path, text in sources.items():
        if path in EXEMPT:
            continue
        for number, line in enumerate(text.splitlines(), 1):
            if direct.search(line):
                problems.append(f"{path.relative_to(ROOT)}:{number}: registered key through UserDefaults.standard "
                                f"(use SensitiveDefaults): {line.strip()}")
    return problems


def check_prefix_collisions(sources, entries):
    """A user-suffixed base also matches any other key that merely starts with it; such a key would be
    moved into SecureStore while its call sites still read UserDefaults. Each must be excluded or registered."""
    problems = []
    values, literals = {}, set()
    for text in sources.values():
        values.update({name: value for name, value in DECLARATION.findall(text)})
        literals.update(KEY_LITERAL.findall(text))
    registered_values = {values.get(name) for _, name, _ in entries}
    for kind, name, excluded in entries:
        if kind != "userSuffixed" or name not in values:
            continue
        base = values[name]
        excluded_values = {values.get(e, e) for e in excluded}
        for literal in sorted(literals):
            if literal != base and literal.startswith(base) and literal not in registered_values \
                    and not any(literal.startswith(e) for e in excluded_values):
                problems.append(f"registry: .userSuffixed({name}) also matches the unrelated key \"{literal}\"; "
                                f"exclude it or register it")
    return problems


def check_files(sources, registry_text):
    """A registered file's URL variable must only be read or written through SecureFiles."""
    problems = []
    values = {}
    for text in sources.values():
        values.update({name: value for name, value in DECLARATION.findall(text)})
    file_names = set()
    for match in FILE_ENTRY.finditer(registry_text):
        token = match.group(1)
        file_names.add(token.strip('"') if token.startswith('"') else values.get(token, token))
    url_variables = set()
    assignment = re.compile(r"\b(\w+)\s*(?::\s*URL\??)?\s*=\s*[^\n=]*appendingPathComponent\(\s*(\"[^\"]+\"|\w+)\s*\)")
    for text in sources.values():
        for match in assignment.finditer(text):
            token = match.group(2)
            name = token.strip('"') if token.startswith('"') else values.get(token)
            if name in file_names:
                url_variables.add(match.group(1))
    for path, text in sources.items():
        if path in EXEMPT or path.name == "SecureFileStore.swift":
            continue
        for number, line in enumerate(text.splitlines(), 1):
            for match in PLAINTEXT_FILE_IO.finditer(line):
                if match.group(1) in url_variables:
                    problems.append(f"{path.relative_to(ROOT)}:{number}: registered file {match.group(1)} read or "
                                    f"written in plaintext (use SecureFiles.shared): {line.strip()}")
    return problems, url_variables


def main():
    sources = {path: path.read_text() for path in swift_files()}
    registry_text = REGISTRY.read_text()
    entries = registry_entries(registry_text)
    problems = check_defaults(sources, entries) + check_prefix_collisions(sources, entries)
    file_problems, url_variables = check_files(sources, registry_text)
    problems += file_problems
    for problem in problems:
        print(problem)
    if problems:
        return 1
    print(f"check-sensitive-defaults: ok ({len(entries)} registered key(s), {len(url_variables)} registered file URL(s))")
    return 0


if __name__ == "__main__":
    sys.exit(main())

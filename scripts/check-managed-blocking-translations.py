#!/usr/bin/env python3
"""Validate the native managed-safety config and literal string references without building."""

import json
from pathlib import Path
import re
import sys


def flatten(value, prefix=""):
    result = {}
    for key, text in value.items():
        path = f"{prefix}.{key}" if prefix else key
        if isinstance(text, dict):
            result.update(flatten(text, path))
        else:
            result[path] = text
    return result


def main():
    root = Path(__file__).resolve().parents[1]
    english = json.loads((root / "FocusBear/config.json").read_text())["managedBlockingInfo"]
    spanish = json.loads((root / "FocusBear/config-es.json").read_text())["managedBlockingInfo"]
    en, es = flatten(english), flatten(spanish)
    errors = []
    if en.keys() != es.keys():
        errors.append(f"Missing Spanish keys: {sorted(en.keys() - es.keys())}; missing English keys: {sorted(es.keys() - en.keys())}")
    for key in en.keys() & es.keys():
        if not isinstance(en[key], str) or not isinstance(es[key], str) or not en[key].strip() or not es[key].strip():
            errors.append(f"Empty or non-string translation: {key}")
            continue
        tokens = r"<[A-Z_]+>|\{\d+\}"
        if sorted(re.findall(tokens, en[key])) != sorted(re.findall(tokens, es[key])):
            errors.append(f"Translation placeholders differ: {key}")
    reference = re.compile(r'(?:ManagedBlockingText\.value|\btext)\("([^"\n]+)"\s*,')
    folders = [root / "FocusBear/ManagedBlocking", root / "FocusBear/Preferences/BlockLists"]
    for folder in folders:
        for source in folder.glob("*.swift"):
            for key in reference.findall(source.read_text()):
                if key not in english or key not in spanish:
                    errors.append(f"{source.relative_to(root)} references missing managedBlockingInfo.{key}")
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print(f"Managed safety translations: {len(en)} non-empty English/Spanish entries; keys, placeholders and literal references match.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""Fail if the local Mac-App config.json has user-facing string keys that are missing
from the assets repo's config.json (the source the Spanish translation is derived from).

This is the guardrail for the recurring bug where a new string is added to
FocusBear/config.json but never propagated to the assets repo, so Spanish users get the
English fallback. The assets repo's own CI enforces English<->Spanish parity, so it's
enough to check that every local string key also exists in the assets English config.

Usage:
    check-config-assets-sync.py <local_config.json> <assets_config.json> [ignore_file]

Exit codes: 0 = in sync (or all drift is ignored), 1 = drift found, 2 = bad input.
"""
import json
import sys


def leaf_keys(node, prefix=""):
    """Flatten a nested dict into {dotted.path: string_value} for every string leaf."""
    out = {}
    if isinstance(node, dict):
        for key, value in node.items():
            out.update(leaf_keys(value, f"{prefix}.{key}" if prefix else key))
    elif isinstance(node, str):
        out[prefix] = node
    return out


def load(path):
    try:
        with open(path, encoding="utf-8") as handle:
            return json.load(handle)
    except (OSError, json.JSONDecodeError) as err:
        print(f"::error::Could not read/parse {path}: {err}")
        sys.exit(2)


def main(argv):
    if not (3 <= len(argv) <= 4):
        print(__doc__)
        return 2

    local_path, assets_path = argv[1], argv[2]
    ignore = set()
    if len(argv) == 4:
        try:
            with open(argv[3], encoding="utf-8") as handle:
                ignore = {
                    line.strip() for line in handle
                    if line.strip() and not line.startswith("#")
                }
        except OSError:
            pass  # ignore file is optional

    local = leaf_keys(load(local_path))
    assets = leaf_keys(load(assets_path))

    missing = sorted(k for k in local if k not in assets and k not in ignore)

    if not missing:
        print(f"✅ All {len(local)} local config strings are present in the assets repo.")
        return 0

    print(f"❌ {len(missing)} string(s) in {local_path} are missing from {assets_path}.")
    print("   Add them (with a Spanish translation) to the assets repo's")
    print("   config/config.json + config/config-es.json before merging.\n")
    for key in missing:
        # A GitHub Actions annotation so each one shows up in the PR checks UI.
        print(f"::error::Missing in assets repo: {key} = {local[key]!r}")
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))

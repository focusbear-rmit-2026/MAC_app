#!/bin/bash
# Fail when app code reads or writes a SecureStore-registered key through UserDefaults.standard, when a
# user-suffixed registry entry would swallow an unrelated key that shares its prefix, or when a
# registered file (SensitiveFile) is read or written in plaintext instead of through SecureFiles.
#
# Registered keys are the constants passed to `.exact(` / `.userSuffixed(` in
# FocusBear/Security/SensitiveKeyRegistry.swift. Their call sites must use SensitiveDefaults, or the
# value lands back in the plaintext preferences plist.
set -euo pipefail
exec python3 "$(dirname "$0")/check_sensitive_defaults.py"

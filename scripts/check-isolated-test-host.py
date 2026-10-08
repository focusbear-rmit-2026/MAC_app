#!/usr/bin/env python3
"""Fail before xcodebuild if app-hosted logic tests could start the normal desktop app.

This structural preflight protects a self-hosted workstation from older PR branches that
lack the isolated XCTest host. The native LogicTestHostTests still verify runtime behavior.
It reads source/scheme files only; it never loads the app or queries the keychain.
"""
from pathlib import Path
import re
import sys
import xml.etree.ElementTree as ET


def check(root: Path) -> list[str]:
    errors = []
    try:
        source = (root / "FocusBear/AppDelegate.swift").read_text()
        scheme = ET.parse(root / "FocusBear.xcodeproj/xcshareddata/xcschemes/Focus Bear.xcscheme").getroot()
        workflow = (root / ".github/workflows/unit-tests.yml").read_text()
    except (OSError, ET.ParseError) as error:
        return [f"Cannot verify isolated test host: {error}"]

    # Ignore documentation-only lines. Keep guards at the start of each entry point: a late
    # guard would still allow startup/keychain work before XCTest takes control.
    code = re.sub(r"(?m)^\s*//[^\n]*", "", source)
    compact = re.sub(r"\s+", "", code)
    required = [
        "enumLogicTestHost{",
        'isDebug&&hasXCTest&&environment["FOCUSBEAR_LOGIC_TEST_HOST"]=="1"',
        'hasXCTest:NSClassFromString("XCTestCase")!=nil,isDebug:true',
        "staticvarisEnabled:Bool{#ifDEBUG",
    ]
    if not all(part in compact for part in required):
        errors.append("The Debug-only, explicit-flag + XCTest LogicTestHost implementation is missing or changed.")
    starts = {
        "applicationWillFinishLaunching": r"if\s+LogicTestHost\.isEnabled\s*\{\s*LogicTestHost\.loadBundledConfiguration\(\)\s*return\s*\}",
        "applicationDidFinishLaunching": r"guard\s+!LogicTestHost\.isEnabled\s+else\s*\{\s*return\s*\}",
        "setCredentialAndUserInfo": r"guard\s+!LogicTestHost\.isEnabled\s+else\s*\{\s*return\s*\}",
    }
    for name, start in starts.items():
        if not re.search(r"(?m)^\s*func\s+" + name + r"\b[^\{]*\{\s*" + start, code):
            errors.append(f"{name} must return through the isolated-host guard before normal app work.")

    action = scheme.find("TestAction")
    if action is None:
        errors.append("The shared scheme has no TestAction.")
    else:
        if action.get("buildConfiguration") != "Debug":
            errors.append("Logic tests must use the Debug configuration.")
        if action.get("shouldUseLaunchSchemeArgsEnv") != "NO":
            errors.append("TestAction must use its own isolated environment, not LaunchAction's environment.")
        flags = action.findall('./EnvironmentVariables/EnvironmentVariable[@key="FOCUSBEAR_LOGIC_TEST_HOST"]')
        if len(flags) != 1 or flags[0].get("value") != "1" or flags[0].get("isEnabled") != "YES":
            errors.append("TestAction must explicitly enable FOCUSBEAR_LOGIC_TEST_HOST=1.")
    for flag in scheme.findall('./LaunchAction/EnvironmentVariables/EnvironmentVariable[@key="FOCUSBEAR_LOGIC_TEST_HOST"]'):
        if flag.get("isEnabled") == "YES":
            errors.append("Normal LaunchAction must not enable the isolated test host.")
    if not (root / "FocusBearTests/LogicTestHostTests.swift").is_file():
        errors.append("The native isolated-host regression suite is missing.")
    if '-only-testing:"Focus BearTests/LogicTestHostTests"' not in workflow:
        errors.append("The workflow must execute LogicTestHostTests.")
    configurations = re.findall(r"-configuration\s+[\"']?([A-Za-z0-9_-]+)", workflow)
    if not configurations or any(value != "Debug" for value in configurations):
        errors.append("Every xcodebuild command must explicitly use Debug; command-line configuration overrides the scheme.")
    return errors


if __name__ == "__main__":
    problems = check(Path(sys.argv[1]) if len(sys.argv) > 1 else Path.cwd())
    for problem in problems:
        print(f"::error::{problem}")
    if problems:
        print("Refusing to launch app-hosted tests. Bring in the isolated test-host prerequisite first.")
        raise SystemExit(1)
    print("Isolated logic test host verified before app launch.")

#!/usr/bin/env python3
"""Verify built logic-test artifacts without launching an app or accessing preferences."""

import argparse
import plistlib
from pathlib import Path
import sys

EXPECTED_BUNDLE_IDENTIFIER = "com.App.EarnYourScreentime.logictests"
LOGIC_HOST_FLAG = "FOCUSBEAR_LOGIC_TEST_HOST"
ENABLED_VALUE = "1"
APP_RELATIVE_PATH = Path("Debug/Focus Bear.app")
METADATA_KEY = "__xctestrun_metadata__"
TEST_ROOT_PLACEHOLDER = "__TESTROOT__"
SUPPORTED_FORMAT_VERSIONS = (1, 2)


def read_plist(path):
    with path.open("rb") as stream:
        value = plistlib.load(stream)
    if not isinstance(value, dict):
        raise ValueError(f"Expected a dictionary plist: {path}")
    return value


def enabled_targets(manifest):
    metadata = manifest.get(METADATA_KEY)
    if not isinstance(metadata, dict):
        raise ValueError("Missing xctestrun format metadata")
    version = metadata.get("FormatVersion")
    if type(version) is not int or version not in SUPPORTED_FORMAT_VERSIONS:
        raise ValueError(f"Unsupported xctestrun format: {version!r}")
    if version == 1:
        targets = [value for key, value in manifest.items() if key != METADATA_KEY]
    else:
        configurations = manifest.get("TestConfigurations")
        if not isinstance(configurations, list) or not configurations:
            raise ValueError("Missing test configurations")
        targets = []
        for configuration in configurations:
            if not isinstance(configuration, dict):
                raise ValueError("Invalid test configuration")
            enabled = configuration.get("IsEnabled", True)
            if type(enabled) is not bool:
                raise ValueError("Invalid configuration enabled flag")
            if not enabled:
                continue
            configuration_targets = configuration.get("TestTargets")
            if not isinstance(configuration_targets, list) or not configuration_targets:
                raise ValueError("Missing targets in enabled test configuration")
            targets.extend(configuration_targets)
    if not targets:
        raise ValueError("No enabled logic-test targets")
    for target in targets:
        if not isinstance(target, dict):
            raise ValueError("Invalid test target")
        # Inspect every target, including targets filtered by -only-testing. A later selector
        # change must not turn a previously unchecked shipping host into a runnable target.
        yield target


def verify_target(target, products_directory, expected_app):
    if target.get("TestHostBundleIdentifier") != EXPECTED_BUNDLE_IDENTIFIER:
        raise ValueError("Test manifest does not identify the isolated logic-test host")
    if target.get("IsUITestBundle", False) is not False:
        raise ValueError("UI-test targets are not allowed in the logic-test manifest")
    environment = target.get("EnvironmentVariables")
    if not isinstance(environment, dict) or environment.get(LOGIC_HOST_FLAG) != ENABLED_VALUE:
        raise ValueError("Test manifest must enable the isolated logic host")
    raw_path = target.get("TestHostPath")
    if not isinstance(raw_path, str) or not raw_path:
        raise ValueError("Missing test-host path")
    expanded_path = raw_path.replace(TEST_ROOT_PLACEHOLDER, str(products_directory))
    if "__" in expanded_path or not Path(expanded_path).is_absolute():
        raise ValueError("Unresolved or relative test-host path")
    if Path(expanded_path).resolve(strict=True) != expected_app:
        raise ValueError("Test manifest points to a different host application")


def verify_products(products_directory):
    products_directory = Path(products_directory).resolve(strict=True)
    manifests = list(products_directory.glob("*.xctestrun"))
    if len(manifests) != 1:
        raise ValueError(f"Expected exactly one generated xctestrun, found {len(manifests)}")
    manifest_path = manifests[0].resolve(strict=True)
    if manifest_path.parent != products_directory:
        raise ValueError("Test manifest escapes the dedicated products directory")
    expected_app = (products_directory / APP_RELATIVE_PATH).resolve(strict=True)
    if not expected_app.is_relative_to(products_directory):
        raise ValueError("Test host escapes the dedicated products directory")
    info = read_plist(expected_app / "Contents/Info.plist")
    if info.get("CFBundleIdentifier") != EXPECTED_BUNDLE_IDENTIFIER:
        raise ValueError("Built application does not have the isolated logic-test bundle identifier")
    if "CFBundleURLTypes" in info:
        raise ValueError("Isolated logic-test app must not register URL handlers")
    for target in enabled_targets(read_plist(manifest_path)):
        verify_target(target, products_directory, expected_app)
    return manifest_path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--products-directory", required=True, type=Path)
    arguments = parser.parse_args()
    try:
        manifest = verify_products(arguments.products_directory)
    except (OSError, ValueError, plistlib.InvalidFileException) as error:
        print(f"Logic-test host preflight refused: {error}", file=sys.stderr)
        return 1
    # The caller runs exactly this manifest, never a separately discovered or default host.
    print(manifest)
    return 0


if __name__ == "__main__":
    sys.exit(main())

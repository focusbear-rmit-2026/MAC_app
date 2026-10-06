#!/usr/bin/env python3
"""Synthetic artifact fixtures only: no app launches, credentials, or preference access."""

import importlib.util
import os
from pathlib import Path
import plistlib
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).with_name("verify-logic-test-host.py")
sys.dont_write_bytecode = True
SPEC = importlib.util.spec_from_file_location("verify_logic_test_host", SCRIPT)
VERIFY = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(VERIFY)
SHIPPING_BUNDLE_IDENTIFIER = "com.App.EarnYourScreentime"


class LogicTestHostIsolationTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="logic__artifacts_")
        self.addCleanup(self.temporary.cleanup)
        self.products = Path(self.temporary.name) / "Build/Products"
        self.app = self.products / VERIFY.APP_RELATIVE_PATH
        self.info_path = self.app / "Contents/Info.plist"
        self.info_path.parent.mkdir(parents=True)
        self.manifest_path = self.products / "Focus Bear_macosx-arm64.xctestrun"
        self.info = {"CFBundleIdentifier": VERIFY.EXPECTED_BUNDLE_IDENTIFIER}
        self.target = {
            "TestHostPath": "__TESTROOT__/Debug/Focus Bear.app",
            "TestHostBundleIdentifier": VERIFY.EXPECTED_BUNDLE_IDENTIFIER,
            "EnvironmentVariables": {VERIFY.LOGIC_HOST_FLAG: VERIFY.ENABLED_VALUE},
        }
        self.manifest = {
            VERIFY.METADATA_KEY: {"FormatVersion": 1},
            "Focus BearTests": self.target,
        }

    def write(self):
        self.info_path.write_bytes(plistlib.dumps(self.info))
        self.manifest_path.write_bytes(plistlib.dumps(self.manifest))

    def verify(self):
        self.write()
        return VERIFY.verify_products(self.products)

    def assert_refused(self):
        with self.assertRaises((ValueError, OSError, plistlib.InvalidFileException)):
            self.verify()

    def test_accepts_current_format_one(self):
        self.assertEqual(self.verify(), self.manifest_path.resolve())

    def test_accepts_format_two(self):
        self.manifest = {
            VERIFY.METADATA_KEY: {"FormatVersion": 2},
            "TestConfigurations": [{"IsEnabled": True, "TestTargets": [self.target]}],
        }
        self.assertEqual(self.verify(), self.manifest_path.resolve())

    def test_rejects_shipping_app_even_if_manifest_claims_isolation(self):
        self.info["CFBundleIdentifier"] = SHIPPING_BUNDLE_IDENTIFIER
        self.assert_refused()

    def test_rejects_shipping_manifest_even_if_app_is_isolated(self):
        self.target["TestHostBundleIdentifier"] = SHIPPING_BUNDLE_IDENTIFIER
        self.assert_refused()

    def test_rejects_missing_bundle_identifiers(self):
        del self.info["CFBundleIdentifier"]
        self.assert_refused()

    def test_rejects_url_handlers_even_if_empty(self):
        self.info["CFBundleURLTypes"] = []
        self.assert_refused()

    def test_rejects_missing_or_disabled_logic_flag(self):
        for environment in [{}, {VERIFY.LOGIC_HOST_FLAG: "0"}, {VERIFY.LOGIC_HOST_FLAG: 1}]:
            with self.subTest(environment=environment):
                self.target["EnvironmentVariables"] = environment
                self.assert_refused()

    def test_rejects_unknown_or_missing_manifest_format(self):
        for metadata in [{}, {"FormatVersion": 3}, {"FormatVersion": "1"}]:
            with self.subTest(metadata=metadata):
                self.manifest[VERIFY.METADATA_KEY] = metadata
                self.assert_refused()

    def test_rejects_another_host_path(self):
        self.target["TestHostPath"] = str(self.products)
        self.assert_refused()

    def test_rejects_relative_or_unresolved_paths(self):
        for path in ["Debug/Focus Bear.app", "__OTHERROOT__/Debug/Focus Bear.app", ""]:
            with self.subTest(path=path):
                self.target["TestHostPath"] = path
                self.assert_refused()

    def test_accepts_absolute_path_to_verified_host(self):
        self.target["TestHostPath"] = str(self.app)
        self.assertEqual(self.verify(), self.manifest_path.resolve())

    def test_accepts_double_underscores_in_absolute_artifact_path(self):
        self.target["TestHostPath"] = str(self.app.resolve())
        self.assertIn("logic__artifacts_", self.target["TestHostPath"])
        self.assertEqual(self.verify(), self.manifest_path.resolve())

    def test_rejects_absolute_path_with_unresolved_macro(self):
        self.target["TestHostPath"] = str(self.products / "__TESTHOST__" / "Focus Bear.app")
        self.assert_refused()

    def test_rejects_additional_shipping_target(self):
        self.manifest["AnotherTarget"] = dict(self.target, TestHostBundleIdentifier=SHIPPING_BUNDLE_IDENTIFIER)
        self.assert_refused()

    def test_rejects_ui_test_target(self):
        self.target["IsUITestBundle"] = True
        self.assert_refused()

    def test_rejects_empty_manifest(self):
        del self.manifest["Focus BearTests"]
        self.assert_refused()

    def test_rejects_empty_or_malformed_format_two(self):
        for configurations in [[], [{}], [{"IsEnabled": False}], [{"TestTargets": "wrong"}]]:
            with self.subTest(configurations=configurations):
                self.manifest = {VERIFY.METADATA_KEY: {"FormatVersion": 2},
                                 "TestConfigurations": configurations}
                self.assert_refused()

    def test_rejects_multiple_manifests(self):
        self.write()
        (self.products / "stale.xctestrun").write_bytes(self.manifest_path.read_bytes())
        with self.assertRaises(ValueError):
            VERIFY.verify_products(self.products)

    def test_rejects_missing_manifest(self):
        with self.assertRaises(ValueError):
            VERIFY.verify_products(self.products)

    def test_rejects_symlink_to_external_host(self):
        self.write()
        external = Path(self.temporary.name) / "external.app"
        self.app.rename(external)
        self.app.symlink_to(external, target_is_directory=True)
        with self.assertRaises(ValueError):
            VERIFY.verify_products(self.products)

    def test_cli_prints_only_selected_manifest(self):
        self.write()
        result = subprocess.run([sys.executable, str(SCRIPT), "--products-directory", str(self.products)],
                                text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), str(self.manifest_path.resolve()))

    def test_cli_fails_before_any_test_launch(self):
        self.info["CFBundleIdentifier"] = SHIPPING_BUNDLE_IDENTIFIER
        self.write()
        result = subprocess.run([sys.executable, str(SCRIPT), "--products-directory", str(self.products)],
                                text=True, capture_output=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")
        self.assertIn("preflight refused", result.stderr)


class IsolatedURLSchemeTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.info_path = self.root / "Test.app/Contents/Info.plist"
        self.info_path.parent.mkdir(parents=True)
        self.info_path.write_bytes(plistlib.dumps({
            "CFBundleIdentifier": VERIFY.EXPECTED_BUNDLE_IDENTIFIER,
            "CFBundleURLTypes": [{"CFBundleURLSchemes": ["focusbear"]}],
        }))

    def strip(self, suffix):
        environment = dict(os.environ, FB_BUNDLE_ID_SUFFIX=suffix,
                           TARGET_BUILD_DIR=str(self.root),
                           INFOPLIST_PATH="Test.app/Contents/Info.plist")
        return subprocess.run(["bash", str(SCRIPT.with_name("strip-isolated-test-url-schemes.sh"))],
                              env=environment, text=True, capture_output=True)

    def test_isolated_host_loses_url_handlers_and_keeps_identifier(self):
        result = self.strip(".logictests")
        self.assertEqual(result.returncode, 0, result.stderr)
        info = plistlib.loads(self.info_path.read_bytes())
        self.assertNotIn("CFBundleURLTypes", info)
        self.assertEqual(info["CFBundleIdentifier"], VERIFY.EXPECTED_BUNDLE_IDENTIFIER)
        self.assertEqual(self.strip(".logictests").returncode, 0)

    def test_normal_build_is_unchanged(self):
        original = self.info_path.read_bytes()
        result = self.strip("")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.info_path.read_bytes(), original)


if __name__ == "__main__":
    unittest.main()

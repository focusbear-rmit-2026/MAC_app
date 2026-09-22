import importlib.util
from pathlib import Path
import sys
import tempfile
import unittest


sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("preflight", HERE / "check-isolated-test-host.py")
preflight = importlib.util.module_from_spec(spec)
spec.loader.exec_module(preflight)
SOURCE = "FocusBear/AppDelegate.swift"
SCHEME = "FocusBear.xcodeproj/xcshareddata/xcschemes/Focus Bear.xcscheme"


class IsolatedTestHostPreflightTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        for name in [SOURCE, SCHEME, ".github/workflows/unit-tests.yml", "FocusBearTests/LogicTestHostTests.swift"]:
            target = self.root / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text((HERE.parent / name).read_text())

    def replace(self, path, old, new):
        target = self.root / path
        text = target.read_text()
        self.assertIn(old, text)
        target.write_text(text.replace(old, new))

    def test_current_isolated_host_passes_without_launching_anything(self):
        self.assertEqual(preflight.check(self.root), [])

    def test_legacy_pr_without_host_is_rejected_before_app_launch(self):
        (self.root / SOURCE).write_text("class AppDelegate { func applicationWillFinishLaunching() { startNormalApp() } }")
        self.assertTrue(preflight.check(self.root))

    def test_disabled_or_inherited_test_environment_is_rejected(self):
        original = (self.root / SCHEME).read_text()
        for old, new in [('value = "1"', 'value = "0"'),
                         ('shouldUseLaunchSchemeArgsEnv = "NO"', 'shouldUseLaunchSchemeArgsEnv = "YES"'),
                         ('buildConfiguration = "Debug"', 'buildConfiguration = "Release"')]:
            with self.subTest(change=old):
                (self.root / SCHEME).write_text(original.replace(old, new, 1))
                self.assertTrue(preflight.check(self.root))

    def test_guard_must_precede_normal_startup_and_credential_callbacks(self):
        original = (self.root / SOURCE).read_text()
        for old, new in [('if LogicTestHost.isEnabled {', 'startNormalApp()\n        if LogicTestHost.isEnabled {'),
                         ('guard !LogicTestHost.isEnabled else { return }', 'readCredentials()\n        guard !LogicTestHost.isEnabled else { return }')]:
            with self.subTest(change=old):
                (self.root / SOURCE).write_text(original.replace(old, new))
                self.assertTrue(preflight.check(self.root))

    def test_runtime_regression_suite_cannot_be_silently_omitted(self):
        self.replace('.github/workflows/unit-tests.yml', '-only-testing:"Focus BearTests/LogicTestHostTests"', '')
        self.assertTrue(preflight.check(self.root))

    def test_workflow_cannot_override_the_debug_scheme_with_release(self):
        self.replace('.github/workflows/unit-tests.yml', '-configuration Debug', '-configuration Release')
        self.assertTrue(preflight.check(self.root))


if __name__ == "__main__":
    unittest.main()

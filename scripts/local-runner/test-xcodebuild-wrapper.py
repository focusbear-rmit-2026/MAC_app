import contextlib
import importlib.machinery
import importlib.util
import io
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent


def load(name, path):
    loader = importlib.machinery.SourceFileLoader(name, str(path))
    spec = importlib.util.spec_from_loader(name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


wrapper = load("wrapper", HERE / "xcodebuild")
trusted = load("trusted", HERE.parent / "check-isolated-test-host.py")
CI = {"GITHUB_ACTIONS": "true", "GITHUB_REPOSITORY": "Focus-Bear/Mac-App"}
ARGS = ["test", "-workspace", "FocusBear.xcworkspace", "-scheme", "Focus Bear", "-configuration", "Debug"]


class RunnerWrapperTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="Focus Bear runner tests ")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.checkout = self.root / "actual checkout"
        self.checkout.mkdir()
        subprocess.run(["/usr/bin/git", "init", "-q", str(self.checkout)], check=True)
        (self.checkout / "FocusBear.xcworkspace").mkdir()
        for name in ["FocusBear/AppDelegate.swift", "FocusBear.xcodeproj/xcshareddata/xcschemes/Focus Bear.xcscheme",
                     "FocusBearTests/LogicTestHostTests.swift", ".github/workflows/unit-tests.yml"]:
            target = self.checkout / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text((HERE.parent.parent / name).read_text())
        self.executed = []
        self.checked = []

    def invoke(self, arguments=ARGS, environment=None, cwd=None, preflight=None):
        def check(root):
            self.checked.append(root)
            return trusted.check(root) == []
        with contextlib.redirect_stderr(io.StringIO()):
            return wrapper.run(arguments, CI if environment is None else environment,
                               cwd or self.checkout, self.executed.append, preflight or check)

    def test_verified_checkout_runs_absolute_tool_with_every_original_argument(self):
        arguments = ARGS + ["-resultBundlePath", "result with spaces.xcresult", "CODE_SIGN_IDENTITY=Apple Development: Test", "-only-testing:Focus BearTests/LogicTestHostTests"]
        self.assertEqual(self.invoke(arguments), 0)
        self.assertEqual(self.checked, [self.checkout])
        self.assertEqual(self.executed, [["/usr/bin/xcodebuild"] + arguments])

    def test_old_checkout_cannot_launch_even_when_it_supplies_a_fake_passing_preflight(self):
        (self.checkout / "FocusBear/AppDelegate.swift").write_text("func applicationWillFinishLaunching() { readCredentials() }")
        fake = self.checkout / "scripts/check-isolated-test-host.py"
        fake.parent.mkdir()
        fake.write_text("raise SystemExit(0)")
        self.assertEqual(self.invoke(), 78)
        self.assertEqual(self.executed, [])

    def test_other_repositories_non_ci_and_non_test_calls_pass_through_unchanged(self):
        for environment, arguments in [({**CI, "GITHUB_REPOSITORY": "Other/Repo"}, ARGS),
                                       ({"GITHUB_REPOSITORY": "Focus-Bear/Mac-App"}, ARGS),
                                       (CI, ["-version"]), (CI, ["build", "-scheme", "test"]),
                                       (CI, ["build", "-resultBundlePath", "test"])]:
            with self.subTest(arguments=arguments, environment=environment):
                self.assertEqual(self.invoke(arguments, environment), 0)
                self.assertEqual(self.executed[-1], ["/usr/bin/xcodebuild"] + arguments)
        self.assertEqual(self.checked, [])

    def test_release_wrong_scheme_duplicates_and_host_overrides_are_rejected(self):
        cases = [ARGS[:-1] + ["Release"], ARGS + ["-configuration", "Debug"],
                 ARGS + ["-scheme", "Other"], ARGS + ["-xcconfig", "override.xcconfig"],
                 ARGS + ["SWIFT_ACTIVE_COMPILATION_CONDITIONS="], ARGS + ["TEST_HOST=Other.app"],
                 ARGS + ["SWIFT_ACTIVE_COMPILATION_CONDITIONS[arch=arm64]="],
                 ARGS + ["OTHER_SWIFT_FLAGS=-UDEBUG"], ARGS + ["-testPlan", "Other"]]
        for arguments in cases:
            with self.subTest(arguments=arguments):
                self.assertEqual(self.invoke(arguments), 78)
        self.assertEqual(self.executed, [])

    def test_prebuilt_hosts_are_rejected_even_with_current_isolated_source(self):
        for arguments in [["test-without-building"] + ARGS[1:], ARGS + ["-xctestrun", "old.xctestrun"]]:
            self.assertEqual(self.invoke(arguments), 78)
        self.assertEqual(self.executed, [])

    def test_actual_workspace_checkout_wins_over_github_workspace_or_cwd(self):
        elsewhere = self.root / "stale checkout"
        elsewhere.mkdir()
        arguments = ARGS.copy()
        arguments[2] = str(self.checkout / "FocusBear.xcworkspace")
        self.assertEqual(self.invoke(arguments, {**CI, "GITHUB_WORKSPACE": str(elsewhere)}, elsewhere), 0)
        self.assertEqual(self.checked, [self.checkout])

    def test_symlinked_workspace_resolves_actual_checkout_and_foreign_workspace_is_rejected(self):
        alias = self.root / "workspace alias"
        alias.symlink_to(self.checkout / "FocusBear.xcworkspace")
        arguments = ARGS.copy(); arguments[2] = str(alias)
        self.assertEqual(self.invoke(arguments), 0)
        self.assertEqual(self.checked, [self.checkout])
        foreign = self.checkout / "Other.xcworkspace"; foreign.mkdir()
        arguments[2] = str(foreign)
        self.assertEqual(self.invoke(arguments), 78)
        self.assertEqual(len(self.executed), 1)

    def test_project_selector_and_root_cwd_are_supported_but_ambiguous_subdirectory_is_not(self):
        arguments = ARGS.copy(); arguments[1:3] = ["-project", "FocusBear.xcodeproj"]
        self.assertEqual(self.invoke(arguments), 0)
        self.assertEqual(self.invoke(["test", "-scheme", "Focus Bear", "-configuration", "Debug"]), 0)
        self.assertEqual(self.invoke(["test", "-scheme", "Focus Bear", "-configuration", "Debug"], cwd=self.checkout / "FocusBear"), 78)
        self.assertEqual(self.invoke(ARGS + ["-project", "FocusBear.xcodeproj"]), 78)

    def test_missing_paths_or_missing_option_values_never_reach_xcodebuild(self):
        for arguments in [ARGS[:2] + ["missing.xcworkspace"] + ARGS[3:], ARGS + ["-project"], ["test", "-scheme"]]:
            self.assertEqual(self.invoke(arguments), 78)
        self.assertEqual(self.executed, [])

    def test_inherited_config_or_disabled_host_environment_cannot_override_the_scheme(self):
        for override in [{"XCODE_XCCONFIG_FILE": "override.xcconfig"}, {"FOCUSBEAR_LOGIC_TEST_HOST": "0"},
                         {"TEST_RUNNER_FOCUSBEAR_LOGIC_TEST_HOST": "0"}]:
            self.assertEqual(self.invoke(environment={**CI, **override}), 78)
        self.assertEqual(self.executed, [])

    def test_default_preflight_uses_trusted_absolute_script_isolated_python_and_actual_root(self):
        completed = subprocess.CompletedProcess([], 0)
        with mock.patch.object(wrapper, "validate_invocation", return_value=self.checkout), mock.patch.object(wrapper.subprocess, "run", return_value=completed) as run:
            status = wrapper.run(ARGS, CI, self.checkout, self.executed.append)
        self.assertEqual(status, 0)
        self.assertEqual(run.call_args.args[0], ["/usr/bin/python3", "-I", str(wrapper.TRUSTED_PREFLIGHT), str(self.checkout)])
        self.assertEqual(wrapper.TRUSTED_PREFLIGHT, HERE.parent / "check-isolated-test-host.py")

    def test_default_preflight_failure_or_missing_trusted_copy_fails_closed(self):
        with mock.patch.object(wrapper, "validate_invocation", return_value=self.checkout), mock.patch.object(wrapper.subprocess, "run", return_value=subprocess.CompletedProcess([], 1)):
            self.assertEqual(wrapper.run(ARGS, CI, self.checkout, self.executed.append), 78)
        with mock.patch.object(wrapper, "TRUSTED_PREFLIGHT", self.root / "missing.py"):
            self.assertEqual(wrapper.run(ARGS, CI, self.checkout, self.executed.append), 78)
        self.assertEqual(self.executed, [])


if __name__ == "__main__":
    unittest.main()

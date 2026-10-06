import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest


sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("selector", HERE / "select-ui-tests.py")
selector = importlib.util.module_from_spec(spec)
spec.loader.exec_module(selector)

IMPACT_MAP = {
    "fullRun": ["FocusBear/AppDelegate.swift", "FocusBear.xcodeproj/**", "FocusBearUITests/UITestSupport.swift"],
    "noUITests": ["**/*.md", "FocusBearTests/**"],
    "areas": [
        {"name": "Day Plan", "paths": ["FocusBear/Schedule/**"],
         "tests": ["DayPlanUITests", "AccessibilityUITests/testDayPlan"]},
        {"name": "To-do", "paths": ["FocusBear/ToDo/**"], "tests": ["ToDoUITests", "DayPlanUITests/testTasks"]},
    ],
}
SMOKE = ["AuthUITests/testSignIn"]


def run(paths, **options):
    return selector.select(paths, IMPACT_MAP, SMOKE, **options)


class SelectionTests(unittest.TestCase):
    def test_a_change_in_one_area_runs_its_tests_and_smoke(self):
        selection = run(["FocusBear/Schedule/ScheduleKit.swift"])
        self.assertFalse(selection.is_full_run)
        self.assertEqual(selector.only_testing_arguments(selection), [
            "-only-testing:Focus BearUITests/AccessibilityUITests/testDayPlan",
            "-only-testing:Focus BearUITests/AuthUITests/testSignIn",
            "-only-testing:Focus BearUITests/DayPlanUITests",
        ])
        self.assertIn("Day Plan: `FocusBear/Schedule/ScheduleKit.swift`", selection.tests["DayPlanUITests"])

    def test_shared_infrastructure_runs_everything(self):
        selection = run(["FocusBear/Schedule/ScheduleKit.swift", "FocusBear/AppDelegate.swift"])
        self.assertTrue(selection.is_full_run)
        self.assertEqual(selector.only_testing_arguments(selection), [])
        self.assertIn("`FocusBear/AppDelegate.swift` is shared by every area", selection.full_run_reasons)

    def test_a_glob_reaches_into_subfolders(self):
        self.assertTrue(run(["FocusBear.xcodeproj/xcshareddata/xcschemes/Focus Bear.xcscheme"]).is_full_run)

    def test_a_path_the_map_doesnt_know_runs_everything(self):
        selection = run(["FocusBear/SomethingNew.swift"])
        self.assertTrue(selection.is_full_run)
        self.assertIn("isn't in the map", selection.full_run_reasons[0])

    def test_docs_and_unit_tests_run_only_smoke(self):
        selection = run(["docs/ui-tests.md", "FocusBearTests/DayFixPlanTests.swift"])
        self.assertFalse(selection.is_full_run)
        self.assertEqual(list(selection.tests), SMOKE)
        self.assertEqual(selection.paths_without_ui_tests, ["docs/ui-tests.md", "FocusBearTests/DayFixPlanTests.swift"])

    def test_an_area_file_named_md_still_counts_for_its_area(self):
        selection = run(["FocusBear/Schedule/NOTES.md"])
        self.assertIn("DayPlanUITests", selection.tests)
        self.assertEqual(selection.paths_without_ui_tests, [])

    def test_a_method_of_a_class_already_running_whole_is_not_listed_twice(self):
        selection = run(["FocusBear/Schedule/ScheduleKit.swift", "FocusBear/ToDo/ToDoListView.swift"])
        arguments = selector.only_testing_arguments(selection)
        self.assertIn("-only-testing:Focus BearUITests/DayPlanUITests", arguments)
        self.assertNotIn("-only-testing:Focus BearUITests/DayPlanUITests/testTasks", arguments)
        self.assertEqual(sorted(selection.tests["DayPlanUITests"]), [
            "Day Plan: `FocusBear/Schedule/ScheduleKit.swift`"])

    def test_the_full_run_label_runs_everything(self):
        selection = run(["docs/ui-tests.md"], labels=["ui-tests", "full-ui-tests"])
        self.assertTrue(selection.is_full_run)

    def test_push_and_scheduled_runs_run_everything(self):
        for event in ["push", "schedule"]:
            self.assertTrue(run([], event=event).is_full_run, event)

    def test_the_summary_says_why(self):
        summary = selector.summary_markdown(run(["FocusBear/ToDo/ToDoListView.swift", "README.md"]))
        self.assertIn("| `ToDoUITests` | To-do: `FocusBear/ToDo/ToDoListView.swift` |", summary)
        self.assertIn("| `AuthUITests/testSignIn` | Smoke always runs |", summary)
        self.assertIn("- `README.md`", summary)


class GuardTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        tests = self.root / selector.TESTS_DIR
        tests.mkdir()
        (tests / "Support.swift").write_text("class BaseUITestCase: XCTestCase {}\n")
        (tests / "DayPlanUITests.swift").write_text(
            "final class DayPlanUITests: BaseUITestCase {\n    func testTasks() throws {}\n}\n")
        (tests / "Regression.xctestplan").write_text(json.dumps({"testTargets": [{"skippedTests": ["ProbeUITests"]}]}))
        self.impact_map = {"fullRun": [], "noUITests": [], "areas": [
            {"name": "Day Plan", "paths": ["FocusBear/Schedule/**"], "tests": ["DayPlanUITests/testTasks"]}]}

    def add_class(self, name):
        (self.root / selector.TESTS_DIR / f"{name}.swift").write_text(f"final class {name}: BaseUITestCase {{}}\n")

    def test_a_mapped_suite_passes(self):
        self.assertEqual(selector.check(self.root, self.impact_map), [])

    def test_a_new_class_missing_from_the_map_fails(self):
        self.add_class("FocusTimerUITests")
        problems = selector.check(self.root, self.impact_map)
        self.assertEqual(len(problems), 1)
        self.assertIn("FocusTimerUITests isn't in", problems[0])

    def test_a_class_no_plan_runs_is_exempt(self):
        self.add_class("ProbeUITests")
        self.assertEqual(selector.check(self.root, self.impact_map), [])

    def test_a_misspelled_test_fails(self):
        self.impact_map["areas"][0]["tests"].append("DayPlanUITests/testTask")
        self.assertIn("names DayPlanUITests/testTask, which isn't a test", selector.check(self.root, self.impact_map)[0])

    def test_an_unknown_class_fails(self):
        self.impact_map["areas"][0]["tests"].append("DayPlanUITest")
        self.assertIn("names DayPlanUITest, which isn't a UI test class", selector.check(self.root, self.impact_map)[0])

    def test_the_repository_map_passes(self):
        impact_map = json.loads((selector.ROOT / selector.MAP_PATH).read_text())
        self.assertEqual(selector.check(selector.ROOT, impact_map), [])


if __name__ == "__main__":
    unittest.main()

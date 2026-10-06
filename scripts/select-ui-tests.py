#!/usr/bin/env python3
"""Which UI tests a change needs, from what it touched (.github/ui-test-impact.json).

    select-ui-tests.py select --base REF [--head REF] [--event NAME] [--labels a,b]
                              [--args-file FILE] [--summary FILE]
    select-ui-tests.py check

`select` diffs HEAD against its merge-base with REF and maps each changed path to the UI tests of
its area. Smoke's tests always run. The whole Regression plan runs instead when a changed path is
shared infrastructure (`fullRun`) or matches nothing in the map, when the pull request carries the
`full-ui-tests` label, or for a push or a scheduled run. It writes one xcodebuild argument per line
to --args-file (none means the whole plan) and why each test was chosen to --summary (Markdown, for
$GITHUB_STEP_SUMMARY).

`check` is the guard: it fails when a UI test class is named nowhere in the map (a new class would
otherwise never run on a selective build), or when the map names a class or test that doesn't exist.
"""
import argparse
import json
import re
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MAP_PATH = ".github/ui-test-impact.json"
TESTS_DIR = "FocusBearUITests"
SMOKE_PLAN = f"{TESTS_DIR}/Smoke.xctestplan"
REGRESSION_PLAN = f"{TESTS_DIR}/Regression.xctestplan"
TEST_TARGET = "Focus BearUITests"
FULL_RUN_LABEL = "full-ui-tests"
FULL_RUN_EVENTS = {"push", "schedule"}
CLASS_DECLARATION = re.compile(r"^\s*(?:final\s+)?class\s+(\w+)\s*:\s*(\w+)", re.MULTILINE)


@dataclass
class Selection:
    is_full_run: bool = False
    full_run_reasons: list = field(default_factory=list)
    # test → why it was chosen (the areas and paths that asked for it)
    tests: dict = field(default_factory=dict)
    paths_without_ui_tests: list = field(default_factory=list)

    def choose(self, test, reason):
        self.tests.setdefault(test, []).append(reason)

    def run_everything(self, reason):
        self.is_full_run = True
        self.full_run_reasons.append(reason)


def glob_to_regex(glob):
    """`**` crosses folders, `*` and `?` stay inside one."""
    pattern, i = "", 0
    while i < len(glob):
        if glob.startswith("**/", i):
            pattern, i = pattern + "(?:.*/)?", i + 3
        elif glob.startswith("**", i):
            pattern, i = pattern + ".*", i + 2
        elif glob[i] == "*":
            pattern, i = pattern + "[^/]*", i + 1
        elif glob[i] == "?":
            pattern, i = pattern + "[^/]", i + 1
        else:
            pattern, i = pattern + re.escape(glob[i]), i + 1
    return re.compile(pattern + r"\Z")


def matches(path, globs):
    return any(glob_to_regex(glob).match(path) for glob in globs)


def select(changed_paths, impact_map, smoke_tests, event="pull_request", labels=()):
    selection = Selection()
    if event in FULL_RUN_EVENTS:
        selection.run_everything(f"a {event} run always runs everything")
    if FULL_RUN_LABEL in labels:
        selection.run_everything(f"the pull request is labelled `{FULL_RUN_LABEL}`")
    for test in smoke_tests:
        selection.choose(test, "Smoke always runs")
    for path in changed_paths:
        if matches(path, impact_map["fullRun"]):
            selection.run_everything(f"`{path}` is shared by every area")
            continue
        areas = [area for area in impact_map["areas"] if matches(path, area["paths"])]
        if areas:
            for area in areas:
                for test in area["tests"]:
                    selection.choose(test, f"{area['name']}: `{path}`")
        elif matches(path, impact_map["noUITests"]):
            selection.paths_without_ui_tests.append(path)
        else:
            selection.run_everything(f"`{path}` isn't in the map, so nothing says which tests cover it")
    return selection


def only_testing_arguments(selection):
    """Nothing for a full run (the whole plan); otherwise each test, minus methods of a whole class."""
    if selection.is_full_run:
        return []
    whole_classes = {test for test in selection.tests if "/" not in test}
    tests = [test for test in selection.tests if "/" not in test or test.split("/")[0] not in whole_classes]
    return [f"-only-testing:{TEST_TARGET}/{test}" for test in sorted(tests)]


def summary_markdown(selection):
    lines = ["## UI tests for this change", ""]
    if selection.is_full_run:
        lines += ["**The whole Regression plan runs**, because:", ""]
        lines += [f"- {reason}" for reason in selection.full_run_reasons]
    else:
        lines += ["| Test | Why |", "| --- | --- |"]
        lines += [f"| `{test}` | {'; '.join(reasons)} |" for test, reasons in sorted(selection.tests.items())]
    if selection.paths_without_ui_tests:
        lines += ["", "No UI test covers these (docs, unit tests, tooling):", ""]
        lines += [f"- `{path}`" for path in selection.paths_without_ui_tests]
    return "\n".join(lines) + "\n"


def changed_paths(base, head):
    """Both sides of a rename: moving a file out of an area touches that area too."""
    output = subprocess.run(["git", "diff", "--name-status", "-M", f"{base}...{head}"], cwd=ROOT,
                            check=True, capture_output=True, text=True).stdout
    paths = []
    for line in output.splitlines():
        paths += line.split("\t")[1:]
    return list(dict.fromkeys(paths))


def plan_tests(root, plan_path, key):
    """A plan's `selectedTests` or `skippedTests`, as -only-testing names them (no `()`)."""
    plan = json.loads((root / plan_path).read_text())
    return [test.replace("()", "") for target in plan["testTargets"] for test in target.get(key, [])]


# MARK: - The guard

def declared_classes(root):
    """Every UI test class and the source it's declared in, minus the base classes others extend."""
    declared, superclasses = {}, set()
    for source in sorted((root / TESTS_DIR).glob("*.swift")):
        text = source.read_text()
        for name, superclass in CLASS_DECLARATION.findall(text):
            declared[name] = text
            superclasses.add(superclass)
    return {name: text for name, text in declared.items() if name not in superclasses}


def check(root, impact_map):
    problems = []
    classes = declared_classes(root)
    not_in_any_plan = set(plan_tests(root, REGRESSION_PLAN, "skippedTests"))
    named = [test for area in impact_map["areas"] for test in area["tests"]]
    named_classes = {test.split("/")[0] for test in named}
    for name in sorted(classes):
        if name not in named_classes and name not in not_in_any_plan:
            problems.append(f"{name} isn't in {MAP_PATH}: a change would never select it. "
                            f"Add it to the area whose code it tests.")
    for test in named:
        class_name, _, method = test.partition("/")
        if class_name not in classes:
            problems.append(f"{MAP_PATH} names {class_name}, which isn't a UI test class")
        elif method and not re.search(rf"func {re.escape(method)}\(", classes[class_name]):
            problems.append(f"{MAP_PATH} names {test}, which isn't a test in {class_name}")
    return problems


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    commands = parser.add_subparsers(dest="command", required=True)
    select_command = commands.add_parser("select")
    select_command.add_argument("--base", required=True)
    select_command.add_argument("--head", default="HEAD")
    select_command.add_argument("--event", default="pull_request")
    select_command.add_argument("--labels", default="", help="comma-separated pull request labels")
    select_command.add_argument("--args-file")
    select_command.add_argument("--summary")
    commands.add_parser("check")
    options = parser.parse_args()

    impact_map = json.loads((ROOT / MAP_PATH).read_text())
    if options.command == "check":
        problems = check(ROOT, impact_map)
        for problem in problems:
            print(f"::error::{problem}")
        return 1 if problems else 0

    labels = [label for label in options.labels.split(",") if label]
    paths = [] if options.event in FULL_RUN_EVENTS else changed_paths(options.base, options.head)
    selection = select(paths, impact_map, plan_tests(ROOT, SMOKE_PLAN, "selectedTests"), options.event, labels)
    arguments = only_testing_arguments(selection)
    if options.args_file:
        Path(options.args_file).write_text("".join(f"{argument}\n" for argument in arguments))
    summary = summary_markdown(selection)
    if options.summary:
        with open(options.summary, "a") as out:
            out.write(summary)
    print(summary)
    return 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""Re-run Mac-App PRs' "Config <-> Assets Sync" check once the assets repo has the keys.

config-assets-sync.yml only runs on pull_request events, so a Mac PR that failed because its
new strings were not yet on Focus-Bear/assets `main` stays red after the assets PR merges until
somebody re-runs it by hand. This script is that somebody. For every open Mac-App PR it:

  1. finds the latest config-assets-sync run on the PR's head commit;
  2. if that run failed, reads the missing keys out of its job log
     (the `MISSING_KEY:` lines check-config-assets-sync.py prints);
  3. fetches the current assets `main` config files and, if every missing key is now there,
     re-runs the run's failed jobs. PRs whose keys are still missing are reported and left alone.

Runs that are already queued/running, did not fail, failed for some other reason (no missing
keys in the log), or have been re-run MAX_RUN_ATTEMPTS times are skipped, so running it again
(e.g. once per assets merge in a burst) is idempotent.

Only PRs authored by DEFAULT_PULL_REQUEST_AUTHOR are considered unless --all-authors is passed:
re-running a check never modifies a PR, but other authors' PRs are theirs to manage.

Usage:
    rerun-assets-sync-checks.py [--dry-run] [--all-authors]

Auth: GITHUB_TOKEN (needs actions:write + pull-requests:read on Mac-App), else `gh auth token`.
Exit codes: 0 = every PR handled, 1 = at least one PR hit an API error.
"""
import argparse
from collections import namedtuple
import importlib.util
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request

sys.dont_write_bytecode = True
_SPEC = importlib.util.spec_from_file_location(
    "config_assets_sync", Path(__file__).with_name("check-config-assets-sync.py"))
CONFIG_ASSETS_SYNC = importlib.util.module_from_spec(_SPEC)
_SPEC.loader.exec_module(CONFIG_ASSETS_SYNC)

MAC_APP_REPOSITORY = "Focus-Bear/Mac-App"
ASSETS_REPOSITORY = "Focus-Bear/assets"
ASSETS_BRANCH = "main"
ASSETS_CONFIG_DIRECTORY = "config"
# Runs logged before MISSING_KEY lines existed only name the key; they always checked this file.
LEGACY_ASSETS_FILE = "config.json"
SYNC_WORKFLOW_FILE = "config-assets-sync.yml"
SYNC_WORKFLOW_EVENT = "pull_request"
DEFAULT_PULL_REQUEST_AUTHOR = "jeznag"

GITHUB_API_ROOT = "https://api.github.com"
GITHUB_JSON_MEDIA_TYPE = "application/vnd.github+json"
GITHUB_RAW_MEDIA_TYPE = "application/vnd.github.raw+json"
GITHUB_API_VERSION = "2022-11-28"
USER_AGENT = "focusbear-rerun-assets-sync-checks"
PAGE_SIZE = 100

RUN_STATUS_COMPLETED = "completed"
RUN_CONCLUSION_FAILURE = "failure"
# Backstop against a re-run loop if the check ever keeps failing with keys that assets has.
MAX_RUN_ATTEMPTS = 5

LOG_TIMESTAMP_PATTERN = re.compile(r"^\d{4}-\d{2}-\d{2}T\S+Z ")
# The GitHub log renders `::error::` annotations as `##[error]`.
LEGACY_MISSING_KEY_PATTERN = re.compile(r"^(?:##\[error\]|::error::)Missing in assets repo: (?P<key>.+?) = ")

MissingKey = namedtuple("MissingKey", "assets_file key")
Decision = namedtuple("Decision", "action reason")
ACTION_RERUN = "rerun"
ACTION_WAIT = "wait"
ACTION_SKIP = "skip"


# ---- pure decision logic (unit-tested in test-rerun-assets-sync-checks.py) -----------------

def strip_log_timestamp(line):
    return LOG_TIMESTAMP_PATTERN.sub("", line, count=1)


def parse_missing_key_line(line):
    """Return the MissingKey a sync-check log line reports, or None."""
    text = strip_log_timestamp(line.rstrip("\r\n"))
    prefix = CONFIG_ASSETS_SYNC.MISSING_KEY_PREFIX
    if text.startswith(prefix):
        assets_file, separator, key = text[len(prefix):].partition(":")
        return MissingKey(assets_file, key) if separator and key else None
    legacy = LEGACY_MISSING_KEY_PATTERN.match(text)
    return MissingKey(LEGACY_ASSETS_FILE, legacy.group("key")) if legacy else None


def extract_missing_keys(log_text):
    """Every key a sync-check job log reports missing (new and legacy formats both count)."""
    return {key for key in map(parse_missing_key_line, log_text.splitlines()) if key}


def keys_still_missing(missing_keys, assets_keys_by_file):
    """The subset of missing_keys that assets main still lacks, sorted for stable output."""
    return sorted(missing for missing in missing_keys
                  if missing.key not in assets_keys_by_file.get(missing.assets_file, set()))


def describe_keys(missing_keys):
    return ", ".join(f"{missing.assets_file}:{missing.key}" for missing in sorted(missing_keys))


def decide_before_logs(run):
    """Decision from the run's metadata alone, or None when its log has to be read."""
    if run is None:
        return Decision(ACTION_SKIP, "no config-assets-sync run on the head commit")
    if run["status"] != RUN_STATUS_COMPLETED:
        return Decision(ACTION_SKIP, f"run is already {run['status']}")
    if run["conclusion"] != RUN_CONCLUSION_FAILURE:
        return Decision(ACTION_SKIP, f"run concluded {run['conclusion']}")
    if run["run_attempt"] >= MAX_RUN_ATTEMPTS:
        return Decision(ACTION_SKIP, f"already attempted {run['run_attempt']} times")
    return None


def decide_after_logs(missing_keys, assets_keys_by_file):
    if not missing_keys:
        return Decision(ACTION_SKIP, "failed for a reason other than missing keys")
    still_missing = keys_still_missing(missing_keys, assets_keys_by_file)
    if still_missing:
        return Decision(ACTION_WAIT, f"assets {ASSETS_BRANCH} still lacks {describe_keys(still_missing)}")
    return Decision(ACTION_RERUN, f"assets {ASSETS_BRANCH} now has {describe_keys(missing_keys)}")


def is_in_scope(pull_request, author):
    """author None = every author."""
    return author is None or pull_request["user"]["login"] == author


def latest_run(runs):
    return max(runs, key=lambda run: run["run_number"], default=None)


# ---- GitHub API -----------------------------------------------------------------------------

def resolve_token():
    token = os.environ.get("GITHUB_TOKEN")
    if token:
        return token
    return subprocess.run(["gh", "auth", "token"], check=True, capture_output=True, text=True).stdout.strip()


class GitHubClient:
    def __init__(self, token):
        self.token = token

    def request(self, method, path, params=None, media_type=GITHUB_JSON_MEDIA_TYPE):
        query = f"?{urllib.parse.urlencode(params)}" if params else ""
        request = urllib.request.Request(f"{GITHUB_API_ROOT}{path}{query}", method=method)
        request.add_header("Accept", media_type)
        request.add_header("X-GitHub-Api-Version", GITHUB_API_VERSION)
        request.add_header("User-Agent", USER_AGENT)
        # Unredirected: job logs redirect to a signed storage URL that rejects a second credential.
        request.add_unredirected_header("Authorization", f"Bearer {self.token}")
        with urllib.request.urlopen(request) as response:
            return response.read().decode("utf-8")

    def get_json(self, path, params=None):
        return json.loads(self.request("GET", path, params))

    def get_text(self, path, media_type=GITHUB_JSON_MEDIA_TYPE):
        return self.request("GET", path, media_type=media_type)

    def post(self, path):
        self.request("POST", path)


def list_open_pull_requests(client):
    pull_requests, page = [], 1
    while True:
        batch = client.get_json(f"/repos/{MAC_APP_REPOSITORY}/pulls",
                                {"state": "open", "per_page": PAGE_SIZE, "page": page})
        pull_requests.extend(batch)
        if len(batch) < PAGE_SIZE:
            return pull_requests
        page += 1


def find_latest_sync_run(client, head_sha):
    response = client.get_json(
        f"/repos/{MAC_APP_REPOSITORY}/actions/workflows/{SYNC_WORKFLOW_FILE}/runs",
        {"head_sha": head_sha, "event": SYNC_WORKFLOW_EVENT, "per_page": PAGE_SIZE})
    return latest_run(response["workflow_runs"])


def read_failed_job_logs(client, run_id):
    jobs = client.get_json(f"/repos/{MAC_APP_REPOSITORY}/actions/runs/{run_id}/jobs")["jobs"]
    failed = [job for job in jobs if job["conclusion"] == RUN_CONCLUSION_FAILURE]
    return "\n".join(client.get_text(f"/repos/{MAC_APP_REPOSITORY}/actions/jobs/{job['id']}/logs")
                     for job in failed)


class AssetsConfigCache:
    """Assets-main config keys per file name, fetched at most once per script run."""

    def __init__(self, client):
        self.client = client
        self.keys_by_file = {}

    def keys_for(self, missing_keys):
        for assets_file in {missing.assets_file for missing in missing_keys}:
            if assets_file not in self.keys_by_file:
                self.keys_by_file[assets_file] = self.fetch_keys(assets_file)
        return self.keys_by_file

    def fetch_keys(self, assets_file):
        path = f"/repos/{ASSETS_REPOSITORY}/contents/{ASSETS_CONFIG_DIRECTORY}/{assets_file}"
        try:
            raw = self.client.get_text(f"{path}?ref={ASSETS_BRANCH}", media_type=GITHUB_RAW_MEDIA_TYPE)
        except urllib.error.HTTPError as error:
            if error.code == 404:
                return set()  # a file assets doesn't have can't supply any key
            raise
        return set(CONFIG_ASSETS_SYNC.leaf_keys(json.loads(raw)))


# ---- orchestration --------------------------------------------------------------------------

def decide_for_run(client, assets_cache, run):
    decision = decide_before_logs(run)
    if decision:
        return decision
    missing_keys = extract_missing_keys(read_failed_job_logs(client, run["id"]))
    return decide_after_logs(missing_keys, assets_cache.keys_for(missing_keys))


def handle_pull_request(client, assets_cache, pull_request, is_dry_run):
    label = f"#{pull_request['number']} ({pull_request['head']['ref']})"
    run = find_latest_sync_run(client, pull_request["head"]["sha"])
    decision = decide_for_run(client, assets_cache, run)
    run_link = f" {run['html_url']}" if run else ""
    if decision.action == ACTION_RERUN and not is_dry_run:
        client.post(f"/repos/{MAC_APP_REPOSITORY}/actions/runs/{run['id']}/rerun-failed-jobs")
    verb = {ACTION_RERUN: "would re-run" if is_dry_run else "re-ran",
            ACTION_WAIT: "waiting", ACTION_SKIP: "skip"}[decision.action]
    print(f"{label}: {verb} — {decision.reason}{run_link}")


def main(argv):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--dry-run", action="store_true", help="report decisions without re-running anything")
    parser.add_argument("--all-authors", action="store_true",
                        help=f"consider every open PR, not just {DEFAULT_PULL_REQUEST_AUTHOR}'s")
    arguments = parser.parse_args(argv[1:])
    author = None if arguments.all_authors else DEFAULT_PULL_REQUEST_AUTHOR

    client = GitHubClient(resolve_token())
    assets_cache = AssetsConfigCache(client)
    has_errors = False
    pull_requests = [pr for pr in list_open_pull_requests(client) if is_in_scope(pr, author)]
    for pull_request in sorted(pull_requests, key=lambda pr: pr["number"]):
        try:
            handle_pull_request(client, assets_cache, pull_request, arguments.dry_run)
        except (urllib.error.URLError, KeyError, json.JSONDecodeError) as error:
            has_errors = True
            print(f"::error::#{pull_request['number']}: {error}")
    return 1 if has_errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))

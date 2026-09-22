# Isolated app-hosted tests on the local runner

This runner-only PATH wrapper stops Focus-Bear/Mac-App GitHub Actions test jobs before
`xcodebuild` can launch an app from an older checkout without the isolated XCTest host.
It does not install or modify anything by itself. It is an operational guard for trusted
workflows, not a sandbox: a workflow that explicitly invokes `/usr/bin/xcodebuild` bypasses PATH.

The wrapper uses the actual workspace/project's Git checkout, not `GITHUB_WORKSPACE` or
the installer's checkout. A trusted, versioned copy of the unchanged Mac #2465 preflight
checks the invocation's source, shared scheme and workflow. It never executes a checker
from the job checkout, patches the checkout, opens an app, or accesses credentials.

Guarded invocations must specify the Focus Bear scheme and Debug configuration. Compiler
condition, host, test-plan and xcconfig overrides are rejected. `test-without-building`
and `-xctestrun` are rejected because source inspection cannot prove the provenance of a
previously built host; use `test` so the verified checkout is built. Other repositories,
non-test commands, and commands outside GitHub Actions go directly to `/usr/bin/xcodebuild`
with their original arguments and environment. The wrapper itself never resolves that tool
through PATH. GitHub repository names are compared case-insensitively.

## Installation, after the runner becomes idle

The parent process owns deployment and the exact runner service restart. Do not install
or switch PATH while `Runner.Worker` or a local build/test job is active.

Copy reviewed files into this immutable version layout (use the full reviewed commit SHA):

```
~/.local/share/focusbear-runner/<sha>/bin/xcodebuild
~/.local/share/focusbear-runner/<sha>/check-isolated-test-host.py
```

Sources are `scripts/local-runner/xcodebuild` and `scripts/check-isolated-test-host.py`.
Keep the wrapper executable. Both directories and files should be owned by the runner user
and not writable by other users. The preflight's SHA-256 is
`7bf6781f3f981950eda237e74ae8f80d4c93809d14327bfdf4c2b0cef2722464`, byte-identical to the
reviewed #2465 copy at the time this wrapper was added. Do not fetch it from a job branch.

Back up the runner's existing `.path` file, then prepend only the versioned `bin` directory
to that runner's colon-delimited path, preserving all existing entries and their order.
Do not change shell profiles, the global PATH, signing/keychain ACLs, `xcode-select`, or
the user's app installation. Restart only the exact idle Actions runner service so it
reloads `.path`. Confirm from the runner job environment that `command -v xcodebuild`
resolves to the versioned wrapper.

Before permitting another Mac test job, exercise the wrapper against an unisolated
temporary checkout with the GitHub Actions repository environment: it must return 78
without invoking the real tool. `python3 scripts/local-runner/test-xcodebuild-wrapper.py`
tests that case using an injected recording executor, plus allowed argument forwarding,
trusted preflight invocation and path/configuration boundaries; it never runs xcodebuild.
`python3 scripts/test-isolated-test-host.py` runs the six unchanged structural regressions.
Native LogicTestHostTests remain the runtime check; this wrapper does not replace them.

## Rollback

Wait for the runner to become idle, restore its exact saved `.path`, and restart only that
runner service. Leave the versioned directory for diagnosis or remove only that exact
directory after verifying PATH no longer refers to it. This restores prior runner behavior;
it does not add isolation to older branches, so keep unguarded Mac test jobs paused until
their source includes the #2465 prerequisite. No user app or personal settings are modified.

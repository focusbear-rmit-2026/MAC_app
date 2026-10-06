#!/usr/bin/env bash
#
# Run the UI tests and, only if they pass, publish a release DMG of the same commit: upload it to
# Cloudflare R2 with wrangler and post the download link to the Cliq channel #version-updates.
#
#     ./scripts/ui-test-and-publish.sh                     # regression plan (every UI test)
#     ./scripts/ui-test-and-publish.sh --plan smoke        # the critical path only
#     ./scripts/ui-test-and-publish.sh --dry-run           # test and build, but upload and post nothing
#
# Extra arguments go to scripts/run-ui-tests.sh (and from there to xcodebuild).
#
# The UI tests run against an isolated Debug build (docs/ui-tests.md). The DMG comes from
# scripts/build-release-dmg.sh, which builds the same commit the way releases are built, so the working
# tree must be clean: the link names the commit that was tested.
#
# Before running:
#   npx wrangler login               # your own Cloudflare login; it needs write access to $R2_BUCKET
#   CLOUDFLARE_ACCOUNT_ID=…          # the account that owns $R2_BUCKET, if your login has several
#   ZOHO_CLIQ_BACKEND_BOT_WEBHOOK=…  # the Cliq bot's incoming webhook, https://cliq.zoho.com.au/api/v2/bots/…
#   ZOHO_CLIQ_API_KEY=…              # its zapikey
# Optional:
#   ZOHO_CLIQ_CHANNEL  channel unique name, default versionupdates (#version-updates)
#   R2_BUCKET          default desktop-app-releases
#   R2_PREFIX          default mac/ui-tested
#   PUBLIC_BASE_URL    where $R2_BUCKET is served, default https://downloads.focusbear.io
#   NOTARY_PROFILE     passed through to build-release-dmg.sh
set -euo pipefail

cd "$(dirname "$0")/.."

readonly EXIT_USAGE=64
readonly EXIT_TEMPFAIL=75   # run-ui-tests.sh: Focus Bear's screen was in the way; nothing ran
readonly UI_TEST_RUNNER="${UI_TEST_RUNNER:-scripts/run-ui-tests.sh}"
readonly BUILD_DMG="${BUILD_DMG:-scripts/build-release-dmg.sh}"
readonly DMG_CONTENT_TYPE="application/x-apple-diskimage"
# wrangler r2 object put refuses anything bigger; past this the upload needs the S3 API instead.
readonly WRANGLER_UPLOAD_LIMIT_BYTES=$((300 * 1024 * 1024))
readonly CLIQ_TIMEOUT_SECONDS=10
readonly R2_BUCKET="${R2_BUCKET:-desktop-app-releases}"
readonly R2_PREFIX="${R2_PREFIX:-mac/ui-tested}"
readonly PUBLIC_BASE_URL="${PUBLIC_BASE_URL:-https://downloads.focusbear.io}"
readonly ZOHO_CLIQ_CHANNEL="${ZOHO_CLIQ_CHANNEL:-versionupdates}"

plan="regression"
is_dry_run=false
runner_args=()
while [ $# -gt 0 ]; do
  case "$1" in
    --plan) plan="${2:-}"; shift 2 ;;
    --dry-run) is_dry_run=true; shift ;;
    *) runner_args+=("$1"); shift ;;
  esac
done
case "$plan" in
  smoke|regression) ;;
  *) echo "usage: $0 [--plan smoke|regression] [--dry-run] [run-ui-tests.sh arguments…]" >&2; exit "$EXIT_USAGE" ;;
esac

fail() { echo "error: $*" >&2; exit 1; }

wrangler() { npx --yes wrangler "$@"; }

require_publish_setup() {
  local name
  for name in ZOHO_CLIQ_BACKEND_BOT_WEBHOOK ZOHO_CLIQ_API_KEY; do
    [ -n "${!name:-}" ] || fail "$name is not set (see the top of $0)"
  done
  command -v jq >/dev/null || fail "jq is needed: brew install jq"
  wrangler whoami 2>&1 | grep -q "[0-9a-f]\{32\}" || fail "wrangler isn't logged in: run npx wrangler login"
}

require_clean_tree() {
  [ -z "$(git status --porcelain --untracked-files=no)" ] ||
    fail "the working tree has uncommitted changes; the published build must be exactly the tested commit"
}

run_ui_tests() {
  local status=0
  "$UI_TEST_RUNNER" --plan "$plan" ${runner_args[@]+"${runner_args[@]}"} || status=$?
  if [ "$status" -eq "$EXIT_TEMPFAIL" ]; then
    echo "The UI tests didn't run, so nothing was published. Run this again later." >&2
    exit "$EXIT_TEMPFAIL"
  elif [ "$status" -ne 0 ]; then
    echo "The UI tests failed (exit $status), so nothing was published." >&2
    exit "$status"
  fi
}

# Prints the DMG's path: the last line build-release-dmg.sh prints.
build_dmg() {
  local dmg
  dmg=$("$BUILD_DMG" "$1" | tail -1) || fail "building the DMG failed, so nothing was published"
  [ -f "$dmg" ] || fail "$BUILD_DMG didn't print the path of a DMG (got: ${dmg:-nothing})"
  echo "$dmg"
}

upload_to_r2() {
  local file="$1" key="$2" public_url="$3" size
  size=$(stat -f%z "$file")
  [ "$size" -le "$WRANGLER_UPLOAD_LIMIT_BYTES" ] ||
    fail "the DMG is $size bytes; wrangler uploads at most $WRANGLER_UPLOAD_LIMIT_BYTES"
  wrangler r2 object put "$R2_BUCKET/$key" --file "$file" --content-type "$DMG_CONTENT_TYPE" --remote >&2 ||
    fail "the upload to R2 failed"
  local served_size
  served_size=$(curl -fsSI "$public_url" | tr -d '\r' | awk 'tolower($1)=="content-length:" {print $2}')
  [ "$served_size" = "$size" ] || fail "$public_url serves ${served_size:-nothing}, expected $size bytes"
}

# Same message shape as the analytics reports (analytics: node-js-analytics/communication/cliq.js).
post_to_cliq() {
  local title="$1" content="$2"
  # Never print this URL: it embeds the zapikey.
  local url="$ZOHO_CLIQ_BACKEND_BOT_WEBHOOK?zapikey=$ZOHO_CLIQ_API_KEY"
  jq -n --arg title "$title" --arg content "$content" --arg channel "$ZOHO_CLIQ_CHANNEL" \
      '{message: "*\($title)*\n\($content)", card: {title: $title, theme: "modern-inline"}, channel: $channel}' |
    curl -fsS --max-time "$CLIQ_TIMEOUT_SECONDS" -X POST "$url" -H "Content-Type: application/json" \
      --data-binary @- > /dev/null ||
    fail "posting to Cliq failed (the DMG is uploaded: check the webhook, key and ZOHO_CLIQ_CHANNEL)"
}

main() {
  [ "$is_dry_run" = true ] || require_publish_setup
  require_clean_tree
  local commit branch
  commit=$(git rev-parse --short HEAD)
  branch=$(git rev-parse --abbrev-ref HEAD)

  run_ui_tests
  [ "$(git rev-parse --short HEAD)" = "$commit" ] ||
    fail "HEAD moved from $commit while the tests ran; not publishing a build of a different commit"
  require_clean_tree

  local work dmg name
  work=$(mktemp -d "${TMPDIR:-/tmp}/ui-test-publish.XXXXXX")
  dmg=$(build_dmg "$work")
  name=$(basename "$dmg")
  local key="$R2_PREFIX/${name%.dmg}/$name"
  local public_url="$PUBLIC_BASE_URL/$key"
  local title="Mac build ${name%.dmg} passed the $plan UI tests"
  local content="Download: $public_url"$'\n'"Commit $commit on $branch."

  if [ "$is_dry_run" = true ]; then
    echo "Dry run: would upload $dmg to r2://$R2_BUCKET/$key and post to #$ZOHO_CLIQ_CHANNEL:"
    printf '%s\n%s\n' "$title" "$content"
    return
  fi
  upload_to_r2 "$dmg" "$key" "$public_url"
  post_to_cliq "$title" "$content"
  echo "Published $public_url and posted it to #$ZOHO_CLIQ_CHANNEL."
  rm -rf "$work"
}

main

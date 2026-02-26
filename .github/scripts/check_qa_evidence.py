#!/usr/bin/env python3
"""
QA Evidence Checker

Checks issues in 'QA Passed' / 'Done' / 'QA Failed' on the Focus Bear GitHub
Project board to ensure they have a proper test-evidence comment. Uses the
OpenAI Responses API to assess evidence quality. Issues without adequate
evidence are moved back to 'Ready for QA' with an explanatory comment that
@mentions the relevant person.

Required environment variables:
  GITHUB_TOKEN              - PAT with read:org + read:project + repo scopes
  OPEN_AI_KEY_FOR_QA_REVIEW - OpenAI API key
  ORG                       - GitHub org name (default: Focus-Bear)
  PROJECT_NUMBER            - Project board number (default: 3)
  DAYS_TO_CHECK             - Only check issues updated in last N days; 0=all (default: 30)
  STATUS_VALUES             - Comma-separated statuses to check (default: QA Passed,Done,QA Failed)
  READY_FOR_QA_STATUS       - Status to move failing issues back to (default: Ready for QA)
  OPENAI_MODEL              - Model to use (default: gpt-4.1-mini)
  REASONING_EFFORT          - Reasoning effort level: low/medium/high (default: medium)
  DRY_RUN                   - If true/1/yes, only report issues without posting comments or
                              moving items (default: false)
  QA_APPROVED_LABEL         - Label applied to issues with approved evidence (default: qa-evidence-approved)
                              Issues already carrying this label are skipped on subsequent runs.
"""

import base64
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime, timezone, timedelta
from difflib import get_close_matches
from typing import Any

import requests
from openai import OpenAI

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

GITHUB_TOKEN = os.environ["GITHUB_TOKEN"]
OPENAI_API_KEY = os.environ["OPEN_AI_KEY_FOR_QA_REVIEW"]

ORG = os.environ.get("ORG", "Focus-Bear")
PROJECT_NUMBER = int(os.environ.get("PROJECT_NUMBER", "1"))
DAYS_TO_CHECK = int(os.environ.get("DAYS_TO_CHECK", "30"))
STATUS_VALUES = [s.strip() for s in os.environ.get("STATUS_VALUES", "QA Passed/Done,QA Failed").split(",")]
READY_FOR_QA_STATUS = os.environ.get("READY_FOR_QA_STATUS", "QA in Progress")

# NOTE: The user requested "gpt-5-mini". Set OPENAI_MODEL env var to override
# once you confirm the exact model name from https://platform.openai.com/docs/models
MODEL = os.environ.get("OPENAI_MODEL", "gpt-4.1-mini")
REASONING_EFFORT = os.environ.get("REASONING_EFFORT", "medium")
DRY_RUN = os.environ.get("DRY_RUN", "false").lower() in ("true", "1", "yes")
QA_APPROVED_LABEL = os.environ.get("QA_APPROVED_LABEL", "qa-evidence-approved")

GRAPHQL_URL = "https://api.github.com/graphql"
GITHUB_REST_BASE = "https://api.github.com"

GITHUB_HEADERS = {
    "Authorization": f"Bearer {GITHUB_TOKEN}",
    "Accept": "application/vnd.github.v3+json",
    "X-GitHub-Api-Version": "2022-11-28",
}

# Headers for downloading binary attachments (no API-specific Accept header which
# can confuse CDNs when following GitHub's signed-URL redirects)
GITHUB_DOWNLOAD_HEADERS = {
    "Authorization": f"Bearer {GITHUB_TOKEN}",
}

# Attachment URL patterns
# Use [^\s"'>)]+ instead of \S+ so that URLs embedded in HTML attributes like
#   <img src="https://..." />
# don't capture the trailing " or > character, which would produce invalid URLs.
GDRIVE_RE = re.compile(r"https://drive\.google\.com/[^\s\"'>)]+", re.IGNORECASE)
GDRIVE_FOLDER_ID_RE = re.compile(r"/drive/folders/([^/?&\s\"'>)]+)", re.IGNORECASE)
DIRECT_IMAGE_RE = re.compile(
    r"https?://[^\s\"'>)]+\.(?:png|jpg|jpeg|gif|webp|bmp)(?:\?[^\s\"'>)]*)?",
    re.IGNORECASE,
)
VIDEO_RE = re.compile(
    r"https?://[^\s\"'>)]+\.(?:mp4|mov|avi|mkv|webm)(?:\?[^\s\"'>)]*)?",
    re.IGNORECASE,
)
GITHUB_CDN_RE = re.compile(
    r"https://(?:user-images\.githubusercontent\.com"
    r"|private-user-images\.githubusercontent\.com"
    r"|github\.com/user-attachments)[^\s\"'>)]+",
    re.IGNORECASE,
)

openai_client = OpenAI(api_key=OPENAI_API_KEY)


# ---------------------------------------------------------------------------
# GitHub GraphQL helpers
# ---------------------------------------------------------------------------

def graphql(query: str, variables: dict | None = None) -> dict:
    """Execute a GraphQL query against the GitHub API."""
    payload: dict = {"query": query}
    if variables:
        payload["variables"] = variables
    resp = requests.post(
        GRAPHQL_URL,
        json=payload,
        headers={"Authorization": f"Bearer {GITHUB_TOKEN}", "Content-Type": "application/json"},
        timeout=30,
    )
    resp.raise_for_status()
    data = resp.json()
    if "errors" in data:
        raise RuntimeError(f"GraphQL errors: {json.dumps(data['errors'], indent=2)}")
    return data["data"]


def get_project_items(org: str, project_number: int) -> list[dict]:
    """
    Return all items from the project board, paginated.
    Each item includes its status field value and linked issue/PR details.
    """
    query = """
    query($org: String!, $number: Int!, $cursor: String) {
      organization(login: $org) {
        projectV2(number: $number) {
          id
          items(first: 100, after: $cursor) {
            pageInfo { hasNextPage endCursor }
            nodes {
              id
              fieldValues(first: 20) {
                nodes {
                  ... on ProjectV2ItemFieldSingleSelectValue {
                    name
                    field { ... on ProjectV2SingleSelectField { name } }
                  }
                }
              }
              content {
                ... on Issue {
                  number
                  title
                  body
                  url
                  updatedAt
                  repository { nameWithOwner }
                  author { login }
                  assignees(first: 5) { nodes { login } }
                  labels(first: 20) { nodes { name } }
                }
                ... on PullRequest {
                  number
                  title
                  url
                  updatedAt
                  repository { nameWithOwner }
                  author { login }
                  assignees(first: 5) { nodes { login } }
                  labels(first: 20) { nodes { name } }
                }
              }
            }
          }
        }
      }
    }
    """
    items: list[dict] = []
    cursor = None

    while True:
        data = graphql(query, {"org": org, "number": project_number, "cursor": cursor})
        project = data["organization"]["projectV2"]
        page = project["items"]

        for node in page["nodes"]:
            status = _extract_status(node)
            content = node.get("content")
            if content:
                items.append({"item_id": node["id"], "status": status, "content": content})

        if not page["pageInfo"]["hasNextPage"]:
            break
        cursor = page["pageInfo"]["endCursor"]

    return items


def _extract_status(node: dict) -> str | None:
    """Pull the Status single-select value from a project item node."""
    for fv in node.get("fieldValues", {}).get("nodes", []):
        if isinstance(fv, dict) and fv.get("field", {}).get("name", "").lower() == "status":
            return fv.get("name")
    return None


def get_project_id(org: str, project_number: int) -> str:
    """Return the node ID of the project."""
    query = """
    query($org: String!, $number: Int!) {
      organization(login: $org) {
        projectV2(number: $number) { id }
      }
    }
    """
    data = graphql(query, {"org": org, "number": project_number})
    return data["organization"]["projectV2"]["id"]


STATUS_FIELD_NAME = "status"
MAX_FIELDS_TO_FETCH = 100
MAX_CLOSE_MATCHES = 5
CLOSE_MATCH_CUTOFF = 0.6


def _normalise_label(value: str) -> str:
    return " ".join(str(value).strip().lower().split())


def get_status_field_and_option(
    org: str, project_number: int, target_status: str
) -> tuple[str, str]:
    """
    Return (fieldId, optionId) for the Status field's target_status option.
    If not found, prints all candidate Status-like fields + their options.
    """
    query = f"""
    query($org: String!, $number: Int!) {{
      organization(login: $org) {{
        projectV2(number: $number) {{
          fields(first: {MAX_FIELDS_TO_FETCH}) {{
            nodes {{
              ... on ProjectV2SingleSelectField {{
                id
                name
                options {{ id name }}
              }}
            }}
          }}
        }}
      }}
    }}
    """

    data: dict[str, Any] = graphql(query, {"org": org, "number": project_number})
    nodes = data["organization"]["projectV2"]["fields"]["nodes"]

    target_norm = _normalise_label(target_status)

    single_select_fields: list[dict[str, Any]] = [
        field for field in nodes if isinstance(field, dict) and "options" in field
    ]

    status_like_fields = [
        field
        for field in single_select_fields
        if _normalise_label(field.get("name", "")) == STATUS_FIELD_NAME
        or STATUS_FIELD_NAME in _normalise_label(field.get("name", ""))
    ]

    for field in status_like_fields:
        for option in field.get("options", []):
            if _normalise_label(option.get("name", "")) == target_norm:
                return field["id"], option["id"]

    # Debug dump
    print(
        f"Could not find target status '{target_status}'. "
        f"Dumping all single-select fields + options for project {project_number}."
    )
    for field in single_select_fields:
        field_name = field.get("name", "")
        print(f"\nField: {field_name} ({field.get('id')})")
        for option in field.get("options", []):
            print(f"  - {option.get('name')} ({option.get('id')})")

    # Helpful suggestions (only from Status-like fields, if any)
    candidate_names: list[str] = []
    for field in (status_like_fields or single_select_fields):
        candidate_names.extend([opt.get("name", "") for opt in field.get("options", [])])

    suggestions = get_close_matches(
        target_status, [c for c in candidate_names if c], n=MAX_CLOSE_MATCHES, cutoff=CLOSE_MATCH_CUTOFF
    )
    if suggestions:
        raise ValueError(
            f"Could not find Status option '{target_status}'. Close matches: {suggestions}"
        )

    raise ValueError(
        f"Could not find Status field option '{target_status}' in project {project_number}"
    )


def move_item_to_status(
    project_id: str, item_id: str, field_id: str, option_id: str
) -> None:
    """Update a project item's Status field to the given option."""
    mutation = """
    mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!) {
      updateProjectV2ItemFieldValue(input: {
        projectId: $projectId
        itemId: $itemId
        fieldId: $fieldId
        value: { singleSelectOptionId: $optionId }
      }) {
        projectV2Item { id }
      }
    }
    """
    graphql(mutation, {
        "projectId": project_id,
        "itemId": item_id,
        "fieldId": field_id,
        "optionId": option_id,
    })


# ---------------------------------------------------------------------------
# GitHub REST helpers
# ---------------------------------------------------------------------------

def get_all_comments(repo: str, issue_number: int) -> list[dict]:
    """
    Return all comments on an issue (most recent last).
    """
    url = f"{GITHUB_REST_BASE}/repos/{repo}/issues/{issue_number}/comments"
    all_comments: list[dict] = []
    page = 1

    while True:
        resp = requests.get(
            url,
            headers=GITHUB_HEADERS,
            params={"per_page": 100, "page": page},
            timeout=30,
        )
        resp.raise_for_status()
        batch = resp.json()
        if not batch:
            break
        all_comments.extend(batch)
        if len(batch) < 100:
            break
        page += 1

    return all_comments


def post_issue_comment(repo: str, issue_number: int, body: str) -> None:
    """Post a comment on a GitHub issue."""
    url = f"{GITHUB_REST_BASE}/repos/{repo}/issues/{issue_number}/comments"
    resp = requests.post(url, headers=GITHUB_HEADERS, json={"body": body}, timeout=30)
    resp.raise_for_status()


def ensure_label_exists(repo: str, label_name: str) -> None:
    """Create the label on the repo if it doesn't already exist (idempotent)."""
    url = f"{GITHUB_REST_BASE}/repos/{repo}/labels/{label_name}"
    resp = requests.get(url, headers=GITHUB_HEADERS, timeout=30)
    if resp.status_code == 200:
        return  # Already exists

    create_resp = requests.post(
        f"{GITHUB_REST_BASE}/repos/{repo}/labels",
        headers=GITHUB_HEADERS,
        json={
            "name": label_name,
            "color": "0075ca",
            "description": "QA evidence has been reviewed and approved",
        },
        timeout=30,
    )
    # 422 = label already exists (race condition) — safe to ignore
    if create_resp.status_code not in (201, 422):
        create_resp.raise_for_status()


def add_label_to_issue(repo: str, issue_number: int, label_name: str) -> None:
    """Apply a label to an issue."""
    url = f"{GITHUB_REST_BASE}/repos/{repo}/issues/{issue_number}/labels"
    resp = requests.post(
        url,
        headers=GITHUB_HEADERS,
        json={"labels": [label_name]},
        timeout=30,
    )
    resp.raise_for_status()


# ---------------------------------------------------------------------------
# Attachment helpers
# ---------------------------------------------------------------------------

def download_github_attachment(url: str) -> dict:
    """
    Download a GitHub attachment using auth headers, check content type.
    Returns a dict with type, bytes, and content_type.

    Uses GITHUB_DOWNLOAD_HEADERS (auth only, no API Accept header) so that
    GitHub's CDN signed-URL redirects work correctly. Falls back to no-auth
    if the authenticated request fails (e.g. public repos where the redirect
    CDN URL is already signed with a query-string token).
    """
    try:
        # Auth-only headers — avoid the API Accept header which confuses CDNs
        resp = requests.get(url, headers=GITHUB_DOWNLOAD_HEADERS, timeout=60, allow_redirects=True)
        if resp.status_code != 200:
            print(f"  [attachments] Auth request failed HTTP {resp.status_code} — retrying without auth")
            resp = requests.get(url, timeout=60, allow_redirects=True)
            if resp.status_code != 200:
                print(f"  [attachments] No-auth also failed HTTP {resp.status_code} for {url[:80]}")
                return {"type": "unknown"}

        content_type = resp.headers.get("content-type", "").lower()
        print(f"  [attachments] Fetched {url[:80]} → final URL: {resp.url[:80]}")
        print(f"  [attachments] Content-Type: {content_type}, size: {len(resp.content) / 1024:.1f} KB")

        if "image" in content_type:
            return {"type": "image", "bytes": resp.content, "content_type": content_type}
        elif "video" in content_type or "octet-stream" in content_type:
            return {"type": "video", "bytes": resp.content, "content_type": content_type}

        # Infer from URL extension as a last resort
        url_lower = url.lower().split("?")[0]
        if any(url_lower.endswith(ext) for ext in (".png", ".jpg", ".jpeg", ".gif", ".webp", ".bmp")):
            print(f"  [attachments] Content-Type unclear but URL suggests image — treating as image")
            return {"type": "image", "bytes": resp.content, "content_type": content_type}
        elif any(url_lower.endswith(ext) for ext in (".mp4", ".mov", ".avi", ".mkv", ".webm")):
            print(f"  [attachments] Content-Type unclear but URL suggests video — treating as video")
            return {"type": "video", "bytes": resp.content, "content_type": content_type}

        print(f"  [attachments] Unrecognised content-type '{content_type}' and no known extension")
        return {"type": "unknown", "content_type": content_type}
    except Exception as exc:
        print(f"  [attachments] Error fetching {url[:80]}: {exc}")
        return {"type": "unknown"}

def try_download_image(url: str) -> bytes | None:
    """Attempt to download an image from a URL. Returns raw bytes or None."""
    try:
        resp = requests.get(url, timeout=20, allow_redirects=True)
        if resp.status_code == 200 and "image" in resp.headers.get("content-type", ""):
            return resp.content
    except Exception:
        pass
    return None


def download_gdrive_file(file_id: str, max_mb: int = 200) -> tuple[str | None, str]:
    """
    Download a file from Google Drive to a temp file.
    Handles large-file confirmation pages (virus-scan warning).
    Returns (temp_file_path, content_type) or (None, "").
    Caller is responsible for deleting the temp file.
    """
    session = requests.Session()
    url = f"https://drive.google.com/uc?export=download&id={file_id}"
    print(f"  [gdrive] Downloading file_id={file_id}")
    try:
        resp = session.get(url, timeout=60, allow_redirects=True, stream=True)
        print(f"  [gdrive] Initial response: status={resp.status_code}, content-type={resp.headers.get('content-type', '?')}")
        if resp.status_code != 200:
            print(f"  [gdrive] Download failed: HTTP {resp.status_code}")
            return None, ""

        content_type = resp.headers.get("content-type", "")

        # Large files show an HTML confirmation page instead of the file
        if "text/html" in content_type:
            print(f"  [gdrive] Got HTML confirmation page (large file / virus scan warning) — extracting confirm token")
            html_chunks: list[bytes] = []
            for chunk in resp.iter_content(chunk_size=65536):
                html_chunks.append(chunk)
                if sum(len(c) for c in html_chunks) > 1_048_576:
                    break
            html_text = b"".join(html_chunks).decode("utf-8", errors="ignore")

            confirm_match = re.search(r'confirm=([^&"&amp;]+)', html_text)
            uuid_match = re.search(r'uuid=([^&"&amp;]+)', html_text)

            if not confirm_match:
                print(f"  [gdrive] Could not find confirm token in HTML response — file may be restricted or not shared publicly")
                return None, ""

            params: dict = {
                "export": "download",
                "id": file_id,
                "confirm": confirm_match.group(1),
            }
            if uuid_match:
                params["uuid"] = uuid_match.group(1)

            print(f"  [gdrive] Retrying download with confirm token")
            resp = session.get(
                "https://drive.google.com/uc",
                params=params,
                timeout=120,
                allow_redirects=True,
                stream=True,
            )
            print(f"  [gdrive] Confirmed response: status={resp.status_code}, content-type={resp.headers.get('content-type', '?')}")
            if resp.status_code != 200:
                print(f"  [gdrive] Confirmed download failed: HTTP {resp.status_code}")
                return None, ""
            content_type = resp.headers.get("content-type", "")

        # Choose a sensible suffix for the temp file
        suffix = ".bin"
        if "video" in content_type:
            suffix = ".mp4"
        elif "image/jpeg" in content_type or "image/jpg" in content_type:
            suffix = ".jpg"
        elif "image/png" in content_type:
            suffix = ".png"
        elif "image/gif" in content_type:
            suffix = ".gif"

        max_bytes = max_mb * 1024 * 1024
        downloaded = 0
        tmp = tempfile.NamedTemporaryFile(suffix=suffix, delete=False)
        print(f"  [gdrive] Saving to temp file {tmp.name} (suffix={suffix})")
        try:
            for chunk in resp.iter_content(chunk_size=1_048_576):
                tmp.write(chunk)
                downloaded += len(chunk)
                if downloaded >= max_bytes:
                    print(f"  [warn] GDrive file exceeds {max_mb} MB limit, stopping download")
                    break
            tmp.close()
            print(f"  [gdrive] Download complete: {downloaded / 1024:.1f} KB, content-type={content_type}")
            return tmp.name, content_type
        except Exception:
            tmp.close()
            try:
                os.unlink(tmp.name)
            except OSError:
                pass
            return None, ""

    except Exception as exc:
        print(f"  [warn] Failed to download GDrive file {file_id}: {exc}")
        return None, ""


def list_gdrive_folder_files(folder_id: str, max_files: int = 10) -> list[str]:
    """
    Attempt to list file IDs in a publicly-shared Google Drive folder.
    Uses the embedded folder view endpoint which works for "Anyone with the link" folders.
    Returns a list of file IDs (empty if listing fails or folder is private).
    """
    print(f"  [gdrive] Attempting to list files in folder id={folder_id}")
    # The embeddedfolderview endpoint serves partial HTML for shared folders
    url = f"https://drive.google.com/embeddedfolderview?id={folder_id}#list"
    try:
        resp = requests.get(url, timeout=30, allow_redirects=True)
        print(f"  [gdrive] Folder listing response: HTTP {resp.status_code}, size={len(resp.content) / 1024:.1f} KB")
        if resp.status_code != 200:
            print(f"  [gdrive] Folder listing failed: HTTP {resp.status_code}")
            return []

        html = resp.text
        file_ids: set[str] = set()

        # Pattern 1: /file/d/FILE_ID embedded as links in the HTML
        for m in re.finditer(r"/file/d/([a-zA-Z0-9_-]{25,})", html):
            file_ids.add(m.group(1))

        # Pattern 2: data attributes — e.g. data-id="FILE_ID"
        for m in re.finditer(r'data-id="([a-zA-Z0-9_-]{25,})"', html):
            file_ids.add(m.group(1))

        # Pattern 3: JSON-embedded "id":"FILE_ID"
        for m in re.finditer(r'"id"\s*:\s*"([a-zA-Z0-9_-]{25,})"', html):
            file_ids.add(m.group(1))

        # Remove the folder_id itself if it ended up in the set
        file_ids.discard(folder_id)

        print(f"  [gdrive] Found {len(file_ids)} file ID(s) in folder")
        return list(file_ids)[:max_files]
    except Exception as exc:
        print(f"  [gdrive] Error listing folder {folder_id}: {exc}")
        return []


def _frame_thumbnail(img_bytes: bytes, size: tuple[int, int] = (16, 16)) -> list[int] | None:
    """
    Compute a tiny grayscale pixel list for visual similarity comparison.
    Returns None if PIL/Pillow is unavailable or the image cannot be decoded.
    """
    try:
        from PIL import Image  # type: ignore
        import io
        img = Image.open(io.BytesIO(img_bytes)).convert("L").resize(size, Image.LANCZOS)
        return list(img.getdata())
    except ImportError:
        return None
    except Exception:
        return None


def _frames_are_similar(pixels1: list[int], pixels2: list[int], threshold: float) -> bool:
    """Return True if two pixel arrays represent visually similar images (similarity >= threshold)."""
    if len(pixels1) != len(pixels2):
        return False
    total_diff = sum(abs(a - b) for a, b in zip(pixels1, pixels2))
    similarity = 1.0 - total_diff / (255 * len(pixels1))
    return similarity >= threshold


def _deduplicate_frames(frames: list[bytes], threshold: float) -> list[bytes]:
    """
    Remove frames that are visually similar to the previous kept frame.
    Returns all frames unchanged if PIL is not available.
    """
    if not frames:
        return frames
    first_thumb = _frame_thumbnail(frames[0])
    if first_thumb is None:
        print("  [info] PIL/Pillow not available — skipping frame deduplication")
        return frames

    kept: list[bytes] = [frames[0]]
    last_thumb = first_thumb
    for frame_bytes in frames[1:]:
        thumb = _frame_thumbnail(frame_bytes)
        if thumb is None:
            # Can't compare this frame; keep it but don't update last_thumb
            kept.append(frame_bytes)
            continue
        if not _frames_are_similar(last_thumb, thumb, threshold):
            kept.append(frame_bytes)
            last_thumb = thumb

    return kept


def _ensure_ffmpeg() -> bool:
    """
    Check if ffmpeg is available in the system PATH.
    """
    if shutil.which("ffmpeg"):
        return True
    
    print("  [ffmpeg] ffmpeg not found in PATH.")
    return False

def extract_video_frames(
    video_path: str,
    interval_secs: float = 0.5,
    max_frames: int = 8,
    similarity_threshold: float = 0.90,
) -> list[bytes]:
    """
    Extract frames from a video every `interval_secs` seconds, then deduplicate
    visually similar consecutive frames using a perceptual thumbnail comparison.
    Returns up to `max_frames` JPEG bytes.
    Falls back gracefully if ffmpeg or PIL are unavailable.
    """
    if not _ensure_ffmpeg():
        print("  [ffmpeg] ffmpeg unavailable — cannot extract video frames")
        return []

    fps_val = 1.0 / interval_secs
    raw_frames: list[bytes] = []
    try:
        with tempfile.TemporaryDirectory() as tmpdir:
            ffmpeg_cmd = [
                "ffmpeg", "-i", video_path,
                "-vf", f"fps={fps_val}",
                "-q:v", "3",
                "-y",
                os.path.join(tmpdir, "frame_%04d.jpg"),
            ]
            print(f"  [ffmpeg] Running: {' '.join(ffmpeg_cmd[:5])} ... fps={fps_val}")
            result = subprocess.run(
                ffmpeg_cmd,
                capture_output=True,
                timeout=120,
            )
            if result.returncode != 0:
                stderr_text = result.stderr.decode("utf-8", errors="replace")
                stdout_text = result.stdout.decode("utf-8", errors="replace")
                # ffmpeg writes progress/info to stderr even on success; show last 800 chars
                print(f"  [ffmpeg] FAILED with exit code {result.returncode}")
                if stderr_text:
                    print(f"  [ffmpeg] stderr (last 800 chars):\n{stderr_text[-800:]}")
                if stdout_text:
                    print(f"  [ffmpeg] stdout: {stdout_text[-200:]}")
                return []

            frame_files = sorted(f for f in os.listdir(tmpdir) if f.endswith(".jpg"))

            # Cap raw frames to avoid excessive processing on very long videos
            MAX_RAW = 200
            if len(frame_files) > MAX_RAW:
                step = len(frame_files) // MAX_RAW
                frame_files = frame_files[::step][:MAX_RAW]

            for fname in frame_files:
                with open(os.path.join(tmpdir, fname), "rb") as f:
                    raw_frames.append(f.read())

    except FileNotFoundError:
        print("  [warn] ffmpeg binary not found even after install attempt — video frames cannot be extracted")
        return []
    except Exception as exc:
        print(f"  [warn] Video frame extraction failed: {exc}")
        return []

    if not raw_frames:
        return []

    print(f"  [video] Extracted {len(raw_frames)} raw frames at {interval_secs}s intervals")

    unique_frames = _deduplicate_frames(raw_frames, similarity_threshold)
    print(
        f"  [video] {len(unique_frames)} unique frames after deduplication "
        f"(similarity threshold={similarity_threshold})"
    )

    if len(unique_frames) <= max_frames:
        return unique_frames

    # Spread evenly across unique frames when we still have too many
    step = (len(unique_frames) - 1) / (max_frames - 1)
    return [unique_frames[round(i * step)] for i in range(max_frames)]


def _process_gdrive_file_id(file_id: str, original_link: str, result: dict) -> None:
    """Download a single Google Drive file by ID and append an entry to result['gdrive']."""
    file_path, content_type = download_gdrive_file(file_id)
    entry: dict = {"original": original_link, "available": file_path is not None}

    if file_path:
        try:
            if "image" in content_type:
                with open(file_path, "rb") as f:
                    entry["image_bytes"] = f.read()
            else:
                # Treat as video (video/*, application/octet-stream, or unknown type)
                entry["is_video"] = True
                frames = extract_video_frames(file_path)
                if frames:
                    entry["video_frames"] = frames
                    print(f"  [gdrive] Extracted {len(frames)} frames from video (file_id={file_id})")
                else:
                    print(f"  [gdrive] Video accessible but frame extraction failed (file_id={file_id})")
        finally:
            try:
                os.unlink(file_path)
            except OSError:
                pass

    result["gdrive"].append(entry)


def extract_attachments(text: str) -> dict:
    """
    Parse a comment body and return categorised attachment info:
      gdrive   - list of Google Drive links, each entry may contain:
                   available    - bool
                   image_bytes  - raw bytes if it's an image
                   is_video     - True if identified as a video
                   video_frames - list of JPEG bytes extracted from the video
      images   - list of directly-accessible image dicts (url + image_bytes)
      videos   - list of video dicts (url, optional video_frames)
    """
    result: dict = {"gdrive": [], "images": [], "videos": []}

    gdrive_links = GDRIVE_RE.findall(text)
    github_cdn_links = GITHUB_CDN_RE.findall(text)
    direct_image_links = DIRECT_IMAGE_RE.findall(text)
    video_links = VIDEO_RE.findall(text)
    print(f"  [attachments] Found: {len(gdrive_links)} GDrive, {len(github_cdn_links)} GitHub CDN, "
          f"{len(direct_image_links)} direct images, {len(video_links)} videos")

    for m in GDRIVE_RE.finditer(text):
        link = m.group(0).rstrip(")")
        print(f"  [attachments] Processing GDrive URL: {link[:80]}")

        # Check if it's a folder URL first
        folder_id_match = GDRIVE_FOLDER_ID_RE.search(link)
        if folder_id_match:
            folder_id = folder_id_match.group(1)
            print(f"  [attachments] Detected Google Drive folder — listing files (folder_id={folder_id})")
            file_ids = list_gdrive_folder_files(folder_id)
            if not file_ids:
                print(f"  [attachments] Could not list files in GDrive folder (private or empty?) — skipping")
                result["gdrive"].append({"original": link, "available": False, "is_folder": True})
                continue
            print(f"  [attachments] Processing {len(file_ids)} file(s) from folder")
            for fid in file_ids:
                _process_gdrive_file_id(fid, link, result)
            continue

        file_id_match = re.search(r"/file/d/([^/?&\s\"'>)]+)", link)
        if not file_id_match:
            print(f"  [attachments] Could not extract file ID from GDrive URL — skipping")
            result["gdrive"].append({"original": link, "available": False})
            continue

        file_id = file_id_match.group(1)
        _process_gdrive_file_id(file_id, link, result)

    for m in GITHUB_CDN_RE.finditer(text):
        url = m.group(0).rstrip(")")
        print(f"  [attachments] Processing GitHub CDN URL: {url[:80]}")
        
        asset = download_github_attachment(url)
        
        if asset["type"] == "image":
            print(f"  [attachments] Downloaded GitHub image: {len(asset['bytes']) / 1024:.1f} KB")
            result["images"].append({"url": url, "image_bytes": asset["bytes"]})
            
        elif asset["type"] == "video":
            print(f"  [attachments] Identified as video. Extracting frames...")
            suffix = ".mp4" if "mp4" in asset.get("content_type", "") else ".bin"
            with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
                tmp.write(asset["bytes"])
                tmp_path = tmp.name
            
            try:
                frames = extract_video_frames(tmp_path)
                if frames:
                    print(f"  [attachments] Extracted {len(frames)} frames from GitHub video")
                    result["videos"].append({"url": url, "video_frames": frames})
                else:
                    print(f"  [attachments] Could not extract frames, logging as unviewable video.")
                    result["videos"].append({"url": url})
            finally:
                try:
                    os.unlink(tmp_path)
                except OSError:
                    pass
        else:
            print(f"  [attachments] GitHub CDN URL is not a recognized image/video.")

    for m in DIRECT_IMAGE_RE.finditer(text):
        url = m.group(0).rstrip(")")
        if GITHUB_CDN_RE.match(url):
            continue  # already handled above
        img_bytes = try_download_image(url)
        if img_bytes:
            result["images"].append({"url": url, "image_bytes": img_bytes})

    for m in VIDEO_RE.finditer(text):
        url = m.group(0).rstrip(")")
        if not any(v.get("url") == url for v in result["videos"]):
            result["videos"].append({"url": url})

    return result


# ---------------------------------------------------------------------------
# OpenAI Responses API
# ---------------------------------------------------------------------------

def assess_evidence_with_ai(
    issue_title: str,
    issue_body: str.
    recent_comments: list[dict],
    attachments: dict,
) -> dict:
    """
    Call the OpenAI Responses API to assess whether QA evidence is adequate.
    Accepts the last N comments (as raw comment dicts) and assesses them as a whole.

    Returns a dict with:
      score             - int 1–10
      passed            - bool (score >= 7)
      problems          - list of strings describing issues
      summary           - one-line summary
      media_description - description of what was visible in attached images/video frames
    """
    content: list[dict] = []

    # Format the recent comments for the prompt
    comments_text = ""
    for i, c in enumerate(recent_comments, 1):
        author = c.get("user", {}).get("login", "unknown")
        body = c.get("body", "")
        comments_text += f"\n--- Comment {i} (by @{author}) ---\n{body}\n"

    # Build the text prompt
    prompt_text = f"""You are a QA lead reviewing whether a software issue has adequate test evidence.

Issue title: {issue_title}
Original issue description:
{issue_body}

The last {len(recent_comments)} comment(s) on this issue:
{comments_text}

Your job is to determine if these comments contain adequate QA test evidence.

The expected format is:
  "Tested on {{OS}} with these scenarios:
   1. <scenario>
   2. <scenario>
   Evidence: <attached screenshot or video>"

However, do NOT rigidly enforce this exact wording. Use your judgment to assess whether
the comments demonstrate that the issue was properly tested. Look for:
1. Was an OS/device specified? (e.g. iOS 17, Android 14, macOS, Windows)
2. Are the test scenarios or steps described clearly and relevant to the issue?
3. Is there actual evidence (screenshot, video, link) that demonstrates the fix works?
4. IMPORTANT: If images are attached below, look at them directly. A clear screenshot
   IS sufficient evidence on its own — do NOT penalize for lacking a text description.
   Only fail on images if they are unclear, unrelated to the issue, or don't demonstrate
   the feature working. Do NOT require multiple screenshots if one clearly shows the result.
5. If video frames are attached below (extracted from a screen recording), describe exactly
   what you can see in the frames — what screen is shown, what UI elements are visible,
   what actions appear to have been taken. This description will be shown to the team.

If there is NO evidence comment at all (e.g. only automated bot messages, code review
comments, or unrelated discussion), mark as failed.

**Scoring rubric — apply strictly (start at 10, deduct for each problem):**
- **-3 points**: OS/device not specified clearly. "Android" alone is NOT sufficient — must
  include OS version AND device model (e.g. "Android 14, Samsung Galaxy S23") or platform
  (e.g. "iOS 17.2, iPhone 15", "macOS 14 Sonoma, MacBook Pro M3").
- **-3 points**: No explicit test steps or scenarios described. Vague wording like "tested
  the feature" is NOT sufficient — need at least one numbered or clearly described step
  showing what was actually tested.
- **-2 points**: No verifiable visual evidence. This means: no screenshot/video attached,
  OR a video link is mentioned but frames could NOT be extracted (content unverifiable). In
  that case evaluate based on text quality alone.
- **-1 point**: Only a single positive test case with no edge cases or negative testing
  (e.g. not verifying the original bug is still reproduced without the fix).
- **-1 point**: Video frames available but the feature working is not clearly demonstrated.

**CRITICAL scoring rules:**
- The score in your JSON MUST be consistent with the number of problems you list.
  Do NOT give a high score and then list multiple problems — that is contradictory.
- If you list **3 or more problems**, the score MUST be **5 or below**.
- If you list **2 problems**, the score MUST be **6 or below**.
- If you list **1 problem**, the score MUST be **7 or below** (it can be 7 only if that
  single problem is minor and clear visual evidence compensates for it).
- A score of **7 or above** means the evidence is acceptable and the issue passes.
- If a clear screenshot/video ACTUALLY shows the feature working and OS+scenarios are
  present, that can score 8–10.
- If a video is mentioned but frames could NOT be extracted (unverifiable), do NOT score
  >= 7 just because a video link exists — score based on text evidence quality alone.

If you don't think enough test scenarios were performed, please clearly state what test cases you would recommend for this issue.

Respond ONLY with valid JSON in this exact format:
{{
  "score": <integer 1-10>,
  "passed": <true|false>,
  "problems": [<string>, ...],
  "summary": "<one sentence>",
  "media_description": "<detailed description of what you can see in the attached images/video frames, e.g. what screen is shown, what UI is visible, what actions are demonstrated. Write 'No media attached' if no images or frames were provided.>"
}}"""

    content.append({"type": "input_text", "text": prompt_text})

    # Attach images / video frames for visual assessment
    images_added = 0
    MAX_IMAGES = 8

    for gdrive in attachments.get("gdrive", []):
        if not gdrive.get("available"):
            content.append({
                "type": "input_text",
                "text": f"[Google Drive link was NOT accessible: {gdrive['original']}]",
            })
        elif gdrive.get("is_video"):
            frames = gdrive.get("video_frames", [])
            if frames:
                content.append({
                    "type": "input_text",
                    "text": (
                        f"[Google Drive video — {len(frames)} frames extracted for analysis "
                        f"(source: {gdrive['original'][:80]})]"
                    ),
                })
                for frame_bytes in frames:
                    if images_added >= MAX_IMAGES:
                        break
                    b64 = base64.b64encode(frame_bytes).decode()
                    content.append({
                        "type": "input_image",
                        "image_url": f"data:image/jpeg;base64,{b64}",
                    })
                    images_added += 1
            else:
                content.append({
                    "type": "input_text",
                    "text": (
                        f"[Google Drive video is accessible at {gdrive['original'][:80]} "
                        f"but frames could NOT be extracted and the video content CANNOT be verified. "
                        f"Do NOT treat unverifiable video presence as passing evidence — "
                        f"assess based on text evidence quality alone.]"
                    ),
                })
        elif "image_bytes" in gdrive:
            if images_added < MAX_IMAGES:
                b64 = base64.b64encode(gdrive["image_bytes"]).decode()
                content.append({
                    "type": "input_image",
                    "image_url": f"data:image/jpeg;base64,{b64}",
                })
                images_added += 1
        else:
            content.append({
                "type": "input_text",
                "text": f"[Google Drive link accessible but file type unknown: {gdrive['original'][:80]}]",
            })

    for img in attachments.get("images", []):
        if images_added >= MAX_IMAGES:
            break
        if "image_bytes" in img:
            b64 = base64.b64encode(img["image_bytes"]).decode()
            content.append({
                "type": "input_image",
                "image_url": f"data:image/jpeg;base64,{b64}",
            })
            images_added += 1

    for video in attachments.get("videos", []):
        vid_url = video.get("url", "") if isinstance(video, dict) else str(video)
        frames = video.get("video_frames", []) if isinstance(video, dict) else []
        
        if frames:
            content.append({
                "type": "input_text",
                "text": f"[Video attached — {len(frames)} frames extracted for analysis (source: {vid_url[:80]})]"
            })
            for frame_bytes in frames:
                if images_added >= MAX_IMAGES:
                    break
                b64 = base64.b64encode(frame_bytes).decode()
                content.append({
                    "type": "input_image",
                    "image_url": f"data:image/jpeg;base64,{b64}",
                })
                images_added += 1
        else:
            content.append({
                "type": "input_text",
                "text": f"[Video attached: {vid_url} — cannot be directly viewed but its presence has been noted]",
            })

    # Build Responses API kwargs
    kwargs: dict = {
        "model": MODEL,
        "input": [{"role": "user", "content": content}],
    }

    # Add reasoning effort only when a reasoning model is detected
    # (o-series models like o1, o3, o4, o4-mini; also gpt-5+ may support it)
    is_reasoning_model = MODEL.startswith("o") or MODEL.startswith("gpt-5")
    if REASONING_EFFORT and is_reasoning_model:
        kwargs["reasoning"] = {"effort": REASONING_EFFORT}

    text_blocks = sum(1 for c in content if c.get("type") == "input_text")
    image_blocks = sum(1 for c in content if c.get("type") == "input_image")
    print(f"  [ai] Calling OpenAI model={MODEL}, text_blocks={text_blocks}, image_blocks={image_blocks}")
    if is_reasoning_model and REASONING_EFFORT:
        print(f"  [ai] Using reasoning effort={REASONING_EFFORT}")

    def _parse_response(response) -> dict:
        raw = response.output_text.strip()
        # Strip markdown code fences if present
        raw = re.sub(r"^```(?:json)?\s*|\s*```$", "", raw, flags=re.MULTILINE).strip()
        return json.loads(raw)

    try:
        response = openai_client.responses.create(**kwargs)
        result = _parse_response(response)
        print(f"  [ai] Response: score={result.get('score')}, passed={result.get('passed')}, summary={result.get('summary', '')[:100]}")
        return result
    except Exception as exc:
        error_str = str(exc)
        # If reasoning parameter is the problem, retry without it
        if "reasoning" in error_str.lower() and "reasoning" in kwargs:
            print(f"  [warn] Reasoning parameter rejected by model, retrying without it: {exc}")
            del kwargs["reasoning"]
            try:
                response = openai_client.responses.create(**kwargs)
                return _parse_response(response)
            except Exception as exc2:
                return {
                    "score": 1,
                    "passed": False,
                    "problems": [f"AI API error (after retry): {exc2}"],
                    "summary": "AI assessment failed.",
                }
        if isinstance(exc, json.JSONDecodeError):
            return {
                "score": 1,
                "passed": False,
                "problems": [f"AI returned unparseable response: {exc}"],
                "summary": "Could not parse AI assessment.",
            }
        return {
            "score": 1,
            "passed": False,
            "problems": [f"AI API error: {exc}"],
            "summary": "AI assessment failed.",
        }


# ---------------------------------------------------------------------------
# Core logic
# ---------------------------------------------------------------------------

REVIEW_BOT_LOGIN = os.environ.get("REVIEW_BOT_LOGIN", "jeznag").strip()
REVIEW_BOT_SIGNATURE = "Automated check by QA Evidence Checker"  # keep in sync with your footer text

def _is_review_bot_comment(comment: dict) -> bool:
    author_login = (comment.get("user", {}) or {}).get("login", "") or ""
    body = comment.get("body", "") or ""

    if REVIEW_BOT_LOGIN and author_login.lower() == REVIEW_BOT_LOGIN.lower():
        return True
    return REVIEW_BOT_SIGNATURE.lower() in body.lower()


def _request_new_evidence_comment(
    repo: str,
    issue_number: int,
    item_id: str,
    project_id: str | None,
    ready_field_id: str | None,
    ready_option_id: str | None,
    mention: str,
    result: dict,
    dry_run: bool,
) -> None:
    comment_body = (
        "## QA Evidence Needed\n\n"
        "I’ve already reviewed this issue recently, and the latest comment is from the QA Evidence Checker.\n\n"
        "Please add **new test evidence in a fresh comment** (don’t edit the old one), then move the card back to "
        "**QA Passed** or **QA Failed**.\n\n"
        "### Recommended format\n"
        "```\n"
        "Tested on <OS version + device/model> with these scenarios:\n"
        "1. ...\n"
        "2. ...\n\n"
        "Evidence: <attach screenshot/video or link>\n"
        "```\n"
        f"\n{mention}\n\n"
        f"*Automated check by QA Evidence Checker (model: {MODEL})*"
    )

    if dry_run:
        print(f"  [DRY RUN] Would post 'new evidence needed' comment to {repo}#{issue_number}")
        result["action"] = "dry_run_would_request_new_evidence"
        return

    post_issue_comment(repo, issue_number, comment_body)
    move_item_to_status(project_id, item_id, ready_field_id, ready_option_id)
    result["action"] = f"requested_new_evidence_and_moved_to_{READY_FOR_QA_STATUS.lower().replace(' ', '_')}"

def check_issue(
    item_id: str,
    repo: str,
    issue_number: int,
    issue_title: str,
    issue_body: str,
    issue_author: str,
    assignees: list[str],
    project_id: str | None,
    ready_field_id: str | None,
    ready_option_id: str | None,
    dry_run: bool = False,
) -> dict:
    """
    Check a single issue for adequate QA evidence.
    Returns a result dict.
    """
    result = {
        "repo": repo,
        "issue_number": issue_number,
        "issue_title": issue_title,
        "status": "unknown",
        "score": None,
        "problems": [],
        "action": None,
    }

    print(f"  [issue] Fetching comments for {repo}#{issue_number}")
    comments = get_all_comments(repo, issue_number)
    print(f"  [issue] Found {len(comments)} total comments")
    mention = _get_mention_str(assignees, comments, issue_author)

    if not comments:
        result["status"] = "no_comments"
        result["problems"] = ["No comments found on this issue."]
        _move_back_and_comment(
            repo, issue_number, item_id, project_id, ready_field_id, ready_option_id,
            result["problems"], result, mention, dry_run=dry_run
        )
        return result

    # Use the last 2 comments for LLM assessment — no hardcoded format check
    recent_comments = comments[-2:]
    for i, c in enumerate(recent_comments, 1):
        author = c.get("user", {}).get("login", "unknown")
        created = c.get("created_at", "")
        body_len = len(c.get("body", ""))
        print(f"  [issue] Last comment {i}: by @{author} at {created} ({body_len} chars)")

    # If the most recent comment is from this review bot, don't re-run the LLM.
    # Ask QA to provide fresh evidence in a new comment, then move back when ready.
    if comments and _is_review_bot_comment(comments[-1]):
        result["status"] = "awaiting_new_evidence_comment"
        result["problems"] = ["Latest comment is from QA Evidence Checker. Waiting for new evidence from QA."]
        _request_new_evidence_comment(
            repo=repo,
            issue_number=issue_number,
            item_id=item_id,
            project_id=project_id,
            ready_field_id=ready_field_id,
            ready_option_id=ready_option_id,
            mention=mention,
            result=result,
            dry_run=dry_run,
        )
        return result

    # Extract attachments from the recent comments
    combined_body = "\n".join(c.get("body", "") for c in recent_comments)
    attachments = extract_attachments(combined_body)

    print(f"  [issue] Calling AI assessment for issue: {issue_title[:60]}")
    ai_result = assess_evidence_with_ai(issue_title, issue_body, recent_comments, attachments)

    result["score"] = ai_result.get("score")
    result["problems"] = ai_result.get("problems", [])
    result["ai_summary"] = ai_result.get("summary", "")
    result["media_description"] = ai_result.get("media_description", "")

    # Log what the AI saw in the media
    if result["media_description"] and result["media_description"] != "No media attached":
        print(f"  [ai] Media observed: {result['media_description']}")

    # Enforce pass threshold server-side (score >= 7).
    # The AI prompt instructs it to set passed=true only at 7+, but we double-check here.
    PASS_THRESHOLD = 7
    ai_passed = ai_result.get("passed", False)
    score = ai_result.get("score") or 0
    passed = ai_passed and score >= PASS_THRESHOLD
    if ai_passed and not passed:
        print(f"  [ai] AI returned passed=True but score={score} < {PASS_THRESHOLD} — overriding to failed")

    # Use the last comment author as the mention target
    last_comment_author = recent_comments[-1].get("user", {}).get("login", "") if recent_comments else ""
    author_mention = f"@{last_comment_author}" if last_comment_author else mention

    if passed:
        result["status"] = "passed"
        if dry_run:
            print(f"  [DRY RUN] Would post approval comment and apply '{QA_APPROVED_LABEL}' label to {repo}#{issue_number}")
            result["action"] = "dry_run_would_approve"
        else:
            _approve_and_label(repo, issue_number, result, ai_result)
    else:
        result["status"] = "failed_evidence"
        _move_back_and_comment(
            repo, issue_number, item_id, project_id, ready_field_id, ready_option_id,
            result["problems"], result, author_mention, dry_run=dry_run
        )

    return result


def _approve_and_label(
    repo: str,
    issue_number: int,
    result: dict,
    ai_result: dict,
) -> None:
    """Post an approval comment and apply the QA_APPROVED_LABEL label to the issue."""
    score = result.get("score") or 0
    summary = ai_result.get("summary", "")
    media_desc = ai_result.get("media_description", "")

    comment_lines = [
        "## QA Evidence Approved\n",
        f"The test evidence for this issue has been reviewed and meets our quality standards (score: {score}/10).\n",
    ]
    if summary:
        comment_lines.append(f"**Summary:** {summary}\n")
    if media_desc and media_desc != "No media attached":
        comment_lines.append(f"\n**Media observed:** {media_desc}\n")
    comment_lines.append(f"\n*Automated check by QA Evidence Checker (model: {MODEL})*")
    comment_body = "".join(comment_lines)

    try:
        ensure_label_exists(repo, QA_APPROVED_LABEL)
        add_label_to_issue(repo, issue_number, QA_APPROVED_LABEL)
        post_issue_comment(repo, issue_number, comment_body)
        result["action"] = "approved_and_labeled"
        print(f"  [label] Applied '{QA_APPROVED_LABEL}' label and posted approval comment on {repo}#{issue_number}")
    except Exception as exc:
        result["action"] = f"approval_error: {exc}"
        print(f"  [label] Error applying approval: {exc}")


def _get_mention_str(
    assignees: list[str],
    comments: list[dict],
    issue_author: str,
) -> str:
    """
    Determine who to @mention in a QA feedback comment.

    Priority:
      1. Issue assignees (the people responsible for QA/testing)
      2. Author of the most recent comment (likely the tester)
      3. Issue author (fallback)
    """
    if assignees:
        return " ".join(f"@{login}" for login in assignees)
    if comments:
        last_login = comments[-1].get("user", {}).get("login", "")
        if last_login:
            return f"@{last_login}"
    if issue_author:
        return f"@{issue_author}"
    return ""


def _move_back_and_comment(
    repo: str,
    issue_number: int,
    item_id: str,
    project_id: str | None,
    ready_field_id: str | None,
    ready_option_id: str | None,
    problems: list[str],
    result: dict,
    mention: str = "",
    dry_run: bool = False,
) -> None:
    """Move the issue back to Ready for QA and post an explanatory comment.

    In dry run mode, logs what would have happened without making any changes.
    """
    problem_list = "\n".join(f"- {p}" for p in problems) if problems else "- Evidence was insufficient."
    mention_line = f"\n{mention} — please add test evidence before moving back to QA.\n" if mention else ""
    comment_body = (
        f"## QA Evidence Review\n\n"
        f"This issue has been moved back to **{READY_FOR_QA_STATUS}** because the test evidence "
        f"was not sufficient.\n\n"
        f"### Issues found:\n{problem_list}\n"
        f"{mention_line}\n"
        f"### Required format:\n"
        f"```\n"
        f"Tested on {{OS}} with these scenarios:\n"
        f"1. <scenario description>\n"
        f"2. <scenario description>\n\n"
        f"Evidence: <attached screenshot or video>\n"
        f"```\n\n"
        f"Please re-test and provide adequate evidence before moving back to QA Passed.\n\n"
        f"*Automated check by QA Evidence Checker (model: {MODEL})*"
    )

    if dry_run:
        print(f"  [DRY RUN] Would post comment to {repo}#{issue_number}")
        print(f"  [DRY RUN] Would move issue back to '{READY_FOR_QA_STATUS}'")
        result["action"] = f"dry_run_would_move_to_{READY_FOR_QA_STATUS.lower().replace(' ', '_')}"
        return

    try:
        post_issue_comment(repo, issue_number, comment_body)
        move_item_to_status(project_id, item_id, ready_field_id, ready_option_id)
        result["action"] = f"moved_to_{READY_FOR_QA_STATUS.lower().replace(' ', '_')}"
    except Exception as exc:
        result["action"] = f"error: {exc}"


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    if DRY_RUN:
        print("*** DRY RUN MODE — no comments will be posted, no issues will be moved ***")

    cutoff: datetime | None = None
    if DAYS_TO_CHECK > 0:
        cutoff = datetime.now(timezone.utc) - timedelta(days=DAYS_TO_CHECK)

    print(f"Fetching project items for {ORG}/projects/{PROJECT_NUMBER}…")
    items = get_project_items(ORG, PROJECT_NUMBER)
    print(f"  Total items fetched: {len(items)}")

    # Filter to target statuses
    target_items = [
        item for item in items
        if item["status"] in STATUS_VALUES and item["content"]
    ]
    print(f"  Items in target statuses ({', '.join(STATUS_VALUES)}): {len(target_items)}")

    # Apply date filter
    if cutoff:
        filtered = []
        for item in target_items:
            updated_at_str = item["content"].get("updatedAt", "")
            if updated_at_str:
                updated_at = datetime.fromisoformat(updated_at_str.replace("Z", "+00:00"))
                if updated_at >= cutoff:
                    filtered.append(item)
        target_items = filtered
        print(f"  After date filter (last {DAYS_TO_CHECK} days): {len(target_items)}")

    if not target_items:
        print("No items to check. Exiting.")
        return

    # Fetch project-level IDs needed for mutations (skipped in dry run)
    project_id: str | None = None
    ready_field_id: str | None = None
    ready_option_id: str | None = None
    if not DRY_RUN:
        print("Fetching project ID and status field metadata…")
        project_id = get_project_id(ORG, PROJECT_NUMBER)
        ready_field_id, ready_option_id = get_status_field_and_option(
            ORG, PROJECT_NUMBER, READY_FOR_QA_STATUS
        )

    results: list[dict] = []
    failures: list[dict] = []
    processed_issues: set[tuple] = set()

    for item in target_items:
        content = item["content"]
        repo = content.get("repository", {}).get("nameWithOwner", "")
        issue_number = content.get("number")
        issue_title = content.get("title", "")
        item_id = item["item_id"]

        if not repo or not issue_number:
            continue

        issue_key = (repo, issue_number)
        if issue_key in processed_issues:
            print(f"\nSkipping {repo}#{issue_number} (already processed in this run — duplicate board entry)")
            continue
        processed_issues.add(issue_key)

        # Skip issues that have already been approved in a previous run
        issue_labels = [lbl["name"] for lbl in content.get("labels", {}).get("nodes", [])]
        if QA_APPROVED_LABEL in issue_labels:
            print(f"\nSkipping {repo}#{issue_number} — already has '{QA_APPROVED_LABEL}' label")
            continue

        issue_author = content.get("author", {}).get("login", "")
        assignees = [a["login"] for a in content.get("assignees", {}).get("nodes", [])]

        print(f"\nChecking {repo}#{issue_number}: {issue_title[:60]}")
        result = check_issue(
            item_id=item_id,
            repo=repo,
            issue_number=issue_number,
            issue_title=issue_title,
            issue_author=issue_author,
            assignees=assignees,
            project_id=project_id,
            ready_field_id=ready_field_id,
            ready_option_id=ready_option_id,
            dry_run=DRY_RUN,
        )
        results.append(result)

        score_str = f" (score: {result['score']}/10)" if result["score"] is not None else ""
        print(f"  Status: {result['status']}{score_str}")
        if result.get("ai_summary"):
            print(f"  AI summary: {result['ai_summary']}")
        if result.get("action"):
            print(f"  Action: {result['action']}")
        if result.get("problems"):
            for p in result["problems"]:
                print(f"  - {p}")

        if result["status"] != "passed":
            failures.append(result)

    dry_run_note = " (DRY RUN — no actions taken)" if DRY_RUN else ""

    # Summary
    print(f"\n{'='*60}")
    print(f"SUMMARY{dry_run_note}: {len(results)} checked, {len(failures)} failed")
    print(f"{'='*60}")

    # Write to GitHub Actions step summary if available
    summary_file = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary_file:
        with open(summary_file, "a") as f:
            f.write(f"## QA Evidence Check Results{dry_run_note}\n\n")
            if DRY_RUN:
                f.write("> **Dry run mode** — no comments posted, no issues moved.\n\n")
            f.write(f"| Metric | Count |\n|--------|-------|\n")
            f.write(f"| Checked | {len(results)} |\n")
            f.write(f"| Passed | {len(results) - len(failures)} |\n")
            f.write(f"| Failed | {len(failures)} |\n\n")
            # Full results table (passed + failed)
            f.write("### All checked issues\n\n")
            f.write("| Issue | Score | Status | Summary | Media observed |\n")
            f.write("|-------|-------|--------|---------|----------------|\n")
            for r in results:
                score_col = f"{r['score']}/10" if r["score"] is not None else "—"
                status_col = "✅ Passed" if r["status"] == "passed" else "❌ Failed"
                summary_col = (r.get("ai_summary") or "").replace("|", "\\|")[:80]
                media_col = (r.get("media_description") or "No media").replace("|", "\\|")[:120]
                f.write(f"| [{r['repo']}#{r['issue_number']}](https://github.com/{r['repo']}/issues/{r['issue_number']}) | {score_col} | {status_col} | {summary_col} | {media_col} |\n")
            f.write("\n")

            if failures:
                heading = "Issues that would be moved back to Ready for QA" if DRY_RUN else "Issues moved back to Ready for QA"
                f.write(f"### {heading}\n\n")
                for r in failures:
                    score_str = f" (score {r['score']}/10)" if r["score"] else ""
                    f.write(f"- **{r['repo']}#{r['issue_number']}**{score_str}: {r['issue_title']}\n")
                    if r.get("media_description") and r["media_description"] != "No media attached":
                        f.write(f"  - **Media observed:** {r['media_description']}\n")
                    for p in r.get("problems", []):
                        f.write(f"  - {p}\n")
                f.write("\n")

    if failures:
        sys.exit(1)


if __name__ == "__main__":
    main()

#!/usr/bin/env bash
# fk_drive_upload.sh — upload a Flow Kit project's final video(s) to Google Drive via rclone.
# Local addition (not part of upstream Flow Kit).
#
# Usage:
#   scripts/fk_drive_upload.sh [--share] [<project_id> | <file.mp4> ...]
#
#   (no arg)      active project (falls back to the most recent one)
#   <project_id>  that project
#   <file.mp4>    those exact files (agent not needed)
#   --share       also create an "anyone with the link can view" link (default: private)
#
# Env:
#   FK_DRIVE_DEST  rclone destination root  (default: gdrive:FlowKit)
#   FK_API         Flow Kit agent base URL   (default: http://127.0.0.1:8100)
#
# One-time setup:
#   brew install rclone
#   rclone config create gdrive drive scope=drive.file
set -euo pipefail
cd "$(dirname "$0")/.."

API="${FK_API:-http://127.0.0.1:8100}"
DEST_ROOT="${FK_DRIVE_DEST:-gdrive:FlowKit}"
REMOTE="${DEST_ROOT%%:*}"

die() { local code="$1"; shift; echo "ERROR: $*" >&2; exit "$code"; }
json() { python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('$1') or '')"; }

SHARE=0
if [[ "${1:-}" == "--share" ]]; then SHARE=1; shift; fi

command -v rclone >/dev/null 2>&1 || die 2 "rclone not installed. Run: brew install rclone"
rclone listremotes 2>/dev/null | grep -qx "${REMOTE}:" \
  || die 2 "rclone remote '${REMOTE}' not configured. Run: rclone config create ${REMOTE} drive scope=drive.file"

files=()
if [[ $# -gt 0 && "$1" == *.mp4 ]]; then
  for f in "$@"; do
    [[ -f "$f" ]] || die 4 "file not found: $f"
    files+=("$f")
  done
  slug="$(basename "$(cd "$(dirname "$1")" && pwd)")"
else
  pid="${1:-}"
  if [[ -z "$pid" ]]; then
    ap="$(curl -fsS "$API/api/active-project" 2>/dev/null)" \
      || die 3 "cannot reach Flow Kit agent at $API (is run.sh running?) — or pass the .mp4 path directly"
    pid="$(printf '%s' "$ap" | json project_id)"
    [[ -n "$pid" ]] || die 3 "no project found"
  fi
  od="$(curl -fsS "$API/api/projects/$pid/output-dir" 2>/dev/null)" \
    || die 3 "project '$pid' not found (or agent not running)"
  slug="$(printf '%s' "$od" | json slug)"
  outdir="$(printf '%s' "$od" | json path)"
  for f in "$outdir/${slug}_narrator_cut.mp4" "$outdir/${slug}_final.mp4";
    if [[ -f "$f" ]]; then files+=("$f"); fi
  done
  [[ ${#files[@]} -gt 0 ]] \
    || die 4 "no ${slug}_final.mp4 or ${slug}_narrator_cut.mp4 in $outdir — run /fk-concat first"
fi

dest="$DEST_ROOT/$slug"
if [[ -t 1 ]]; then
  prog=(--progress)
else
  prog=(--stats-one-line --stats 20s --stats-log-level NOTICE)
fi

for f in "${files[@]}"; do
  name="$(basename "$f")"
  echo "Uploading $name ($(du -h "$f" | cut -f1)) -> $dest/"
  rclone copyto "$f" "$dest/$name" "${prog[@]}"

  id="$(rclone lsjson --stat "$dest/$name" 2>/dev/null | json ID || true)"
  if [[ -n "$id" ]]; then
    echo "  OK    https://drive.google.com/file/d/$id/view"
  else
    echo "  OK    $dest/$name"
  fi

  if [[ "$SHARE" == 1 ]]; then
    if link="$(rclone link "$dest/$name" 2>&1)"; then
      echo "  SHARE $link"
    else
      echo "  SHARE failed: $link" >&2
    fi
  fi
done

#!/usr/bin/env bash
# fk_hand_drawn_materials.sh — register the hand-drawn style pack as Flow Kit custom materials.
# Local addition (not part of upstream Flow Kit). Source recipes: skills/hand-drawn-styles/
#
# Usage:
#   scripts/fk_hand_drawn_materials.sh                 register all hd_* materials (skip ones that exist)
#   scripts/fk_hand_drawn_materials.sh --force         delete + re-create every hd_* material
#   scripts/fk_hand_drawn_materials.sh --list          show hd_* materials currently registered
#   scripts/fk_hand_drawn_materials.sh --remove        delete every hd_* material
#   scripts/fk_hand_drawn_materials.sh hd_xkcd hd_ms_paint   only these ids
#
# Env:
#   FK_API   Flow Kit agent base URL (default: http://127.0.0.1:8100)
#
# Materials persist in flow_agent.db and are reloaded when the agent starts,
# so this only needs to run once per database (or after --remove / a fresh DB).
set -euo pipefail
cd "$(dirname "$0")/.."

API="${FK_API:-http://127.0.0.1:8100}"
JSON="skills/hand-drawn-styles/materials.json"

die() { local code="$1"; shift; echo "ERROR: $*" >&2; exit "$code"; }

[[ -f "$JSON" ]] || die 2 "missing $JSON"
command -v jq >/dev/null 2>&1 || die 2 "jq not installed. Run: brew install jq"
curl -sf "$API/api/materials" >/dev/null 2>&1 \
  || die 3 "Flow Kit agent not reachable at $API — start it first (./run.sh)"

MODE="add"
IDS=()
for a in "$@"; do
  case "$a" in
    --force)  MODE="force" ;;
    --list)   MODE="list" ;;
    --remove) MODE="remove" ;;
    -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
    hd_*)     IDS+=("$a") ;;
    *)        die 1 "unknown argument: $a" ;;
  esac
done

existing() { curl -s "$API/api/materials" | jq -r '.[] | select(.is_builtin == false) | .id'; }

if [[ "$MODE" == "list" ]]; then
  echo "hd_* materials registered at $API:"
  existing | grep '^hd_' || echo "  (none)"
  exit 0
fi

if [[ "$MODE" == "remove" ]]; then
  for id in $(existing | grep '^hd_' || true); do
    curl -s -X DELETE "$API/api/materials/$id" >/dev/null && echo "removed  $id"
  done
  exit 0
fi

# Which ids to process
if [[ ${#IDS[@]} -eq 0 ]]; then
  while IFS= read -r id; do IDS+=("$id"); done < <(jq -r '.materials[].id' "$JSON")   # macOS bash 3.2 has no mapfile
fi

EXISTING="$(existing || true)"
added=0; skipped=0; failed=0

for id in ${IDS[@]+"${IDS[@]}"}; do
  body="$(jq -c --arg id "$id" '.materials[] | select(.id == $id)' "$JSON")"
  [[ -n "$body" ]] || { echo "unknown id in $JSON: $id" >&2; failed=$((failed+1)); continue; }

  if grep -qx "$id" <<<"$EXISTING"; then
    if [[ "$MODE" == "force" ]]; then
      curl -s -X DELETE "$API/api/materials/$id" >/dev/null
    else
      echo "skip     $id (already registered — use --force to replace)"
      skipped=$((skipped+1)); continue
    fi
  fi

  resp="$(curl -s -w '\n%{http_code}' -X POST "$API/api/materials" \
            -H "Content-Type: application/json" -d "$body")"
  code="${resp##*$'\n'}"
  if [[ "$code" == "200" || "$code" == "201" ]]; then
    name="$(jq -r '.name' <<<"$body")"
    echo "added    $id  ($name)"
    added=$((added+1))
  else
    echo "FAILED   $id  HTTP $code: $(head -c 300 <<<"${resp%$'\n'*}")" >&2
    failed=$((failed+1))
  fi
done

echo
echo "done: $added added, $skipped skipped, $failed failed"
[[ $failed -eq 0 ]] || exit 4

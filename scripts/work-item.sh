#!/usr/bin/env bash
# work-item.sh: one command, three tracking backends (GitHub Issues, Jira,
# Azure DevOps). The loop's phase docs and skills call this script, never a
# backend CLI directly, so swapping trackers is a config change.
#
# Usage:
#   scripts/work-item.sh create "Summary" [--body "context"] [--type task|bug|story]
#   scripts/work-item.sh comment  <id> "what changed and the evidence"
#   scripts/work-item.sh transition <id> "<state>"
#   scripts/work-item.sh link <id> <url>
#   WORK_BACKEND=gh|jira|ado selects the backend (.env or environment)
#
# Configuration shape: docs/templates/work-item.example.env
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() { sed -n '2,13p' "$0"; }
die() { echo "error: $*" >&2; exit 1; }

# Load .env from the repo root if present (never committed; see security std).
if [ -f "$root/.env" ]; then
  # shellcheck source=/dev/null
  . "$root/.env"
fi

backend="${WORK_BACKEND:-gh}"
cmd="${1:-}"
[ -n "$cmd" ] || { usage; exit 2; }
shift || true

case "$backend" in
  gh) ;;
  jira) ;;
  ado) ;;
  *) die "WORK_BACKEND must be gh, jira, or ado (got '$backend')" ;;
esac

# ---------------------------------------------------------------- GitHub ---
gh_create() {
  local summary="$1" body="${2:-}" type="${3:-task}"
  command -v gh >/dev/null 2>&1 || die "gh CLI not found; run 'gh auth login'"
  : "${GH_REPO:?GH_REPO (owner/repo) required for the gh backend}"
  local args=(issue create --repo "$GH_REPO" --title "$summary")
  [ -n "$body" ] && args+=(--body "$body")
  [ "$type" = "bug" ] && args+=(--label bug)
  gh "${args[@]}"
  echo "# if the 'bug' label is missing, create it once:" >&2
  echo "#   gh label create bug --repo $GH_REPO" >&2
}

gh_comment() {
  gh issue comment "$1" --repo "${GH_REPO:?GH_REPO required}" --body "$2"
}

gh_transition() {
  local id="$1" state="$2"
  case "$(echo "$state" | tr '[:upper:]' '[:lower:]')" in
    closed) gh issue close "$id" --repo "${GH_REPO:?GH_REPO required}" ;;
    open|reopened) gh issue reopen "$id" --repo "${GH_REPO:?GH_REPO required}" ;;
    *)
      # GitHub has two states; middle states live in labels (docs/integrations/github.md)
      local label
      label="$(echo "$state" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')"
      gh issue edit "$id" --repo "${GH_REPO:?GH_REPO required}" --add-label "$label" \
        || die "could not add label '$label'; create it: gh label create '$label' --repo ${GH_REPO}"
      ;;
  esac
}

gh_link() {
  gh issue comment "$1" --repo "${GH_REPO:?GH_REPO required}" --body "Link: $2"
}

# ------------------------------------------------------------------ Jira ---
jira_auth() {
  : "${JIRA_HOST:?JIRA_HOST required for the jira backend}"
  : "${JIRA_EMAIL:?JIRA_EMAIL required}"
  : "${JIRA_TOKEN:?JIRA_TOKEN required (API token from id.atlassian.com)}"
}

# v3 wants Atlassian Document Format; a plain paragraph is enough for our use.
jira_adf() {
  local text
  text="$(printf '%s' "$1" | tr '\n' ' ' | sed 's/\\/\\\\/g; s/"/\\"/g')"
  printf '{"type":"doc","version":1,"content":[{"type":"paragraph","content":[{"type":"text","text":"%s"}]}]}' "$text"
}

jira_create() {
  jira_auth
  : "${JIRA_PROJECT:?JIRA_PROJECT required}"
  local summary="$1" body="${2:-}" type="${3:-task}"
  local type_name="Task"
  [ "$type" = "bug" ] && type_name="Bug"
  [ "$type" = "story" ] && type_name="Story"
  local desc='{"type":"doc","version":1,"content":[]}'
  [ -n "$body" ] && desc="$(jira_adf "$body")"
  local response
  response="$(curl -sf -u "$JIRA_EMAIL:$JIRA_TOKEN" -H 'Content-Type: application/json' \
    -X POST "https://$JIRA_HOST/rest/api/3/issue" \
    -d "{\"fields\":{\"project\":{\"key\":\"$JIRA_PROJECT\"},\"summary\":\"$summary\",\"description\":$desc,\"issuetype\":{\"name\":\"$type_name\"}}}")" \
    || die "create failed (check JIRA_PROJECT key, token, and issue types in your project)"
  printf '%s\n' "$response" | grep -oE '"key":"[A-Za-z0-9-]+"' | head -n 1 | cut -d'"' -f4
}

jira_comment() {
  jira_auth
  curl -sf -u "$JIRA_EMAIL:$JIRA_TOKEN" -H 'Content-Type: application/json' \
    -X POST "https://$JIRA_HOST/rest/api/3/issue/$1/comment" \
    -d "$(jira_adf "$2")" >/dev/null || die "comment failed on $1"
  echo "commented on $1"
}

jira_transition() {
  jira_auth
  local key="$1" wanted="$2" trans_json
  trans_json="$(curl -sf -u "$JIRA_EMAIL:$JIRA_TOKEN" \
    "https://$JIRA_HOST/rest/api/3/issue/$key/transitions")" \
    || die "could not read transitions for $key"
  local wanted_lower
  wanted_lower="$(printf '%s' "$wanted" | tr '[:upper:]' '[:lower:]')"
  local trans_id
  trans_id="$(printf '%s' "$trans_json" | tr '{' '\n' | while IFS= read -r pair; do
    name="$(printf '%s' "$pair" | grep -oE '"name": *"[^"]+"' | head -n1 | cut -d'"' -f4)"
    id="$(printf '%s' "$pair" | grep -oE '"id": *"[0-9]+"' | head -n1 | grep -oE '[0-9]+')"
    if [ -n "$name" ] && [ -n "$id" ]; then
      case "$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')" in
        *"$wanted_lower"*) echo "$id"; break ;;
      esac
    fi
  done | head -n 1)"
  [ -n "$trans_id" ] || die "no transition matches '$wanted' on $key; available: $(printf '%s' "$trans_json" | grep -oE '"name": *"[^"]+"' | cut -d'"' -f4 | paste -sd, -)"
  curl -sf -u "$JIRA_EMAIL:$JIRA_TOKEN" -H 'Content-Type: application/json' \
    -X POST "https://$JIRA_HOST/rest/api/3/issue/$key/transitions" \
    -d "{\"transition\":{\"id\":\"$trans_id\"}}" >/dev/null
  echo "transitioned $key -> $wanted"
}

jira_link() {
  jira_auth
  curl -sf -u "$JIRA_EMAIL:$JIRA_TOKEN" -H 'Content-Type: application/json' \
    -X POST "https://$JIRA_HOST/rest/api/3/issue/$1/remotelink" \
    -d "{\"object\":{\"url\":\"$2\",\"title\":\"link\"}}" >/dev/null || die "link failed on $1"
  echo "linked $1 -> $2"
}

# --------------------------------------------------------- Azure DevOps ---
ado_args() {
  : "${ADO_ORG:?ADO_ORG required for the ado backend}"
  : "${ADO_PROJECT:?ADO_PROJECT required}"
}

ado_create() {
  ado_args
  command -v az >/dev/null 2>&1 || die "az CLI not found; az extension add --name azure-devops"
  local summary="$1" body="${2:-}" type="${3:-task}" out id
  local args=(boards work-item create --title "$summary" --type "$type" --org "$ADO_ORG" --project "$ADO_PROJECT" --output json)
  [ -n "$body" ] && args+=(--description "$body")
  [ -n "${ADO_AREA_PATH:-}" ] && args+=(--area "$ADO_AREA_PATH")
  out="$(az "${args[@]}")" || die "create failed (check az login and the azure-devops extension)"
  id="$(printf '%s' "$out" | grep -oE '"id": *[0-9]+' | head -n 1 | grep -oE '[0-9]+')"
  [ -n "$id" ] || die "could not parse work item id from az output"
  echo "$id"
  echo "# $ADO_ORG/$ADO_PROJECT/_workitems/edit/$id" >&2
}

ado_comment() {
  ado_args
  az boards work-item update --id "$1" --discussion "$2" \
    --org "$ADO_ORG" --project "$ADO_PROJECT" --output none \
    || die "comment failed on $1"
  echo "commented on $1"
}

ado_transition() {
  ado_args
  az boards work-item update --id "$1" --state "$2" \
    --org "$ADO_ORG" --project "$ADO_PROJECT" --output none \
    || die "transition failed on $1 (state names come from your process template)"
  echo "transitioned $1 -> $2"
}

ado_link() {
  ado_args
  az boards work-item relation add --id "$1" --relation-type hyperlink --target-url "$2" \
    --org "$ADO_ORG" --project "$ADO_PROJECT" --output none \
    || die "link failed on $1"
  echo "linked $1 -> $2"
}

# ------------------------------------------------------------- dispatch ---
case "$cmd" in
  create)
    summary="${1:?create needs a summary}"
    shift || true
    body="" ; type="task"
    while [ $# -gt 0 ]; do
      case "$1" in
        --body) body="${2:?}" ; shift 2 ;;
        --type) type="${2:?}" ; shift 2 ;;
        *) die "unknown option: $1" ;;
      esac
    done
    "${backend}_create" "$summary" "$body" "$type"
    ;;
  comment)
    id="${1:?comment needs an item id}"; msg="${2:?comment needs a message}"
    "${backend}_comment" "$id" "$msg"
    ;;
  transition)
    id="${1:?transition needs an item id}"; state="${2:?transition needs a state}"
    "${backend}_transition" "$id" "$state"
    ;;
  link)
    id="${1:?link needs an item id}"; url="${2:?link needs a url}"
    "${backend}_link" "$id" "$url"
    ;;
  -h|--help|help) usage ;;
  *) usage; die "unknown command: $cmd" ;;
esac

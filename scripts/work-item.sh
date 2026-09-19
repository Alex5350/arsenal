#!/usr/bin/env bash
# work-item.sh: one command, three tracking backends (GitHub Issues, Jira,
# Azure DevOps). The loop's phase docs and skills call this script, never a
# backend CLI directly, so swapping trackers is a config change.
#
# Usage:
#   scripts/work-item.sh create     "Summary" [--body "context"] [--type task|bug|story]
#   scripts/work-item.sh comment    <id> "what changed and the evidence"
#   scripts/work-item.sh transition <id> "<state>"
#   scripts/work-item.sh link       <id> <url>
#   scripts/work-item.sh pr         <id> "Title" [--body "context"] [--base main]
#   scripts/work-item.sh show       <id>
#   WORK_BACKEND=gh|jira|ado selects the backend (.env or environment)
#
# Configuration: .env in the repo root, then .env in the current directory
# (the latter wins); shape in docs/templates/work-item.example.env.
# Needs jq. gh: the gh CLI; GH_REPO, or the checkout's origin when unset.
# jira: curl. ado: the az CLI with the azure-devops extension. pr needs the
# gh CLI on every backend, because the pull request lives on GitHub.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() { sed -n '2,19p' "$0"; }
die() { echo "error: $*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "$2"; }

# Load .env (never committed; see security std): the repo root's first, then
# the current directory's when that is a different file, so cwd wins.
if [ -f "$root/.env" ]; then
  # shellcheck source=/dev/null
  . "$root/.env"
fi
if [ -f "$PWD/.env" ] && ! [ "$PWD/.env" -ef "$root/.env" ]; then
  # shellcheck source=/dev/null
  . "$PWD/.env"
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
# Sets $repo from GH_REPO, else from the checkout's origin (github.com only).
gh_repo() {
  repo="${GH_REPO:-}"
  if [ -z "$repo" ]; then
    local origin=""
    origin="$(git remote get-url origin 2>/dev/null)" || origin=""
    case "$origin" in
      *github.com[:/]*) repo="$(printf '%s\n' "$origin" | sed -E 's#^.*github\.com[:/]##; s#\.git$##; s#/$##')" ;;
    esac
  fi
  [ -n "$repo" ] || die "GH_REPO (owner/repo) required for the gh backend"
  need gh "gh CLI not found; run 'gh auth login'"
}

# Run a gh command that names label $1; if it fails, create the label once
# (labels are created on demand) and retry once.
gh_with_label() {
  local label="$1"
  shift
  if ! gh "$@"; then
    echo "# creating label '$label' in $repo and retrying" >&2
    # An existing label makes create fail; that is fine, the retry decides.
    gh label create "$label" --repo "$repo" >/dev/null 2>&1 || true
    if ! gh "$@"; then
      die "gh failed again after creating label '$label' in $repo (wrong id, missing label, or auth?)"
    fi
  fi
}

gh_create() {
  local summary="$1" body="${2:-}" type="${3:-task}"
  gh_repo
  local args=(issue create --repo "$repo" --title "$summary" --label "$type")
  [ -n "$body" ] && args+=(--body "$body")
  gh_with_label "$type" "${args[@]}"
}

gh_comment() {
  gh_repo
  gh issue comment "$1" --repo "$repo" --body "$2"
}

gh_transition() {
  local id="$1" state
  state="$(echo "$2" | tr '[:upper:]' '[:lower:]')"
  gh_repo
  case "$state" in
    done|closed) gh issue close "$id" --repo "$repo" ;;
    backlog|open|reopened) gh issue reopen "$id" --repo "$repo" ;;
    *)
      # GitHub has two states; middle states live in labels (docs/integrations/github.md)
      local label
      label="$(echo "$state" | tr ' ' '-')"
      gh_with_label "$label" issue edit "$id" --repo "$repo" --add-label "$label"
      ;;
  esac
}

gh_link() {
  gh_repo
  gh issue comment "$1" --repo "$repo" --body "Link: $2"
}

gh_pr() {
  gh_repo
  pr_create "gh-$1 $2" "$3" "Closes #$1" "$4"
  gh_transition "$1" "in review"
}

gh_show() {
  gh_repo
  need jq "jq not found; show reads gh's JSON with it"
  gh issue view "$1" --repo "$repo" --json number,title,state,labels \
    | jq -r '"#\(.number) \(.state) [\([.labels[].name] | join(","))] \(.title)"'
}

# ------------------------------------------------------------------ Jira ---
jira_auth() {
  : "${JIRA_HOST:?JIRA_HOST required for the jira backend}"
  : "${JIRA_EMAIL:?JIRA_EMAIL required}"
  : "${JIRA_TOKEN:?JIRA_TOKEN required (API token from id.atlassian.com)}"
  need jq "jq not found; the jira backend builds and reads JSON with it"
}

# v3 wants Atlassian Document Format: one paragraph per non-empty line.
jira_adf() {
  jq -cn --arg text "$1" \
    '{type:"doc",version:1,content:[$text | split("\n")[] | select(length > 0)
      | {type:"paragraph",content:[{type:"text",text:.}]}]}'
}

jira_create() {
  jira_auth
  : "${JIRA_PROJECT:?JIRA_PROJECT required}"
  local summary="$1" body="${2:-}" type="${3:-task}"
  local type_name="Task"
  [ "$type" = "bug" ] && type_name="Bug"
  [ "$type" = "story" ] && type_name="Story"
  local payload response
  payload="$(jq -cn --arg project "$JIRA_PROJECT" --arg summary "$summary" --arg type "$type_name" \
    --argjson description "$(jira_adf "$body")" \
    '{fields:{project:{key:$project},summary:$summary,description:$description,issuetype:{name:$type}}}')"
  if ! response="$(curl -sf -u "$JIRA_EMAIL:$JIRA_TOKEN" -H 'Content-Type: application/json' \
    -X POST "https://$JIRA_HOST/rest/api/3/issue" -d "$payload")"; then
    die "create failed (check JIRA_PROJECT key, token, and issue types in your project)"
  fi
  printf '%s\n' "$response" | jq -r '.key // empty'
}

jira_comment() {
  jira_auth
  local payload
  payload="$(jq -cn --argjson body "$(jira_adf "$2")" '{body:$body}')"
  if ! curl -sf -u "$JIRA_EMAIL:$JIRA_TOKEN" -H 'Content-Type: application/json' \
    -X POST "https://$JIRA_HOST/rest/api/3/issue/$1/comment" -d "$payload" >/dev/null; then
    die "comment failed on $1"
  fi
  echo "commented on $1"
}

jira_transition() {
  jira_auth
  local key="$1" wanted="$2" trans_json trans_id
  if ! trans_json="$(curl -sf -u "$JIRA_EMAIL:$JIRA_TOKEN" \
    "https://$JIRA_HOST/rest/api/3/issue/$key/transitions")"; then
    die "could not read transitions for $key"
  fi
  # A transition matches by its own name or by the status it leads to, case-insensitive.
  trans_id="$(printf '%s' "$trans_json" | jq -r --arg wanted "$wanted" '
    ($wanted | ascii_downcase) as $w
    | [.transitions[] | select(((.name // "") | ascii_downcase) == $w or ((.to.name // "") | ascii_downcase) == $w) | .id]
    | first // empty')"
  [ -n "$trans_id" ] || die "no transition matches '$wanted' on $key; available: $(printf '%s' "$trans_json" | jq -r '[.transitions[] | "\(.name) -> \(.to.name // "?")"] | join(", ")')"
  if ! curl -sf -u "$JIRA_EMAIL:$JIRA_TOKEN" -H 'Content-Type: application/json' \
    -X POST "https://$JIRA_HOST/rest/api/3/issue/$key/transitions" \
    -d "$(jq -cn --arg id "$trans_id" '{transition:{id:$id}}')" >/dev/null; then
    die "transition failed on $key"
  fi
  echo "transitioned $key -> $wanted"
}

jira_link() {
  jira_auth
  if ! curl -sf -u "$JIRA_EMAIL:$JIRA_TOKEN" -H 'Content-Type: application/json' \
    -X POST "https://$JIRA_HOST/rest/api/3/issue/$1/remotelink" \
    -d "$(jq -cn --arg url "$2" '{object:{url:$url,title:"link"}}')" >/dev/null; then
    die "link failed on $1"
  fi
  echo "linked $1 -> $2"
}

jira_pr() {
  pr_create "$1 $2" "$3" "$1" "$4"
}

jira_show() {
  jira_auth
  local response
  if ! response="$(curl -sf -u "$JIRA_EMAIL:$JIRA_TOKEN" \
    "https://$JIRA_HOST/rest/api/3/issue/$1?fields=summary,status")"; then
    die "could not read $1"
  fi
  printf '%s\n' "$response" | jq -r '"\(.key) \(.fields.status.name) \(.fields.summary)"'
}

# --------------------------------------------------------- Azure DevOps ---
ado_args() {
  : "${ADO_ORG:?ADO_ORG required for the ado backend}"
  : "${ADO_PROJECT:?ADO_PROJECT required}"
  need az "az CLI not found; az extension add --name azure-devops"
  need jq "jq not found; the ado backend reads az's JSON with it"
}

ado_create() {
  ado_args
  local summary="$1" body="${2:-}" type="${3:-task}" out id
  case "$type" in
    story) type="${ADO_STORY_TYPE:-User Story}" ;;
    task) type="Task" ;;
    bug) type="Bug" ;;
  esac
  local args=(boards work-item create --title "$summary" --type "$type" --org "$ADO_ORG" --project "$ADO_PROJECT" --output json)
  [ -n "$body" ] && args+=(--description "$body")
  [ -n "${ADO_AREA_PATH:-}" ] && args+=(--area "$ADO_AREA_PATH")
  if ! out="$(az "${args[@]}")"; then
    die "create failed (check az login and the azure-devops extension)"
  fi
  id="$(printf '%s' "$out" | jq -r '.id // empty')"
  [ -n "$id" ] || die "could not parse work item id from az output"
  echo "$id"
  echo "# $ADO_ORG/$ADO_PROJECT/_workitems/edit/$id" >&2
}

# Work item ids are unique per organization: update, relation add and show
# take --org only (az rejects --project on them).
ado_comment() {
  ado_args
  if ! az boards work-item update --id "$1" --discussion "$2" --org "$ADO_ORG" --output none; then
    die "comment failed on $1"
  fi
  echo "commented on $1"
}

ado_transition() {
  ado_args
  if ! az boards work-item update --id "$1" --state "$2" --org "$ADO_ORG" --output none; then
    die "transition failed on $1 (state names come from your process template)"
  fi
  echo "transitioned $1 -> $2"
}

ado_link() {
  ado_args
  if ! az boards work-item relation add --id "$1" --relation-type hyperlink --target-url "$2" \
    --org "$ADO_ORG" --output none; then
    die "link failed on $1"
  fi
  echo "linked $1 -> $2"
}

ado_pr() {
  pr_create "AB#$1 $2" "$3" "AB#$1" "$4"
}

ado_show() {
  ado_args
  local out
  if ! out="$(az boards work-item show --id "$1" --org "$ADO_ORG" --output json)"; then
    die "show failed on $1"
  fi
  printf '%s\n' "$out" | jq -r '"\(.id) \(.fields["System.State"]) \(.fields["System.Title"])"'
}

# ---------------------------------------------------------- pull request ---
# The code lives on GitHub whatever the tracker, so every backend opens the
# PR with gh. $3 is the backend's closing reference, appended as the last line.
pr_create() {
  local title="$1" body="$2" ref="$3" base="$4"
  need gh "gh CLI not found; 'pr' opens the pull request on GitHub for every backend"
  if [ -n "$body" ]; then
    body="$body"$'\n\n'"$ref"
  else
    body="$ref"
  fi
  gh pr create --title "$title" --body "$body" --base "$base"
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
  pr)
    id="${1:?pr needs an item id}"; title="${2:?pr needs a title}"
    shift 2
    body="" ; base="main"
    while [ $# -gt 0 ]; do
      case "$1" in
        --body) body="${2:?}" ; shift 2 ;;
        --base) base="${2:?}" ; shift 2 ;;
        *) die "unknown option: $1" ;;
      esac
    done
    "${backend}_pr" "$id" "$title" "$body" "$base"
    ;;
  show)
    id="${1:?show needs an item id}"
    "${backend}_show" "$id"
    ;;
  -h|--help|help) usage ;;
  *) usage; die "unknown command: $cmd" ;;
esac

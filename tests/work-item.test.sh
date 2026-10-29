#!/usr/bin/env bash
# Tests for scripts/work-item.sh. Run from any directory:
#   bash tests/work-item.test.sh
#
# No network. gh, az, curl and git are stubs in a temp dir placed first on
# PATH; each stub appends its argv (and stdin, if any) to $STUB_LOG, writes
# the value following -d/--data/--body to $STUB_DIR/payload, and answers with
# canned output. The script under test is a copy in a temp root, so the
# developer's own .env never leaks in and case 10 can plant one. Every run
# starts from an empty environment (env -i) with only the case's variables.
# Prints one line per case (ok <case> / FAIL <case>: <detail>); exits 1 on
# any failure. Needs jq, like the script.
set -o pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/work-item-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

SCRIPT="$TMP/repo/scripts/work-item.sh"
STUB_BIN="$TMP/bin"          # gh, az, curl, git stubs
NOGH_BIN="$TMP/bin-nogh"     # the same minus gh, for the "gh missing" case
STUB_DIR="$TMP/stub"
STUB_LOG="$STUB_DIR/log"
HOME_DIR="$TMP/home"
ERR_FILE="$TMP/stderr"
mkdir -p "$TMP/repo/scripts" "$TMP/cwd" "$STUB_BIN" "$NOGH_BIN" "$STUB_DIR" "$HOME_DIR"
cp "$repo/scripts/work-item.sh" "$SCRIPT"

# ------------------------------------------------------------------ stubs ---
printf '#!%s\n' "$BASH" >"$TMP/stub.sh"
cat >>"$TMP/stub.sh" <<'STUB'
name="${0##*/}"
stdin=""
[ -t 0 ] || stdin="$(cat)"
{
  printf '%s' "$name"
  for a in "$@"; do printf ' %s' "${a//$'\n'/\\n}"; done
  printf '\n'
  [ -z "$stdin" ] || printf 'stdin: %s\n' "${stdin//$'\n'/\\n}"
} >>"$STUB_LOG"
prev="" data="" url=""
for a in "$@"; do
  case "$prev" in -d|--data|--data-raw|--body) printf '%s' "$a" >"$STUB_DIR/payload"; data="$a" ;; esac
  case "$a" in http://*|https://*) url="$a" ;; esac
  prev="$a"
done
if [ "${STUB_FAIL:-}" = "$name" ]; then
  echo "$name: simulated failure" >&2
  exit 1
fi
case "$name" in
  gh)
    case "$*" in
      "label create "*) touch "$STUB_DIR/labels-exist" ;;
      "issue create "*|"issue edit "*)
        case " $* " in
          *" --label "*|*" --add-label "*)
            [ -f "$STUB_DIR/labels-exist" ] || { echo "could not add label: not found" >&2; exit 1; } ;;
        esac
        echo "https://github.com/o/r/issues/7" ;;
      "issue view "*) echo '{"number":7,"title":"Title","state":"OPEN","labels":[{"name":"story"},{"name":"in-review"}]}' ;;
      "pr create "*) echo "https://github.com/o/r/pull/8" ;;
    esac ;;
  git)
    if [ "$*" = "remote get-url origin" ]; then
      [ -n "${STUB_ORIGIN:-}" ] || { echo "error: No such remote 'origin'" >&2; exit 2; }
      echo "$STUB_ORIGIN"
    fi ;;
  az)
    case "$*" in
      "boards work-item create "*) echo '{"id": 42, "fields": {"System.State": "New", "System.Title": "S"}}' ;;
      "boards work-item show "*) echo '{"id": 42, "fields": {"System.State": "Active", "System.Title": "Title"}}' ;;
    esac ;;
  curl)
    case "$url" in
      */transitions)
        [ -n "$data" ] || echo '{"transitions":[{"id":"11","name":"Start Progress","to":{"name":"In Progress"}},{"id":"21","name":"Ready for review","to":{"name":"In Review"}},{"id":"31","name":"Done","to":{"name":"Done"}}]}' ;;
      */comment) echo '{"id":"10100"}' ;;
      */remotelink) echo '{"id":10200}' ;;
      *"?fields=summary,status") echo '{"key":"PROJ-7","fields":{"summary":"Title","status":{"name":"In Progress"}}}' ;;
      */rest/api/3/issue) echo '{"id":"10001","key":"PROJ-7","self":"https://jira.example/rest/api/3/issue/10001"}' ;;
    esac ;;
esac
STUB
for n in gh az curl git; do cp "$TMP/stub.sh" "$STUB_BIN/$n"; done
for n in az curl git; do cp "$TMP/stub.sh" "$NOGH_BIN/$n"; done
# On the bare PATH the script may only reach dirname (root lookup) and sed
# (usage) before it notices gh is missing; shim those two, nothing else.
for tool in dirname sed; do
  printf '#!%s\nexec "%s" "$@"\n' "$BASH" "$(command -v "$tool")" >"$NOGH_BIN/$tool"
done
chmod +x "$STUB_BIN"/* "$NOGH_BIN"/*

# ---------------------------------------------------------------- harness ---
GH_ENV=(GH_REPO=o/r)
JIRA_ENV=(JIRA_HOST=jira.example JIRA_EMAIL=me@example.com JIRA_TOKEN=tok JIRA_PROJECT=PROJ)
ADO_ENV=(ADO_ORG=https://dev.azure.com/acme ADO_PROJECT=Proj)

failed=0
current=""
case_err=""

begin() {
  current="$1"
  case_err=""
  : >"$STUB_LOG"
  rm -f "$STUB_DIR/payload" "$TMP/repo/.env" "$TMP/cwd/.env" "$TMP/sourced"
  touch "$STUB_DIR/labels-exist"
  WI_ENV=()
  STUB_ORIGIN=""
  STUB_FAIL=""
  RUN_PATH="$STUB_BIN:$PATH"
  CWD="$TMP/cwd"
}

end() {
  if [ -n "$case_err" ]; then
    echo "FAIL $current: $case_err"
    failed=$((failed + 1))
  else
    echo "ok $current"
  fi
}

# run_wi <backend> <args...>: run the script copy from $CWD; sets out, err, status.
run_wi() {
  local backend="$1"
  shift
  status=0
  # SYSTEMROOT/WINDIR stay only on Windows: native binaries (jq.exe) need them.
  out="$(cd "$CWD" && env -i PATH="$RUN_PATH" HOME="$HOME_DIR" \
    ${SYSTEMROOT:+"SYSTEMROOT=$SYSTEMROOT"} ${WINDIR:+"WINDIR=$WINDIR"} \
    STUB_LOG="$STUB_LOG" STUB_DIR="$STUB_DIR" STUB_ORIGIN="$STUB_ORIGIN" STUB_FAIL="$STUB_FAIL" \
    WORK_BACKEND="$backend" "${WI_ENV[@]}" "$BASH" "$SCRIPT" "$@" 2>"$ERR_FILE" </dev/null)" || status=$?
  err="$(cat "$ERR_FILE")"
}

oneline() { printf '%s' "$1" | tr '\n' '|'; }
flag() { [ -n "$case_err" ] || case_err="$1"; }
logtext() { oneline "$(cat "$STUB_LOG")"; }
payload() { cat "$STUB_DIR/payload" 2>/dev/null; }

assert_status() {
  [ "$status" -eq "$1" ] || flag "exit status $status, wanted $1; stderr: $(oneline "$err")"
}
assert_log() {
  grep -Eq -- "$1" "$STUB_LOG" || flag "no stub call matches '$1'; log: $(logtext)"
}
assert_no_log() {
  ! grep -Eq -- "$1" "$STUB_LOG" || flag "unexpected stub call matching '$1'; log: $(logtext)"
}
assert_count() {
  local n
  n="$(grep -Ec -- "$1" "$STUB_LOG")"
  [ "$n" -eq "$2" ] || flag "$n call(s) match '$1', wanted $2; log: $(logtext)"
}
assert_eq() {
  [ "$1" = "$2" ] || flag "$3: got '$(oneline "$1")', wanted '$(oneline "$2")'"
}
assert_match() {
  printf '%s\n' "$1" | grep -Eq -- "$2" || flag "$3: '$(oneline "$1")' does not match '$2'"
}
assert_json() {  # assert_json <filter> <wanted> <what>: run jq on the captured payload
  local got
  if ! got="$(payload | jq -r "$1" 2>&1)"; then
    flag "$3: jq '$1' failed on payload: $(oneline "$got")"
    return
  fi
  assert_eq "$got" "$2" "$3"
}

# ------------------------------------------------------------------ cases ---
begin "0 usage lists every subcommand and needs no tools"
RUN_PATH="$NOGH_BIN"
run_wi gh --help
assert_status 0
for c in create comment transition link pr show; do
  assert_match "$out" "work-item.sh $c " "usage mentions $c"
done
assert_match "$out" "jq" "usage names the jq dependency"
run_wi gh
assert_status 2
end

for t in story task bug; do
  begin "1 gh create --type $t adds --label $t"
  WI_ENV=("${GH_ENV[@]}")
  run_wi gh create "S" --type "$t"
  assert_status 0
  assert_log "^gh issue create .*--repo o/r( |$)"
  assert_log "^gh issue create .*--title S( |$)"
  assert_log "^gh issue create .*--label $t( |$)"
  assert_eq "$err" "" "stderr on the success path"
  end
done

begin "1 gh create defaults to --type task"
WI_ENV=("${GH_ENV[@]}")
run_wi gh create "S"
assert_status 0
assert_log "^gh issue create .*--label task( |$)"
end

begin "2 gh create creates the missing label and retries once"
WI_ENV=("${GH_ENV[@]}")
rm -f "$STUB_DIR/labels-exist"
run_wi gh create "S" --type story
assert_status 0
assert_count "^gh issue create " 2
assert_log "^gh label create story --repo o/r( |$)"
assert_eq "$(grep -Eo '^gh (issue|label) create' "$STUB_LOG" | tr '\n' ',')" \
  "gh issue create,gh label create,gh issue create," "call order"
end

for s in 'done' closed; do
  begin "3 gh transition $s closes the issue"
  WI_ENV=("${GH_ENV[@]}")
  run_wi gh transition 7 "$s"
  assert_status 0
  assert_log "^gh issue close 7 .*--repo o/r( |$)"
  end
done

for s in backlog open reopened; do
  begin "3 gh transition $s reopens the issue"
  WI_ENV=("${GH_ENV[@]}")
  run_wi gh transition 7 "$s"
  assert_status 0
  assert_log "^gh issue reopen 7 .*--repo o/r( |$)"
  end
done

begin "3 gh transition 'in review' adds the in-review label"
WI_ENV=("${GH_ENV[@]}")
run_wi gh transition 7 "in review"
assert_status 0
assert_log "^gh issue edit 7 .*--repo o/r( |$)"
assert_log "^gh issue edit 7 .*--add-label in-review( |$)"
end

begin "3 gh transition 'in review' creates the missing label and retries"
WI_ENV=("${GH_ENV[@]}")
rm -f "$STUB_DIR/labels-exist"
run_wi gh transition 7 "In Review"
assert_status 0
assert_count "^gh issue edit 7 .*--add-label in-review( |$)" 2
assert_log "^gh label create in-review --repo o/r( |$)"
end

begin "4 gh with GH_REPO unset infers the repo from an https origin"
STUB_ORIGIN="https://github.com/o/r.git"
run_wi gh create "S"
assert_status 0
assert_log "^git remote get-url origin$"
assert_log "^gh issue create .*--repo o/r( |$)"
end

begin "4 gh with GH_REPO unset infers the repo from an ssh origin"
STUB_ORIGIN="git@github.com:o/r.git"
run_wi gh comment 7 "note"
assert_status 0
assert_log "^gh issue comment 7 .*--repo o/r( |$)"
end

begin "4 gh with GH_REPO set does not consult git"
WI_ENV=("${GH_ENV[@]}")
STUB_ORIGIN="https://github.com/other/repo.git"
run_wi gh comment 7 "note"
assert_status 0
assert_log "^gh issue comment 7 .*--repo o/r( |$)"
assert_no_log "^git "
end

begin "4 gh dies when neither GH_REPO nor an origin is available"
run_wi gh comment 7 "note"
assert_status 1
assert_match "$err" "GH_REPO \(owner/repo\) required for the gh backend" "die message"
assert_no_log "^gh "
end

begin "5 jira create sends jq-built JSON: quotes in the summary, ADF paragraphs"
WI_ENV=("${JIRA_ENV[@]}")
run_wi jira create 'Say "hi"' --body "$(printf 'a\n\nb')" --type story
assert_status 0
assert_log "^curl .*-X POST https://jira.example/rest/api/3/issue( |$)"
if payload | jq -e . >/dev/null 2>&1; then
  assert_json '.fields.summary' 'Say "hi"' "summary"
  assert_json '.fields.project.key' 'PROJ' "project key"
  assert_json '.fields.issuetype.name' 'Story' "issue type"
  assert_json '.fields.description.type' 'doc' "description is an ADF doc"
  assert_json '.fields.description.content | length' '2' "paragraph count"
  assert_json '.fields.description.content[0].content[0].text' 'a' "first paragraph"
  assert_json '.fields.description.content[1].content[0].text' 'b' "second paragraph"
else
  flag "payload is not valid JSON: $(oneline "$(payload)")"
fi
assert_eq "$out" "PROJ-7" "printed key"
end

begin "5 jira comment sends multi-paragraph ADF under body"
WI_ENV=("${JIRA_ENV[@]}")
run_wi jira comment PROJ-7 "$(printf 'line "one"\n\nline two')"
assert_status 0
assert_log "^curl .*-X POST https://jira.example/rest/api/3/issue/PROJ-7/comment( |$)"
if payload | jq -e . >/dev/null 2>&1; then
  assert_json '.body.type' 'doc' "comment body is an ADF doc"
  assert_json '.body.content | length' '2' "paragraph count"
  assert_json '.body.content[0].content[0].text' 'line "one"' "first paragraph"
  assert_json '.body.content[1].content[0].text' 'line two' "second paragraph"
else
  flag "payload is not valid JSON: $(oneline "$(payload)")"
fi
end

begin "6 jira transition matches the target status (to.name)"
WI_ENV=("${JIRA_ENV[@]}")
run_wi jira transition PROJ-7 "in progress"
assert_status 0
assert_log "^curl .*https://jira.example/rest/api/3/issue/PROJ-7/transitions( |$)"
assert_json '.transition.id' '11' "transition id"
end

begin "6 jira transition matches the transition name, case-insensitive"
WI_ENV=("${JIRA_ENV[@]}")
run_wi jira transition PROJ-7 "READY FOR REVIEW"
assert_status 0
assert_json '.transition.id' '21' "transition id"
end

begin "6 jira transition rejects a partial match"
WI_ENV=("${JIRA_ENV[@]}")
run_wi jira transition PROJ-7 "progress"
assert_status 1
assert_match "$err" "no transition matches 'progress'" "die message"
assert_count "^curl .*-X POST" 0
end

begin "7 ado --type story maps to User Story"
WI_ENV=("${ADO_ENV[@]}")
run_wi ado create "S" --type story
assert_status 0
assert_log "^az boards work-item create --title S --type User Story --org https://dev.azure.com/acme --project Proj( |$)"
assert_eq "$out" "42" "printed id"
end

begin "7 ado ADO_STORY_TYPE overrides the story type"
WI_ENV=("${ADO_ENV[@]}" "ADO_STORY_TYPE=Story")
run_wi ado create "S" --type story
assert_status 0
assert_log "^az boards work-item create --title S --type Story( |$)"
end

begin "7 ado --type task maps to Task"
WI_ENV=("${ADO_ENV[@]}")
run_wi ado create "S" --type task
assert_status 0
assert_log "^az boards work-item create --title S --type Task( |$)"
end

begin "7 ado --type bug maps to Bug"
WI_ENV=("${ADO_ENV[@]}")
run_wi ado create "S" --type bug
assert_status 0
assert_log "^az boards work-item create --title S --type Bug( |$)"
end

begin "7 ado comment passes --org but not --project (az update rejects it)"
WI_ENV=("${ADO_ENV[@]}")
run_wi ado comment 42 "note"
assert_status 0
assert_log "^az boards work-item update --id 42 --discussion note --org https://dev.azure.com/acme( |$)"
assert_no_log "^az .*--project"
end

begin "7 ado transition passes --org but not --project"
WI_ENV=("${ADO_ENV[@]}")
run_wi ado transition 42 "Active"
assert_status 0
assert_log "^az boards work-item update --id 42 --state Active --org https://dev.azure.com/acme( |$)"
assert_no_log "^az .*--project"
end

begin "7 ado link passes --org but not --project"
WI_ENV=("${ADO_ENV[@]}")
run_wi ado link 42 "https://example.com/plan"
assert_status 0
assert_log "^az boards work-item relation add --id 42 --relation-type hyperlink --target-url https://example.com/plan --org https://dev.azure.com/acme( |$)"
assert_no_log "^az .*--project"
end

begin "8 gh pr: title gh-<id>, base main, body Closes #<id>, in-review label"
WI_ENV=("${GH_ENV[@]}")
run_wi gh pr 7 "Title"
assert_status 0
assert_log "^gh pr create .*--title gh-7 Title( |$)"
assert_log "^gh pr create .*--base main( |$)"
assert_eq "$(payload)" "Closes #7" "PR body"
assert_log "^gh issue edit 7 .*--add-label in-review( |$)"
end

begin "8 gh pr honours --body and --base"
WI_ENV=("${GH_ENV[@]}")
run_wi gh pr 7 "Title" --body "Context" --base develop
assert_status 0
assert_log "^gh pr create .*--base develop( |$)"
assert_eq "$(payload)" "$(printf 'Context\n\nCloses #7')" "PR body"
end

begin "8 jira pr: title <KEY> Title, key on its own last line, no Jira calls"
WI_ENV=("${JIRA_ENV[@]}")
run_wi jira pr PROJ-7 "Title" --body "Context"
assert_status 0
assert_log "^gh pr create .*--title PROJ-7 Title( |$)"
assert_log "^gh pr create .*--base main( |$)"
assert_eq "$(payload | tail -n 1)" "PROJ-7" "last body line"
assert_eq "$(payload | head -n 1)" "Context" "first body line"
assert_count "^curl" 0
end

begin "8 ado pr: title AB#<id> Title, body ends with AB#<id>"
WI_ENV=("${ADO_ENV[@]}")
run_wi ado pr 42 "Title"
assert_status 0
assert_log "^gh pr create .*--title AB#42 Title( |$)"
assert_eq "$(payload | tail -n 1)" "AB#42" "last body line"
assert_count "^az" 0
end

begin "8 pr dies with a clear message when the gh CLI is missing"
WI_ENV=("${JIRA_ENV[@]}")
RUN_PATH="$NOGH_BIN"
run_wi jira pr PROJ-7 "Title"
assert_status 1
assert_match "$err" "^error: gh CLI not found" "die message"
end

begin "9 gh show prints #n state [labels] title"
WI_ENV=("${GH_ENV[@]}")
run_wi gh show 7
assert_status 0
assert_log "^gh issue view 7 .*--repo o/r( |$)"
assert_log "^gh issue view 7 .*--json number,title,state,labels( |$)"
assert_eq "$out" "#7 OPEN [story,in-review] Title" "show output"
end

begin "9 jira show prints KEY status summary"
WI_ENV=("${JIRA_ENV[@]}")
run_wi jira show PROJ-7
assert_status 0
assert_log "^curl .*https://jira.example/rest/api/3/issue/PROJ-7\?fields=summary,status( |$)"
assert_eq "$out" "PROJ-7 In Progress Title" "show output"
end

begin "9 ado show prints id State Title"
WI_ENV=("${ADO_ENV[@]}")
run_wi ado show 42
assert_status 0
assert_log "^az boards work-item show --id 42 --org https://dev.azure.com/acme( |$)"
assert_no_log "^az .*--project"
assert_eq "$out" "42 Active Title" "show output"
end

begin "10 .env in the current directory is never executed (only the repo root's)"
printf 'GH_REPO=root/repo\n' >"$TMP/repo/.env"
printf 'GH_REPO=cwd/repo\necho executed >>"%s"\n' "$TMP/cwd-executed" >"$TMP/cwd/.env"
run_wi gh comment 7 "note"
assert_status 0
assert_log "^gh issue comment 7 .*--repo root/repo( |$)"
assert_eq "$( [ -e "$TMP/cwd-executed" ] && echo executed || echo no )" "no" "cwd .env executed"
end

begin "10 .env in the repo root alone is used"
printf 'GH_REPO=root/repo\n' >"$TMP/repo/.env"
run_wi gh comment 7 "note"
assert_status 0
assert_log "^gh issue comment 7 .*--repo root/repo( |$)"
end

begin "10 .env is sourced once when the current directory is the repo root"
printf 'GH_REPO=root/repo\necho sourced >>"%s"\n' "$TMP/sourced" >"$TMP/repo/.env"
CWD="$TMP/repo"
run_wi gh comment 7 "note"
assert_status 0
assert_log "^gh issue comment 7 .*--repo root/repo( |$)"
assert_eq "$(grep -c sourced "$TMP/sourced" 2>/dev/null)" "1" "times sourced"
end

begin "11 gh label creation failure reaches its hint instead of a bare exit"
WI_ENV=("${GH_ENV[@]}")
STUB_FAIL=gh
run_wi gh create "S" --type bug
assert_status 1
assert_match "$err" "^error: .*label 'bug'" "die message"
end

begin "11 jira create failure reaches its hint"
WI_ENV=("${JIRA_ENV[@]}")
STUB_FAIL=curl
run_wi jira create "S"
assert_status 1
assert_match "$err" "^error: create failed \(check JIRA_PROJECT" "die message"
end

begin "11 ado create failure reaches its hint"
WI_ENV=("${ADO_ENV[@]}")
STUB_FAIL=az
run_wi ado create "S"
assert_status 1
assert_match "$err" "^error: create failed \(check az login" "die message"
end

# ---------------------------------------------------------------- summary ---
if [ "$failed" -gt 0 ]; then
  echo "$failed failing case(s)" >&2
  exit 1
fi
echo "all cases passed"

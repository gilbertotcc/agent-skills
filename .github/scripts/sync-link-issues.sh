#!/usr/bin/env bash
# Sync one "broken-link" issue per broken URL with a lychee JSON report.
set -euo pipefail

LABEL="broken-link"
PREFIX="Broken link: "

usage() {
  cat <<'USAGE'
Usage: sync-link-issues.sh [--dry-run] [--run-url URL] REPORT

Sync one "broken-link" issue per broken URL with a lychee JSON report.

Examples:
  sync-link-issues.sh lychee/out.json
  sync-link-issues.sh --dry-run lychee/out.json
  lychee --format json --verbose . | sync-link-issues.sh --dry-run -

Arguments:
  REPORT             lychee JSON report, or - for stdin

Options:
  -n, --dry-run      Print what would change; don't create, comment on or
                     close issues
      --run-url URL  Workflow run to link in comments (default: built from
                     GITHUB_SERVER_URL, GITHUB_REPOSITORY, GITHUB_RUN_ID)
  -h, --help         Show this help

Needs gh (authenticated, e.g. GH_TOKEN) and jq. The repository is the one gh
resolves (GH_REPO or the current checkout).
USAGE
}

die() { echo "error: $*" >&2; exit 1; }
usage_error() {
  echo "error: $*" >&2
  echo "Try 'sync-link-issues.sh --help'." >&2
  exit 2
}

dry_run=false
run_url=""
report=""
have_report=false

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help) usage; exit 0 ;;
    -n|--dry-run) dry_run=true ;;
    --run-url)
      [[ $# -ge 2 ]] || usage_error "--run-url needs a value"
      run_url=$2
      shift
      ;;
    --run-url=*) run_url=${1#*=} ;;
    -) report=-; have_report=true ;;
    -?*) usage_error "unknown option: $1" ;;
    *)
      $have_report && usage_error "unexpected argument: $1"
      report=$1
      have_report=true
      ;;
  esac
  shift
done
$have_report || usage_error "missing REPORT"

if [[ -z $run_url && -n ${GITHUB_SERVER_URL:-} && -n ${GITHUB_REPOSITORY:-} \
  && -n ${GITHUB_RUN_ID:-} ]]; then
  run_url="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID"
fi

command -v jq >/dev/null 2>&1 || die "jq is required"
command -v gh >/dev/null 2>&1 || die "gh is required"

# Validate the report before any write.
if [[ $report == - ]]; then
  json=$(cat)
else
  [[ -f $report ]] || die "report not found: $report"
  json=$(cat "$report") || die "cannot read report: $report"
fi
jq -e . >/dev/null 2>&1 <<<"$json" || die "not valid JSON: $report"
jq -e 'type == "object" and (has("error_map") or has("fail_map"))' \
  >/dev/null 2>&1 <<<"$json" || die "not a lychee JSON report (no error_map)"

# Broken URLs: one object per URL with status text and sorted source files.
# fail_map is the name older lychee versions use for error_map.
broken=$(jq -c '
  (.error_map // .fail_map) | to_entries
  | map(.key as $f | .value[] | {url, status: .status.text, file: $f})
  | group_by(.url)
  | map({url: .[0].url, status: .[0].status, files: (map(.file) | unique)})
' <<<"$json") || die "cannot read broken links from report"
ok_urls=$(jq -c '[(.success_map // {})[][].url] | unique' <<<"$json") \
  || die "cannot read successful links from report"
# Timed-out URLs are inconclusive: they neither open nor close issues.
timeout_urls=$(jq -c '[(.timeout_map // {})[][].url] | unique' <<<"$json") \
  || die "cannot read timed-out links from report"

# would: "would " in dry-run. past VERB SUFFIX: VERB in dry-run, else VERB+SUFFIX.
would() { if $dry_run; then printf 'would '; fi; }
past() { if $dry_run; then printf '%s' "$1"; else printf '%s%s' "$1" "$2"; fi; }

gh_write() {  # gh_write ARGS...: run a gh write command unless --dry-run
  $dry_run && return 0
  # </dev/null: never let gh consume the input of the loops calling this.
  gh "$@" </dev/null
}

# Markdown snippets (one line per paragraph, no hard wrapping).
files_md() { jq -r '.files | map("- `" + . + "`") | join("\n")' <<<"$1"; }
run_md() { if [[ -n $run_url ]]; then printf '\n[Workflow run](%s)\n' "$run_url"; fi; }

details_md() {  # details_md ENTRY
  # shellcheck disable=SC2016  # backticks are Markdown, not expansion
  printf 'Status: `%s`\n\nFound in:\n\n%s\n' \
    "$(jq -r '.status' <<<"$1")" "$(files_md "$1")"
  run_md
}

created=0 reopened=0 closed=0 unchanged=0

# 2. Ensure the label exists.
labels=$(gh label list --limit 1000 --json name --jq '.[].name') \
  || die "gh label list failed"
if ! grep -qxF "$LABEL" <<<"$labels"; then
  echo "$(would)create label $LABEL"
  gh_write label create "$LABEL" --color D93F0B \
    --description "Broken link found by the weekly link check" >/dev/null \
    || die "gh label create failed"
fi

# 3. One issue per broken URL.
issues=$(gh issue list --label "$LABEL" --state all --limit 1000 \
  --json number,title,state) || die "gh issue list failed"

while IFS= read -r entry; do
  [[ -n $entry ]] || continue
  url=$(jq -r '.url' <<<"$entry")
  title="$PREFIX$url"
  # Prefer an open issue; otherwise the most recent closed one.
  found=$(jq -r --arg t "$title" '
    map(select(.title == $t)) | sort_by(.state != "OPEN", -.number)
    | (.[0] // empty) | "\(.state) \(.number)"' <<<"$issues")
  state=${found% *}
  number=${found#* }
  case $state in
    OPEN)
      echo "unchanged #$number"
      unchanged=$((unchanged + 1))
      ;;
    CLOSED)
      gh_write issue reopen "$number" \
        --comment "$(printf 'Still broken.\n\n'; details_md "$entry")" \
        >/dev/null || die "gh issue reopen #$number failed"
      echo "$(would)$(past reopen ed) #$number"
      reopened=$((reopened + 1))
      ;;
    *)
      if $dry_run; then
        echo "would create $title"
      else
        # shellcheck disable=SC2016  # backticks are Markdown
        body=$(printf 'The weekly link check found a broken link: <%s>\n\n' "$url"
          details_md "$entry"
          printf '\nFix the link, or add it to `.lycheeignore` to stop checking it.\n')
        out=$(gh issue create --title "$title" --label "$LABEL" \
          --body-file - <<<"$body") || die "gh issue create failed"
        echo "created #${out##*/} $title"
      fi
      created=$((created + 1))
      ;;
  esac
done < <(jq -c '.[]' <<<"$broken")

# 4. Close open issues whose URL is no longer broken.
while IFS=$'\t' read -r number title; do
  [[ -n $number ]] || continue
  url=${title#"$PREFIX"}
  if jq -e --arg u "$url" 'index($u) != null' <<<"$timeout_urls" >/dev/null; then
    echo "unchanged #$number (timed out)"
    unchanged=$((unchanged + 1))
    continue
  fi
  if jq -e --arg u "$url" 'index($u) != null' <<<"$ok_urls" >/dev/null; then
    why="works again"
    msg="The link works again."
  else
    why="no longer checked"
    msg="The weekly link check no longer checks this URL (removed from the docs or added to \`.lycheeignore\`)."
  fi
  gh_write issue close "$number" --reason completed \
    --comment "$(printf '%s\n' "$msg"; run_md)" >/dev/null \
    || die "gh issue close #$number failed"
  echo "$(would)$(past close d) #$number ($why)"
  closed=$((closed + 1))
done < <(jq -r --argjson b "$broken" --arg p "$PREFIX" '
  .[] | select(.state == "OPEN" and (.title | startswith($p)))
  | select(.title[($p | length):] as $u | $b | map(.url) | index($u) | not)
  | "\(.number)\t\(.title)"' <<<"$issues")

if $dry_run; then
  echo "dry run, nothing written: $created to create, $reopened to reopen," \
    "$closed to close, $unchanged unchanged"
else
  echo "done: $created created, $reopened reopened, $closed closed," \
    "$unchanged unchanged"
fi

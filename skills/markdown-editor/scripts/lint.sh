#!/usr/bin/env bash
# lint.sh - lint (and optionally fix) the repository's Markdown files with
# markdownlint-cli2.
#
# Usage: lint.sh [--fix] [--] [file...]
#   --fix     apply automatic fixes in place (a config with `fix: true` also
#             fixes without this flag; markdownlint-cli2 cannot override that)
#   file...   lint only these files; with none, lint the whole repository
#
# Scope (only files that belong to the git repository are ever touched):
#   - Runs inside the git work tree of the current directory, or else of the
#     given files. Paths outside it are reported and left alone, even with
#     --fix: "skipped (not a repository file): <path>".
#   - If a markdownlint-cli2 options file at the repo root defines `globs`
#     (.markdownlint-cli2.{jsonc,yaml,cjs,mjs}), the config is authoritative:
#     a sweep lets its globs/ignores/gitignore pick the files, and explicit
#     files it ignores print "skipped (ignored by config): <path>".
#   - Otherwise git decides: a sweep lints tracked and unignored *.md files;
#     gitignored explicit files print "skipped (not a repository file)".
#     Rule-only configs (.markdownlint.*) still apply to the files linted.
#
# markdownlint-cli2 is taken from PATH, else run through `npx --yes`.
#
# Exit codes: 0 clean or nothing to lint, 1 lint issues remain,
#             2 usage or environment error (not a git repo, no tool, ...).

set -euo pipefail

# Locate lib.sh next to this script, following symlinks (the skill is
# installed through symlinks into agent folders).
script_path=${BASH_SOURCE[0]}
while [ -L "$script_path" ]; do
  link=$(readlink "$script_path")
  case "$link" in
    /*) script_path=$link ;;
    *) script_path=$(dirname "$script_path")/$link ;;
  esac
done
SCRIPT_DIR=$(cd "$(dirname "$script_path")" && pwd -P)
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

# --- markdownlint-cli2 invocation ---------------------------------------------

# markdownlint-cli2 treats path arguments as globs: make metacharacters literal.
escape_glob() { printf '%s\n' "$1" | sed 's/[][*?{}()!#]/\\&/g'; }

# Set GLOB_ARGS to the escaped form of the given repo-relative paths.
to_glob_args() {
  local path
  GLOB_ARGS=()
  for path in "$@"; do GLOB_ARGS+=("$(escape_glob "$path")"); done
}

# Run markdownlint-cli2 with the given args (FIX_ARGS is prepended). Sets:
#   MDL_RC     tool exit code
#   MDL_FILES  number of files it actually linted
#   MDL_OUT    its findings, without the banner/summary noise
run_markdownlint() {
  local out rc=0
  out=$("${MDL_CMD[@]}" ${FIX_ARGS[@]+"${FIX_ARGS[@]}"} "$@" 2>&1) || rc=$?
  MDL_RC=$rc
  MDL_FILES=$(printf '%s\n' "$out" | sed -n 's/^Linting: \([0-9][0-9]*\) file.*/\1/p')
  MDL_FILES=${MDL_FILES:-0}
  if [ "$rc" -gt 1 ]; then
    MDL_OUT=$out # tool or config error: show everything
  else
    MDL_OUT=$(printf '%s\n' "$out" |
      grep -Ev '^(markdownlint-cli2 v|Finding:|Linting:|Summary: 0 issues)' || true)
  fi
}

# Print the findings of the last run, then map its exit code to ours.
report_markdownlint() {
  [ -z "$MDL_OUT" ] || printf '%s\n' "$MDL_OUT"
  case "$MDL_RC" in
    0) return 0 ;;
    1) return 1 ;;
    *) return 2 ;;
  esac
}

report_clean() {
  if [ "$1" -eq 0 ]; then
    echo 'ok: nothing to lint'
  else
    echo "ok: $1 file(s) clean"
  fi
}

# --- scope modes ---------------------------------------------------------------

# "config" when the repo's markdownlint-cli2 options say what to lint,
# otherwise "git".
lint_mode() {
  if markdownlint_config_selects_files "$1"; then echo config; else echo git; fi
}

# Lint the whole repository (from the repo root).
sweep() {
  if [ "$1" = config ]; then
    run_markdownlint # no path args: the config's globs/ignores apply
  else
    collect_git_files "$REPO_ROOT"
    if [ "${#GIT_FILES[@]}" -eq 0 ]; then
      report_clean 0
      return 0
    fi
    to_glob_args "${GIT_FILES[@]}"
    run_markdownlint --no-globs -- "${GLOB_ARGS[@]}"
  fi
  report_markdownlint || return $?
  report_clean "$MDL_FILES"
}

# Lint one kept file on its own; it may turn out to be ignored by the config.
# lint_one ARG REL   (ARG as the user wrote it, REL relative to the repo root)
lint_one() {
  local rc=0
  to_glob_args "$2"
  run_markdownlint --no-globs -- "${GLOB_ARGS[@]}"
  if [ "$MDL_FILES" -eq 0 ] && [ "$MDL_RC" -le 1 ]; then
    skipped 'ignored by config' "$1"
    return 0
  fi
  report_markdownlint || rc=$?
  if [ "$rc" -eq 0 ]; then echo "ok: $1"; fi
  return "$rc"
}

# Re-run the kept files one by one; returns the worst exit code.
lint_each() {
  local i rc=0 one
  for ((i = 0; i < ${#KEPT_REL[@]}; i++)); do
    one=0
    lint_one "${KEPT_ARG[i]}" "${KEPT_REL[i]}" || one=$?
    [ "$one" -le "$rc" ] || rc=$one
  done
  return "$rc"
}

# Lint the kept explicit files (KEPT_ARG/KEPT_REL, from the repo root).
lint_files() {
  [ "${#KEPT_REL[@]}" -gt 0 ] || return 0
  to_glob_args "${KEPT_REL[@]}"
  # One run for all files. Only if the tool dropped some (ignored by config)
  # re-run per file to say which; fixes are idempotent, so this is safe.
  run_markdownlint --no-globs -- "${GLOB_ARGS[@]}"
  if [ "$MDL_FILES" -ne "${#KEPT_REL[@]}" ] && [ "$MDL_RC" -le 1 ]; then
    lint_each
    return
  fi
  report_markdownlint || return $?
  report_clean "$MDL_FILES"
}

# --- main ----------------------------------------------------------------------

# Sets FIX_ARGS and FILES. -h prints the help and exits.
parse_args() {
  FIX_ARGS=()
  FILES=()
  while [ $# -gt 0 ]; do
    case "$1" in
      -h | --help) print_usage "$script_path"; exit 0 ;;
      --fix) FIX_ARGS=(--fix) ;;
      --) shift; FILES+=("$@"); break ;;
      -*) err "unknown option: $1 (see --help)"; return 2 ;;
      *) FILES+=("$1") ;;
    esac
    shift
  done
}

main() {
  local mode rc=0
  parse_args "$@" || return $?

  if ! resolve_repo_root ${FILES[@]+"${FILES[@]}"}; then
    err 'not in a git repository, nothing linted'
    return 2
  fi
  resolve_markdownlint || return 2
  mode=$(lint_mode "$REPO_ROOT")
  if [ "${#FIX_ARGS[@]}" -eq 0 ] && markdownlint_config_autofixes "$REPO_ROOT"; then
    echo 'note: config sets fix: true, so fixable issues are fixed in place'
  fi

  if [ "${#FILES[@]}" -eq 0 ]; then
    cd -- "$REPO_ROOT"
    sweep "$mode" || rc=$?
  else
    # Resolve the user's paths before changing directory.
    select_explicit_files "$REPO_ROOT" "$mode" "${FILES[@]}" || return $?
    cd -- "$REPO_ROOT"
    lint_files || rc=$?
  fi
  return "$rc"
}

main "$@"

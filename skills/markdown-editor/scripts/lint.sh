#!/usr/bin/env bash
# lint.sh - lint (and optionally fix) a project's Markdown files with
# markdownlint-cli2.
#
# Usage: lint.sh [--fix] [--] [file...]
#   --fix     apply automatic fixes in place (a config that enables `fix` also
#             fixes without this flag; markdownlint-cli2 cannot override that)
#   file...   lint only these files; with none, lint the whole project
#
# Project: the git work tree of the current directory; else the nearest parent
# directory with a markdownlint or lychee config (never $HOME or /); else the
# current directory. Only files inside it are ever touched: other paths print
# "skipped (not a project file): <path>", even with --fix.
#
# Scope:
#   - If a markdownlint-cli2 options file at the project root defines `globs`
#     (.markdownlint-cli2.{jsonc,yaml,cjs,mjs}), the config is authoritative:
#     a sweep lets its globs/ignores/gitignore pick the files, and explicit
#     files it ignores print "skipped (ignored by config): <path>". A sweep is
#     refused (exit 2), fixing or not, because it may write through a config
#     `fix` that cannot be reliably detected: if a glob is absolute, starts with
#     `~` or contains `..`; if the globs cannot be verified (.cjs/.mjs are
#     evaluated with node; a failure or a non-array refuses); or if any symlink
#     to a Markdown file or directory anywhere in the project (except .git)
#     points outside it. Lint explicit files instead.
#   - Otherwise the files are enumerated here: a sweep lints tracked and
#     unignored *.md files (git), or every *.md/*.markdown except in
#     node_modules and dot-directories (no git); gitignored explicit files print
#     "skipped (not a project file)". Rule-only configs (.markdownlint.*) and
#     `ignores` in an options file still apply to the files linted.
#   - Markdown symlinks pointing outside the project are never linted.
#
# markdownlint-cli2 is taken from PATH, else run through `npx --yes`.
#
# Exit codes: 0 clean or nothing to lint, 1 lint issues remain,
#             2 usage or environment error (no tool, unsafe config, ...).

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

# markdownlint-cli2 treats path arguments as globs: make metacharacters literal
# with bracket classes (backslashes do not work for braces; `!` and `#` only
# matter at the start, where a `./` prefix defuses them).
escape_glob() {
  local escaped
  escaped=$(printf '%s\n' "$1" | sed 's/[*?[{}()]/[&]/g')
  case "$escaped" in
    '!'* | '#'*) printf './%s\n' "$escaped" ;;
    *) printf '%s\n' "$escaped" ;;
  esac
}

# Set GLOB_ARGS to the escaped form of the given project-relative paths.
to_glob_args() {
  local path
  GLOB_ARGS=()
  for path in "$@"; do GLOB_ARGS+=("$(escape_glob "$path")"); done
}

# Run markdownlint-cli2 with the given args (FIX_ARGS is prepended). Sets:
#   MDL_RC     tool exit code
#   MDL_FILES  number of files it linted; EMPTY when unknown (the tool prints no
#              "Linting:" line with `noProgress: true`), which is not zero
#   MDL_OUT    its findings, without the banner/summary noise
run_markdownlint() {
  local out rc=0
  out=$("${MDL_CMD[@]}" ${FIX_ARGS[@]+"${FIX_ARGS[@]}"} "$@" 2>&1) || rc=$?
  MDL_RC=$rc
  MDL_FILES=$(printf '%s\n' "$out" | sed -n 's/^Linting: \([0-9][0-9]*\) file.*/\1/p')
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

# report_clean COUNT   (COUNT empty when unknown)
report_clean() {
  case "$1" in
    '') echo 'ok: no issues' ;;
    0) echo 'ok: nothing to lint' ;;
    *) echo "ok: $1 file(s) clean" ;;
  esac
}

# --- scope modes ---------------------------------------------------------------

# "config" when the project's markdownlint-cli2 options say what to lint,
# otherwise "list" (we enumerate the files).
lint_mode() {
  if markdownlint_config_selects_files "$1"; then echo config; else echo list; fi
}

# A config sweep hands file selection to markdownlint-cli2, and it may also
# write (a root, nested or computed `fix` setting cannot be reliably detected).
# So it only runs when nothing it can select leaves the project, whether or not
# it fixes; otherwise exit 2 and the caller lints explicit files instead.
check_config_sweep_is_contained() {
  local rc=0 links file hint
  file=$(markdownlint_options_file "$PROJECT_ROOT")
  hint='Lint explicit files instead: lint.sh [--fix] <file>...'
  markdownlint_globs_check "$PROJECT_ROOT" || rc=$?
  if [ "$rc" -eq 1 ]; then
    err "config globs must stay inside the project (no absolute, ~ or .. patterns): $file. $hint"
    return 2
  elif [ "$rc" -eq 2 ]; then
    err "cannot verify the globs of $file (computed, aliased, escaped, duplicated, or not evaluable with node). $hint"
    return 2
  fi
  links=$(list_outside_symlinks "$PROJECT_ROOT")
  if [ -n "$links" ]; then
    err "refusing to sweep: symlinks to Markdown files or directories point outside the project. $hint"
    printf '%s\n' "$links" | sed 's/^/  /' >&2
    return 2
  fi
}

# Lint the whole project (from the project root).
sweep() {
  if [ "$1" = config ]; then
    check_config_sweep_is_contained || return $?
    run_markdownlint # no path args: the config's globs/ignores apply
  else
    collect_project_files "$PROJECT_ROOT"
    if [ "${#PROJECT_FILES[@]}" -eq 0 ]; then
      report_clean 0
      return 0
    fi
    to_glob_args "${PROJECT_FILES[@]}"
    run_markdownlint --no-globs -- "${GLOB_ARGS[@]}"
  fi
  report_markdownlint || return $?
  report_clean "$MDL_FILES"
}

# Lint one kept file on its own; it may turn out to be ignored by the config.
# lint_one ARG REL   (ARG as the user wrote it, REL relative to the project root)
lint_one() {
  local rc=0
  to_glob_args "$2"
  run_markdownlint --no-globs -- "${GLOB_ARGS[@]}"
  # Only an explicit "Linting: 0 files" means ignored; unknown is not zero.
  if [ "$MDL_FILES" = 0 ] && [ "$MDL_RC" -le 1 ]; then
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

# Lint the kept explicit files (KEPT_ARG/KEPT_REL, from the project root).
lint_files() {
  [ "${#KEPT_REL[@]}" -gt 0 ] || return 0
  to_glob_args "${KEPT_REL[@]}"
  # One run for all files. Only if the tool reports fewer files than given
  # (some ignored by config) re-run per file to say which; fixes are
  # idempotent, so this is safe.
  run_markdownlint --no-globs -- "${GLOB_ARGS[@]}"
  if [ -n "$MDL_FILES" ] && [ "$MDL_FILES" -ne "${#KEPT_REL[@]}" ] && [ "$MDL_RC" -le 1 ]; then
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

  resolve_project_root || return 2
  resolve_markdownlint || return 2
  mode=$(lint_mode "$PROJECT_ROOT")
  if [ "${#FIX_ARGS[@]}" -eq 0 ] && markdownlint_config_autofixes "$PROJECT_ROOT"; then
    echo 'note: config enables fix, so fixable issues are fixed in place'
  fi

  if [ "${#FILES[@]}" -eq 0 ]; then
    cd -- "$PROJECT_ROOT"
    sweep "$mode" || rc=$?
  else
    # Resolve the user's paths before changing directory.
    select_explicit_files "$PROJECT_ROOT" "$mode" "${FILES[@]}" || return $?
    cd -- "$PROJECT_ROOT"
    lint_files || rc=$?
  fi
  return "$rc"
}

main "$@"

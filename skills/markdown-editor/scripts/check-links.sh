#!/usr/bin/env bash
# check-links.sh - check the links of a project's Markdown files with lychee.
# Makes network requests: run it on demand, not on every edit.
#
# Usage: check-links.sh [--] [file...]
#   file...   check only these files; with none, check the whole project
#
# Project: the git work tree of the current directory; else the nearest parent
# directory with a markdownlint or lychee config (never $HOME or /); else the
# current directory. Only files inside it are checked: other paths print
# "skipped (not a project file): <path>".
#
# Scope:
#   - If lychee.toml or .lycheeignore exists at the project root, the lychee
#     config is authoritative: a sweep runs `lychee .` from the root so
#     `exclude_path`, `extensions`, `.lycheeignore` and .gitignore decide.
#     `exclude_path` entries are REGULAR EXPRESSIONS, not globs (use
#     '(^|/)vendor/', not 'vendor/**'). lychee applies them to explicit files
#     too, and silently ("0 Total"), without a "skipped" line. Sweeps skip
#     dot-directories by default; explicit files in them are checked.
#     Without an `extensions` setting, a sweep is limited to Markdown files.
#   - Otherwise the files are enumerated here: tracked and unignored *.md files
#     (git), or every *.md/*.markdown except in node_modules and dot-directories
#     (no git); gitignored explicit files print "skipped (not a project file)".
#   - Markdown symlinks pointing outside the project are never checked.
#
# Exit codes: 0 all links ok or nothing to check, 1 broken links found,
#             2 usage or environment error,
#             3 lychee is not installed: NOTHING WAS CHECKED. This is not a
#               success; do not report the links as verified.

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

# --- lychee invocation -----------------------------------------------------------

# lychee treats path arguments as globs: make `*`, `?` and `[` literal.
escape_glob() { printf '%s\n' "$1" | sed 's/[*?[]/[&]/g'; }

# Set GLOB_ARGS to the escaped form of the given repo-relative paths.
to_glob_args() {
  local path
  GLOB_ARGS=()
  for path in "$@"; do GLOB_ARGS+=("$(escape_glob "$(safe_arg "$path")")"); done
}

# Print the guidance for a missing lychee, and say plainly nothing was checked.
lychee_missing() {
  cat >&2 <<'MSG'
lychee is not installed, so links were NOT checked.

Install it to enable link-checking, then re-run this check:
  macOS (Homebrew): brew install lychee
  Cargo:            cargo install lychee
  Other methods:    https://lychee.cli.rs/guides/getting-started/
MSG
  echo 'RESULT: URLs were not checked (lychee unavailable).'
}

# Run lychee with the given args and map its exit code to ours
# (lychee: 0 ok, 2 broken links, anything else a failure to run).
run_lychee() {
  local rc=0
  lychee --no-progress "$@" || rc=$?
  case "$rc" in
    0) return 0 ;;
    2) return 1 ;;
    *) return 2 ;;
  esac
}

# --- scope modes ---------------------------------------------------------------

# "config" when the project has a lychee config, otherwise "list" (we
# enumerate the files).
link_mode() {
  if has_lychee_config "$1"; then echo config; else echo list; fi
}

# Without an `extensions` setting lychee would also scan html, css, txt, ...
lychee_config_sets_extensions() {
  [ -f lychee.toml ] && grep -q '^[[:space:]]*extensions' lychee.toml
}

# Check the whole project (from the project root).
sweep() {
  if [ "$1" = config ]; then
    if lychee_config_sets_extensions; then
      run_lychee .
    else
      run_lychee --extensions md,markdown .
    fi
    return
  fi
  collect_project_files "$PROJECT_ROOT"
  if [ "${#PROJECT_FILES[@]}" -eq 0 ]; then
    echo 'ok: nothing to check'
    return 0
  fi
  to_glob_args "${PROJECT_FILES[@]}"
  run_lychee -- "${GLOB_ARGS[@]}"
}

# Check the kept explicit files (KEPT_REL, from the project root).
check_files() {
  [ "${#KEPT_REL[@]}" -gt 0 ] || return 0
  to_glob_args "${KEPT_REL[@]}"
  run_lychee -- "${GLOB_ARGS[@]}"
}

# --- main ----------------------------------------------------------------------

# Sets FILES. -h prints the help and exits.
parse_args() {
  FILES=()
  while [ $# -gt 0 ]; do
    case "$1" in
      -h | --help) print_usage "$script_path"; exit 0 ;;
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
  if ! command -v lychee >/dev/null 2>&1; then
    lychee_missing
    return 3
  fi
  mode=$(link_mode "$PROJECT_ROOT")

  if [ "${#FILES[@]}" -eq 0 ]; then
    cd -- "$PROJECT_ROOT"
    sweep "$mode" || rc=$?
  else
    # Resolve the user's paths before changing directory.
    select_explicit_files "$PROJECT_ROOT" "$mode" "${FILES[@]}" || return $?
    cd -- "$PROJECT_ROOT"
    check_files || rc=$?
  fi
  return "$rc"
}

main "$@"

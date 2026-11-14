# shellcheck shell=bash
# shellcheck disable=SC2034  # variables set here are the callers' results
# Shared helpers for the markdown-editor scripts. Sourced, never executed.
#
# Callers must run with `set -euo pipefail` and bash >= 3.2 (macOS default).
#
# Conventions:
#   - Results and "skipped (...)" lines go to stdout, "error: ..." to stderr.
#   - Exit codes: 0 ok, 1 findings, 2 usage/environment error, 3 tool missing.
#   - Every scope rule lives in exactly one function below:
#       resolve_repo_root   which git work tree we operate in
#       repo_relative       is a path inside that work tree
#       is_markdown_file    is a path a Markdown file
#       is_git_ignored      does git ignore a path
#       select_explicit_files  applies all of the above to user-given paths

err() { printf 'error: %s\n' "$*" >&2; }

skipped() { printf 'skipped (%s): %s\n' "$1" "$2"; }

# Print the leading comment block of a script ($1) as its --help text.
print_usage() {
  awk 'NR > 1 { if (/^#/) { sub(/^# ?/, ""); print } else exit }' "$1"
}

# --- paths -------------------------------------------------------------------

# Physical (symlink-free) absolute path of an existing directory.
abs_dir() { (cd -- "$1" 2>/dev/null && pwd -P); }

# Physical absolute path of a file; its directory must exist, the file need not.
abs_path() {
  local dir
  dir=$(abs_dir "$(dirname -- "$1")") || return 1
  printf '%s/%s\n' "${dir%/}" "$(basename -- "$1")"
}

# Print $2 relative to the directory $1 if it lies inside it, else fail.
repo_relative() {
  case "$2" in
    "$1"/*) printf '%s\n' "${2#"$1"/}" ;;
    *) return 1 ;;
  esac
}

# Make a repo-relative path safe as a command-line argument (no leading dash).
safe_arg() {
  case "$1" in
    -*) printf './%s\n' "$1" ;;
    *) printf '%s\n' "$1" ;;
  esac
}

is_markdown_file() {
  case "$1" in
    *.md | *.markdown) return 0 ;;
    *) return 1 ;;
  esac
}

# --- git ---------------------------------------------------------------------

# Set REPO_ROOT to the git work tree to operate in: the one containing the
# current directory, else the one containing the first given file.
resolve_repo_root() {
  local root file dir
  if root=$(git rev-parse --show-toplevel 2>/dev/null); then
    REPO_ROOT=$(abs_dir "$root")
    return 0
  fi
  for file in "$@"; do
    dir=$(dirname -- "$file")
    [ -d "$dir" ] || continue
    if root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null); then
      REPO_ROOT=$(abs_dir "$root")
      return 0
    fi
  done
  return 1
}

# is_git_ignored ROOT REL
is_git_ignored() { git -C "$1" check-ignore -q -- "$2"; }

# Fill GIT_FILES with the repo's tracked or unignored Markdown files.
# collect_git_files ROOT
collect_git_files() {
  local file
  GIT_FILES=()
  while IFS= read -r -d '' file; do
    [ -f "$1/$file" ] && GIT_FILES+=("$file")
  done < <(git -C "$1" ls-files -z -co --exclude-standard -- '*.md' '*.markdown')
  return 0
}

# --- explicit file selection -------------------------------------------------

# Validate user-given paths against the scope rules. Fills two parallel arrays
# of the files that remain: KEPT_ARG (as the user wrote them, for messages) and
# KEPT_REL (relative to ROOT, for the tools). Everything else is reported as
# "skipped (...)". Returns 2 (after printing an error) for a missing path.
#
# MODE "git":    also skip files git ignores (no tool config decides scope).
# MODE "config": leave ignores to the tool's own config.
#
# select_explicit_files ROOT MODE PATH...
select_explicit_files() {
  local root=$1 mode=$2 path abs rel
  shift 2
  KEPT_ARG=()
  KEPT_REL=()
  for path in "$@"; do
    if [ -d "$path" ]; then
      err "not a file: $path"
      return 2
    elif [ ! -e "$path" ]; then
      err "no such file: $path"
      return 2
    fi
    abs=$(abs_path "$path")
    if ! rel=$(repo_relative "$root" "$abs"); then
      skipped 'not a repository file' "$path"
    elif ! is_markdown_file "$rel"; then
      skipped 'not a Markdown file' "$path"
    elif [ "$mode" = git ] && is_git_ignored "$root" "$rel"; then
      skipped 'not a repository file' "$path"
    else
      KEPT_ARG+=("$path")
      KEPT_REL+=("$rel")
    fi
  done
  return 0
}

# --- configuration detection -------------------------------------------------

# Options files of markdownlint-cli2, in the tool's own priority order. They can
# carry `globs`/`ignores`/`gitignore`, i.e. decide which files are linted.
MARKDOWNLINT_OPTIONS_FILES=".markdownlint-cli2.jsonc .markdownlint-cli2.yaml
  .markdownlint-cli2.cjs .markdownlint-cli2.mjs"

# Rule-only configs of markdownlint (no file selection).
MARKDOWNLINT_RULES_FILES=".markdownlint.jsonc .markdownlint.json
  .markdownlint.yaml .markdownlint.yml .markdownlint.cjs .markdownlint.mjs"

# Print the first markdownlint-cli2 options file in DIR, if any.
# markdownlint_options_file DIR
markdownlint_options_file() {
  local name
  for name in $MARKDOWNLINT_OPTIONS_FILES; do
    if [ -f "$1/$name" ]; then
      printf '%s\n' "$1/$name"
      return 0
    fi
  done
  return 1
}

# Any markdownlint configuration in DIR, options file or rules-only.
# has_markdownlint_config DIR
has_markdownlint_config() {
  local name
  markdownlint_options_file "$1" >/dev/null && return 0
  for name in $MARKDOWNLINT_RULES_FILES; do
    [ -f "$1/$name" ] && return 0
  done
  return 1
}

# True when the options file in DIR defines `globs`, i.e. a run without path
# arguments knows what to lint. Textual check: works for every file format.
# markdownlint_config_selects_files DIR
markdownlint_config_selects_files() {
  local file
  file=$(markdownlint_options_file "$1") || return 1
  grep -q 'globs' "$file"
}

# True when the options file in DIR sets `fix: true`: markdownlint-cli2 then
# fixes files in place even without --fix (the CLI cannot switch it off).
# markdownlint_config_autofixes DIR
markdownlint_config_autofixes() {
  local file
  file=$(markdownlint_options_file "$1") || return 1
  grep -Eq '(^|[^[:alnum:]_])"?fix"?[[:space:]]*:[[:space:]]*true' "$file"
}

# lychee reads these from the working directory.
# has_lychee_config DIR
has_lychee_config() {
  [ -f "$1/lychee.toml" ] || [ -f "$1/.lycheeignore" ]
}

# --- tools -------------------------------------------------------------------

# Set MDL_CMD to the markdownlint-cli2 invocation: PATH first, then npx.
resolve_markdownlint() {
  if command -v markdownlint-cli2 >/dev/null 2>&1; then
    MDL_CMD=(markdownlint-cli2)
  elif command -v npx >/dev/null 2>&1; then
    MDL_CMD=(npx --yes markdownlint-cli2)
  else
    err 'markdownlint-cli2 is not installed and npx is unavailable to fetch it.'
    {
      echo 'Install it to lint Markdown files: npm install -g markdownlint-cli2'
      echo '(or install Node.js/npm so npx can run it without a global install)'
    } >&2
    return 1
  fi
}

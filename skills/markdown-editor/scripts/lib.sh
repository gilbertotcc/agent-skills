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
#       resolve_project_root   which directory is the project (PROJECT_ROOT)
#       project_relative       is a path inside the project
#       physical_path          where a path really points (symlinks resolved)
#       is_markdown_file       is a path a Markdown file
#       is_git_ignored         does git ignore a path (USE_GIT=yes only)
#       select_explicit_files  applies all of the above to user-given paths
#       collect_project_files  the file set of a sweep without a tool config
#   - A "project" is a git work tree, or else a directory holding a markdownlint
#     or lychee config, or else the current directory.

err() { printf 'error: %s\n' "$*" >&2; }

skipped() { printf 'skipped (%s): %s\n' "$1" "$2"; }

# Print the leading comment block of a script ($1) as its --help text.
print_usage() {
  awk 'NR > 1 { if (/^#/) { sub(/^# ?/, ""); print } else exit }' "$1"
}

# --- paths -------------------------------------------------------------------

# Physical (symlink-free) absolute path of an existing directory.
abs_dir() { (cd -- "$1" 2>/dev/null && pwd -P); }

# Physical absolute path of a file, following a chain of symlinks to its real
# target. The directories must exist; fails on a dangling link or a loop.
physical_path() {
  local path=$1 dir link hops=0
  while :; do
    dir=$(abs_dir "$(dirname -- "$path")") || return 1
    path="${dir%/}/$(basename -- "$path")"
    [ -L "$path" ] || break
    hops=$((hops + 1))
    [ "$hops" -le 40 ] || return 1
    link=$(readlink "$path")
    case "$link" in
      /*) path=$link ;;
      *) path="$(dirname -- "$path")/$link" ;;
    esac
  done
  printf '%s\n' "$path"
}

# Print $2 relative to the directory $1 if it lies inside it, else fail.
project_relative() {
  case "$2" in
    "$1"/*) printf '%s\n' "${2#"$1"/}" ;;
    *) return 1 ;;
  esac
}

# Make a project-relative path safe as a command-line argument (no leading dash).
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

# --- project root ------------------------------------------------------------

# Set PROJECT_ROOT and USE_GIT (yes|no) for the project containing START
# (default: the current directory):
#   1. the git top-level, if START is in a work tree;
#   2. else the nearest ancestor holding a markdownlint or lychee config (the
#      home directory and / never count, a personal ~/.markdownlint.json would
#      make every directory under $HOME one huge project);
#   3. else START itself.
# resolve_project_root [START]
resolve_project_root() {
  local start dir root home
  start=$(abs_dir "${1:-.}") || return 1
  if root=$(git -C "$start" rev-parse --show-toplevel 2>/dev/null); then
    PROJECT_ROOT=$(abs_dir "$root")
    USE_GIT=yes
    return 0
  fi
  USE_GIT=no
  home=$(abs_dir "${HOME:-/}" || true)
  dir=$start
  while [ "$dir" != / ] && [ "$dir" != "$home" ]; do
    if has_markdownlint_config "$dir" || has_lychee_config "$dir"; then
      PROJECT_ROOT=$dir
      return 0
    fi
    dir=$(dirname -- "$dir")
  done
  PROJECT_ROOT=$start
}

# --- project file set --------------------------------------------------------

# is_git_ignored ROOT REL
is_git_ignored() { git -C "$1" check-ignore -q -- "$2"; }

# Print the target of the symlink ROOT/REL if it lies outside ROOT, else fail.
# outside_symlink_target ROOT REL
outside_symlink_target() {
  local target
  [ -L "$1/$2" ] || return 1
  target=$(physical_path "$1/$2") || return 1
  project_relative "$1" "$target" >/dev/null && return 1
  printf '%s\n' "$target"
}

# Print the Markdown symlinks under ROOT (relative, one per line) whose target
# lies outside ROOT. Skips node_modules and .git.
# list_outside_symlinks ROOT
list_outside_symlinks() {
  local rel
  while IFS= read -r -d '' rel; do
    outside_symlink_target "$1" "${rel#./}" >/dev/null && printf '%s\n' "${rel#./}"
  done < <(cd -- "$1" && find . \( -name node_modules -o -name .git \) -prune -o \
    -type l \( -name '*.md' -o -name '*.markdown' \) -print0)
  return 0
}

# Fill PROJECT_FILES with the Markdown files of a sweep that no tool config
# decides. With git: tracked and unignored files. Without: every file under
# ROOT except in node_modules and dot-directories. Symlinks that point outside
# ROOT are reported and left out, so --fix can never write there.
# collect_project_files ROOT
collect_project_files() {
  local root=$1 rel
  PROJECT_FILES=()
  while IFS= read -r -d '' rel; do
    rel=${rel#./}
    [ -f "$root/$rel" ] || continue
    if outside_symlink_target "$root" "$rel" >/dev/null; then
      skipped 'not a project file' "$rel"
    else
      PROJECT_FILES+=("$rel")
    fi
  done < <(list_markdown_files "$root")
  return 0
}

# NUL-separated candidate files for collect_project_files.
list_markdown_files() {
  if [ "$USE_GIT" = yes ]; then
    git -C "$1" ls-files -z -co --exclude-standard -- '*.md' '*.markdown'
  else
    (cd -- "$1" && find . -mindepth 1 \( -name node_modules -o -name '.*' \) -prune -o \
      \( -type f -o -type l \) \( -name '*.md' -o -name '*.markdown' \) -print0)
  fi
}

# --- explicit file selection -------------------------------------------------

# Validate user-given paths against the scope rules. Fills two parallel arrays
# of the files that remain: KEPT_ARG (as the user wrote them, for messages) and
# KEPT_REL (relative to ROOT, for the tools). Everything else is reported as
# "skipped (...)". Returns 2 (after printing an error) for a missing path.
#
# MODE "list":   also skip files git ignores (when USE_GIT=yes); no tool config
#                decides scope.
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
    if ! abs=$(physical_path "$path") || ! rel=$(project_relative "$root" "$abs"); then
      skipped 'not a project file' "$path"
    elif ! is_markdown_file "$rel"; then
      skipped 'not a Markdown file' "$path"
    elif [ "$mode" = list ] && [ "$USE_GIT" = yes ] && is_git_ignored "$root" "$rel"; then
      skipped 'not a project file' "$path"
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

# Print the `globs` entry (key and value) of an options file; nothing if it has
# none. Textual, so it covers JSONC, YAML and a literal list in .cjs/.mjs: comment
# lines are skipped, a `[...]` list may span lines, and otherwise the value is
# the indented/`-` block that follows.
# markdownlint_globs_entry FILE
markdownlint_globs_entry() {
  awk '
    /^[[:space:]]*(\/\/|\/\*|\*|#)/ { next }
    state == 0 {
      if ($0 ~ /(^|[^[:alnum:]_.-])globs[ \t"\047]*:/) {
        print
        if ($0 ~ /\[/) { if ($0 !~ /\]/) state = 1; else exit }
        else state = 2
      }
      next
    }
    state == 1 { print; if ($0 ~ /\]/) exit; next }
    state == 2 { if ($0 ~ /^([[:space:]]|-|$)/) print; else exit }
  ' "$1"
}

# True when the options file in DIR defines `globs`, i.e. a run without path
# arguments knows what to lint.
# markdownlint_config_selects_files DIR
markdownlint_config_selects_files() {
  local file entry
  file=$(markdownlint_options_file "$1") || return 1
  entry=$(markdownlint_globs_entry "$file")
  [ -n "$entry" ]
}

# True when a `globs` pattern of the options file in DIR could reach outside
# the project: absolute, starting with `~`, or containing `..` (also negated).
# markdownlint_globs_unsafe DIR
markdownlint_globs_unsafe() {
  local file
  file=$(markdownlint_options_file "$1") || return 1
  markdownlint_globs_entry "$file" |
    grep -Eq "\\.\\.|(['\"[,]|-[[:space:]]+|:[[:space:]]+)!?[/~]"
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

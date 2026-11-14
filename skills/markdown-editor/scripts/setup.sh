#!/usr/bin/env bash
# setup.sh - add the skill's default lint and link-check configs to a project,
# without ever overwriting anything.
#
# Usage: setup.sh [--github-actions] [dir]
#   dir               target directory (default: the project root of the current
#                     directory: its git top-level, else the nearest parent with
#                     a markdownlint or lychee config, else the directory itself)
#   --github-actions  also add a GitHub Actions workflow that lints Markdown
#                     and checks links
#
# Copies the templates from ../assets/ (next to this script) into dir:
#   markdownlint-cli2.yaml -> .markdownlint-cli2.yaml
#   lychee.toml            -> lychee.toml
#   lycheeignore           -> .lycheeignore
#   check-markdown.yml     -> .github/workflows/check-markdown.yml
#                             (only with --github-actions)
# Each file prints "created: <file>", "skipped (exists): <file>", or
# "skipped (config exists): <file>" when another config of the same tool is
# already there: any markdownlint config; lychee.toml or .lycheeignore; for the
# workflow, any file in .github/workflows/ that mentions markdownlint or lychee.
#
# Exit codes: 0 done (even if everything was skipped),
#             2 usage or environment error (no target dir, templates missing).

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

ASSETS_DIR="$SCRIPT_DIR/../assets"
WORKFLOW=.github/workflows/check-markdown.yml

# install_template TEMPLATE TARGET_NAME CONFIG_EXISTS
# TARGET_NAME is relative to TARGET_DIR. CONFIG_EXISTS is "yes" when the tool
# already has a config there.
install_template() {
  local template=$1 name=$2 config_exists=$3
  if [ -e "$TARGET_DIR/$name" ]; then
    skipped exists "$name"
  elif [ "$config_exists" = yes ]; then
    skipped 'config exists' "$name"
  else
    mkdir -p -- "$(dirname -- "$TARGET_DIR/$name")"
    cp -- "$ASSETS_DIR/$template" "$TARGET_DIR/$name"
    echo "created: $name"
  fi
}

# True when a workflow in DIR already runs markdownlint or lychee.
# has_markdown_workflow DIR
has_markdown_workflow() {
  [ -d "$1/.github/workflows" ] || return 1
  grep -qiE 'markdownlint|lychee' "$1"/.github/workflows/*.y*ml 2>/dev/null
}

# Sets GITHUB_ACTIONS_FLAG (yes|no) and TARGET_ARG (may be empty).
parse_args() {
  GITHUB_ACTIONS_FLAG=no
  TARGET_ARG=
  while [ $# -gt 0 ]; do
    case "$1" in
      -h | --help) print_usage "$script_path"; exit 0 ;;
      --github-actions) GITHUB_ACTIONS_FLAG=yes ;;
      -*) err "unknown option: $1 (see --help)"; return 2 ;;
      *)
        if [ -n "$TARGET_ARG" ]; then
          err 'too many arguments (see --help)'
          return 2
        fi
        TARGET_ARG=$1
        ;;
    esac
    shift
  done
}

main() {
  local markdownlint=no lychee=no workflow=no template
  parse_args "$@" || return $?

  if [ -n "$TARGET_ARG" ]; then
    TARGET_DIR=$(abs_dir "$TARGET_ARG") || { err "no such directory: $TARGET_ARG"; return 2; }
  else
    resolve_project_root || return 2
    TARGET_DIR=$PROJECT_ROOT
  fi
  for template in markdownlint-cli2.yaml lychee.toml lycheeignore check-markdown.yml; do
    [ -f "$ASSETS_DIR/$template" ] || { err "template missing: assets/$template"; return 2; }
  done

  ! has_markdownlint_config "$TARGET_DIR" || markdownlint=yes
  ! has_lychee_config "$TARGET_DIR" || lychee=yes
  ! has_markdown_workflow "$TARGET_DIR" || workflow=yes
  install_template markdownlint-cli2.yaml .markdownlint-cli2.yaml "$markdownlint"
  install_template lychee.toml lychee.toml "$lychee"
  install_template lycheeignore .lycheeignore "$lychee"
  if [ "$GITHUB_ACTIONS_FLAG" = yes ]; then
    install_template check-markdown.yml "$WORKFLOW" "$workflow"
  fi
}

main "$@"

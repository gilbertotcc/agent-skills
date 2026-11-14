#!/usr/bin/env bash
# setup.sh - add the skill's default lint and link-check configs to a repo,
# without ever overwriting anything.
#
# Usage: setup.sh [dir]
#   dir   target directory (default: the git root of the current directory)
#
# Copies the templates from ../assets/ (next to this script) into dir:
#   markdownlint-cli2.yaml -> .markdownlint-cli2.yaml
#   lychee.toml            -> lychee.toml
#   lycheeignore           -> .lycheeignore
# Each file prints "created: <file>", "skipped (exists): <file>", or
# "skipped (config exists): <file>" when another config of the same tool is
# already there (any markdownlint config; lychee.toml or .lycheeignore).
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

# install_template TEMPLATE TARGET_NAME CONFIG_EXISTS
# CONFIG_EXISTS is "yes" when the tool already has a config in the target dir.
install_template() {
  local template=$1 name=$2 config_exists=$3
  if [ -e "$TARGET_DIR/$name" ]; then
    skipped exists "$name"
  elif [ "$config_exists" = yes ]; then
    skipped 'config exists' "$name"
  else
    cp -- "$ASSETS_DIR/$template" "$TARGET_DIR/$name"
    echo "created: $name"
  fi
}

main() {
  local dir=${1:-} markdownlint=no lychee=no template
  case "$dir" in
    -h | --help) print_usage "$script_path"; return 0 ;;
    -*) err "unknown option: $dir (see --help)"; return 2 ;;
  esac
  if [ $# -gt 1 ]; then
    err 'too many arguments (see --help)'
    return 2
  fi

  if [ -z "$dir" ]; then
    # shellcheck disable=SC2119  # no files: the current directory decides
    resolve_repo_root || { err 'not in a git repository; pass a directory'; return 2; }
    dir=$REPO_ROOT
  fi
  TARGET_DIR=$(abs_dir "$dir") || { err "no such directory: $dir"; return 2; }
  for template in markdownlint-cli2.yaml lychee.toml lycheeignore; do
    [ -f "$ASSETS_DIR/$template" ] || { err "template missing: assets/$template"; return 2; }
  done

  ! has_markdownlint_config "$TARGET_DIR" || markdownlint=yes
  ! has_lychee_config "$TARGET_DIR" || lychee=yes
  install_template markdownlint-cli2.yaml .markdownlint-cli2.yaml "$markdownlint"
  install_template lychee.toml lychee.toml "$lychee"
  install_template lycheeignore .lycheeignore "$lychee"
}

main "$@"

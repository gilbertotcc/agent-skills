#!/usr/bin/env bash
# Check every DIR/*/SKILL.md against the Agent Skills spec and AGENTS.md rules.
set -euo pipefail

MAX_DESCRIPTION=200
MAX_BODY=150

usage() {
  cat <<'USAGE'
Usage: check-skills.sh [DIR]

Check every DIR/*/SKILL.md against the Agent Skills spec and the authoring
rules in AGENTS.md.

Examples:
  check-skills.sh
  check-skills.sh path/to/skills

Arguments:
  DIR          Folder of skill folders (default: skills)

Options:
  -h, --help   Show this help

Errors fail the run; size limits only warn. Needs yq v4 (mikefarah).
Exit status: 0 no errors, 1 errors found, 2 usage error or missing yq.
USAGE
}

die() { echo "error: $*" >&2; exit 2; }
usage_error() {
  echo "error: $*" >&2
  echo "Try 'check-skills.sh --help'." >&2
  exit 2
}

dir=""
have_dir=false
no_more_options=false

while [[ $# -gt 0 ]]; do
  if ! $no_more_options; then
    case $1 in
      -h|--help) usage; exit 0 ;;
      --) no_more_options=true; shift; continue ;;
      -?*) usage_error "unknown option: $1" ;;
    esac
  fi
  $have_dir && usage_error "unexpected argument: $1"
  dir=$1
  have_dir=true
  shift
done
$have_dir || dir=skills
[[ -d $dir ]] || usage_error "not a directory: $dir"

command -v yq >/dev/null 2>&1 || die "yq not found (need mikefarah yq v4)"
yq_version=$(yq --version 2>&1 || true)
[[ $yq_version == *mikefarah* \
  && ( $yq_version == *" v4."* || $yq_version == *" 4."* ) ]] \
  || die "need mikefarah yq v4, found: $yq_version"

# Count characters, not bytes, in ${#var}.
for loc in C.UTF-8 en_US.UTF-8; do
  if [[ $(LC_ALL=$loc bash -c 'x=é; echo ${#x}' 2>/dev/null) == 1 ]]; then
    export LC_ALL=$loc
    break
  fi
done

errors=0
warnings=0
skills=0

report() { # report LEVEL FILE MESSAGE
  local level=$1 file=$2 msg=$3
  if [[ ${GITHUB_ACTIONS:-} == true ]]; then
    echo "::$level file=$file::$msg"
  else
    echo "$file: $level: $msg" >&2
  fi
  if [[ $level == error ]]; then errors=$((errors + 1)); else
    warnings=$((warnings + 1))
  fi
}

check_skill() {
  local folder=$1 file=$1/SKILL.md base bounds close total
  local kind name desc
  base=$(basename "$folder")

  if [[ ! -f $file ]]; then
    report error "$folder" "missing SKILL.md"
    return
  fi

  # Prints "CLOSING_LINE TOTAL_LINES"; empty when the frontmatter is not
  # delimited by --- lines.
  bounds=$(awk '
    { sub(/\r$/, "") }
    NR == 1 { if ($0 != "---") bad = 1; next }
    !bad && !end && $0 == "---" { end = NR }
    END { if (!bad && end) print end, NR }
  ' "$file")
  if [[ -z $bounds ]]; then
    report error "$file" \
      "frontmatter missing: must start with --- and end with a --- line"
    return
  fi
  close=${bounds% *}
  total=${bounds#* }

  if ! kind=$(yq --front-matter=extract 'tag' "$file" 2>/dev/null) \
    || [[ $kind != '!!map' ]]; then
    report error "$file" "frontmatter is not a valid YAML mapping"
    return
  fi

  if ! name=$(yq --front-matter=extract '.name // ""' "$file" 2>/dev/null); then
    report error "$file" "cannot read name"
    return
  fi
  if ! desc=$(yq --front-matter=extract '.description // ""' "$file" \
    2>/dev/null); then
    report error "$file" "cannot read description"
    return
  fi

  if [[ -z $name ]]; then
    report error "$file" "name missing or empty"
  elif [[ $name != "$base" ]]; then
    report error "$file" "name '$name' does not match folder '$base'"
  fi

  if [[ -z $desc ]]; then
    report error "$file" "description missing or empty"
  elif ((${#desc} > MAX_DESCRIPTION)); then
    report warning "$file" \
      "description is ${#desc} characters (max ~$MAX_DESCRIPTION)"
  fi

  if ((total - close > MAX_BODY)); then
    report warning "$file" \
      "body is $((total - close)) lines (max ~$MAX_BODY); move rare cases to references/"
  fi
}

for folder in "${dir%/}"/*/; do
  [[ -d $folder ]] || continue
  skills=$((skills + 1))
  check_skill "${folder%/}"
done

echo "Checked $skills skills: $errors errors, $warnings warnings"
((errors == 0)) || exit 1

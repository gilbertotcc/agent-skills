#!/usr/bin/env bash
# Print selected sections of the Guidelines part of clig.dev/llms.txt.
set -euo pipefail

URL=https://clig.dev/llms.txt

usage() {
  cat <<'USAGE'
Usage: clig-sections.sh [-f FILE] SECTION...
       clig-sections.sh [-f FILE] --list

Print sections from the Guidelines part of the Command Line Interface
Guidelines (https://clig.dev/llms.txt), so you need not read all 72 KB.

Examples:
  clig-sections.sh --list
  clig-sections.sh Output Errors
  clig-sections.sh 'Arguments and flags'

Arguments:
  SECTION          Section name as --list prints it; case-insensitive

Options:
  -f, --file FILE  Read FILE ('-' for stdin) instead of fetching clig.dev
  -l, --list       Print the section names, one per line
  -h, --help       Show this help

Exit status: 0 ok, 1 clig.dev unreadable or has no Guidelines sections,
2 usage error, 3 unknown section (stderr lists the valid names).
USAGE
}

usage_error() {
  echo "error: $*" >&2
  echo "Try 'clig-sections.sh --help'." >&2
  exit 2
}

file=""
have_file=false
list=false
names=""
count=0
no_more_options=false

while [[ $# -gt 0 ]]; do
  if ! $no_more_options; then
    case $1 in
      -h|--help) usage; exit 0 ;;
      -l|--list) list=true; shift; continue ;;
      -f|--file)
        $have_file && usage_error "option given twice: $1"
        [[ $# -ge 2 ]] || usage_error "option needs a value: $1"
        file=$2
        have_file=true
        shift 2
        continue
        ;;
      --file=*)
        $have_file && usage_error "option given twice: --file"
        file=${1#--file=}
        have_file=true
        shift
        continue
        ;;
      --) no_more_options=true; shift; continue ;;
      -?*) usage_error "unknown option: $1" ;;
    esac
  fi
  names=${names:+$names$'\n'}$1
  count=$((count + 1))
  shift
done

if $list; then
  [[ $count -eq 0 ]] || usage_error "--list takes no section names"
elif [[ $count -eq 0 ]]; then
  usage_error "missing SECTION (or use --list)"
fi

if $have_file; then
  if [[ $file == - ]]; then
    doc=$(cat) || { echo "error: cannot read stdin" >&2; exit 1; }
  else
    doc=$(cat -- "$file" 2>/dev/null) \
      || { echo "error: cannot read file: $file" >&2; exit 1; }
  fi
else
  if ! command -v curl >/dev/null 2>&1 \
    || ! doc=$(curl -fsSL --max-time 20 "$URL" 2>/dev/null); then
    echo "error: cannot read $URL; use the bundled checklist" >&2
    exit 1
  fi
fi

# Awk exits 4 when the document has no Guidelines sections, 3 on unknown names.
rc=0
out=$(printf '%s\n' "$doc" | CLIG_WANT=$names CLIG_LIST=$list awk '
  function norm(s) {
    sub(/[ \t]+\{#[^}]*\}[ \t]*$/, "", s)
    gsub(/&nbsp;/, " ", s)
    sub(/[ \t]+$/, "", s)
    return s
  }
  { sub(/\r$/, ""); line[NR] = $0 }
  substr($0, 1, 3) == "## " {
    ingl = (norm(substr($0, 4)) == "Guidelines")
    insec = 0
    next
  }
  ingl && substr($0, 1, 4) == "### " {
    ns++
    name[ns] = norm(substr($0, 5))
    first[ns] = NR
    insec = 1
    last[ns] = NR
    next
  }
  insec { last[ns] = NR }
  END {
    if (ns == 0) exit 4
    if (ENVIRON["CLIG_LIST"] == "true") {
      for (i = 1; i <= ns; i++) print name[i]
      exit 0
    }
    nw = split(ENVIRON["CLIG_WANT"], want, "\n")
    bad = 0
    for (w = 1; w <= nw; w++) {
      found = 0
      for (i = 1; i <= ns; i++)
        if (tolower(name[i]) == tolower(want[w])) { found = 1; pick[i] = 1 }
      if (!found) {
        print "error: unknown section: " want[w] > "/dev/stderr"
        bad = 1
      }
    }
    if (bad) {
      print "Sections:" > "/dev/stderr"
      for (i = 1; i <= ns; i++) print "  " name[i] > "/dev/stderr"
      exit 3
    }
    for (i = 1; i <= ns; i++)
      if (pick[i])
        for (n = first[i]; n <= last[i]; n++) print line[n]
  }
') || rc=$?

case $rc in
  0) [[ -z $out ]] || printf '%s\n' "$out" ;;
  4)
    echo "error: no Guidelines sections found; the clig.dev format may have changed" >&2
    exit 1
    ;;
  *) exit "$rc" ;;
esac

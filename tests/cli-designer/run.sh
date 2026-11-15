#!/usr/bin/env bash
# Offline tests for skills/cli-designer/scripts/clig-sections.sh.
# Lives outside the skill so it does not ship with it. Run: bash run.sh
set -uo pipefail

here=$(cd "$(dirname "$0")" && pwd)
script=$here/../../skills/cli-designer/scripts/clig-sections.sh
fx=$here/fixtures/llms.txt

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

pass=0
fail=0
out="" err="" rc=0

run() { # run ARGS... ; sets out, err, rc
  rc=0
  out=$(bash "$script" "$@" 2>"$tmp/err" </dev/null) || rc=$?
  err=$(cat "$tmp/err")
}

t() { # t NAME CONDITION (evaluated after run)
  if eval "$2"; then
    echo "PASS: $1"; pass=$((pass + 1))
  else
    echo "FAIL: $1 (rc=$rc out=[$out] err=[$err])"; fail=$((fail + 1))
  fi
}

has() { [[ $1 == *"$2"* ]]; }
hint="Try 'clig-sections.sh --help'."
cr=$(printf '\r')

run --help
t "--help exits 0 on stdout" '[[ $rc -eq 0 && -z $err ]] && has "$out" "Usage: clig-sections.sh"'

run
t "no args is usage error" '[[ $rc -eq 2 ]] && has "$err" "$hint" && [[ -z $out ]]'
run --bogus
t "unknown option is usage error" '[[ $rc -eq 2 ]] && has "$err" "unknown option" && has "$err" "$hint"'
run -f "$fx" --list Output
t "--list with section is usage error" '[[ $rc -eq 2 ]] && has "$err" "$hint"'
run Output -f
t "-f without value is usage error" '[[ $rc -eq 2 ]] && has "$err" "$hint"'
run -f "$fx" -f "$fx" Output
t "-f twice is usage error" '[[ $rc -eq 2 ]] && has "$err" "$hint"'

expected_list="Output
Errors
Arguments and flags
Subcommands
Robustness
Signals and control characters"
run -f "$fx" --list
t "--list prints only Guidelines names" '[[ $rc -eq 0 && $out == "$expected_list" ]]'
run --file="$fx" --list
t "--file=FILE works" '[[ $rc -eq 0 ]] && has "$out" "Subcommands"'

errors_section="### Errors {#errors}

ERRORS body line."
run -f "$fx" Errors
t "one section" '[[ $rc -eq 0 && $out == "$errors_section" ]]'
run -f "$fx" "Arguments and flags" Errors
t "several sections, document order" '[[ $rc -eq 0 ]] && has "$out" "ERRORS body" && has "$out" "ARGS body" && [[ ${out%%ERRORS*} != *ARGS* ]]'
run -f "$fx" oUTPUT
t "case-insensitive" '[[ $rc -eq 0 ]] && has "$out" "OUTPUT body"'
run -f "$fx" "arguments AND flags"
t "name with spaces" '[[ $rc -eq 0 ]] && has "$out" "ARGS body"'
run -f "$fx" Robustness
t "Robustness is the Guidelines one" '[[ $rc -eq 0 ]] && has "$out" "GUIDELINES-ROBUSTNESS" && ! has "$out" "PHILOSOPHY"'
run -f "$fx" Subcommands
t "Subcommands without anchor" '[[ $rc -eq 0 ]] && has "$out" "### Subcommands" && has "$out" "SUBCOMMANDS body"'
run -f "$fx" "signals and control characters"
t "&nbsp; name resolves with a space" '[[ $rc -eq 0 ]] && has "$out" "SIGNALS body"'
t "last section excludes Further reading" '! has "$out" "FURTHER-READING" && ! has "$out" "Further reading"'
run -f "$fx" Errors
t "stops at next heading" '[[ $rc -eq 0 ]] && ! has "$out" "ARGS" && ! has "$out" "OUTPUT"'
run -f "$fx" Output
t "#### subheading stays inside" '[[ $rc -eq 0 ]] && has "$out" "#### Output subheading" && has "$out" "OUTPUT-SUB" && ! has "$out" "ERRORS"'

run -f "$fx" Nope
t "unknown name exits 3, lists names" '[[ $rc -eq 3 && -z $out ]] && has "$err" "error: unknown section: Nope" && has "$err" "Sections:" && has "$err" "Arguments and flags"'
run -f "$fx" 'Output|Errors'
t "regex-like name is unknown" '[[ $rc -eq 3 && -z $out ]] && has "$err" "unknown section: Output|Errors"'
run -f "$fx" Output Nope
t "all-or-nothing on partial match" '[[ $rc -eq 3 && -z $out ]]'

run -f "$tmp/missing.txt" --list
t "missing file exits 1" '[[ $rc -eq 1 ]] && has "$err" "missing.txt"'
printf '# Title\n\n## Philosophy\n\n### Robustness\n\ntext\n' >"$tmp/nog.txt"
run -f "$tmp/nog.txt" --list
t "no Guidelines exits 1" '[[ $rc -eq 1 && -z $out ]] && has "$err" "format may have changed"'

rc=0
out=$(bash "$script" -f - Errors <"$fx" 2>"$tmp/err") || rc=$?
err=$(cat "$tmp/err")
t "stdin via -f -" '[[ $rc -eq 0 ]] && has "$out" "ERRORS body"'

sed "s/\$/$cr/" "$fx" >"$tmp/crlf.txt"
run -f "$tmp/crlf.txt" Errors "Arguments and flags"
t "CRLF input works, CR stripped" '[[ $rc -eq 0 ]] && has "$out" "ERRORS body" && ! has "$out" "$cr"'

run -f "$fx" Errors errors ERRORS
t "duplicate name printed once" '[[ $rc -eq 0 && $out == "$errors_section" ]]'

echo
echo "Passed: $pass, failed: $fail"
[[ $fail -eq 0 ]]

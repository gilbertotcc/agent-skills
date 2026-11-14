#!/usr/bin/env bash
# Regression tests for skills/markdown-editor/scripts. Lives outside the skill
# so it does not ship with it. Self-contained: fixtures are built in temporary
# directories (removed on exit), one PASS/FAIL/SKIP line per case, non-zero exit
# on any failure. Needs git and node/npx; link checks need lychee (else SKIP).
#
# Usage: tests/markdown-editor/run.sh

set -u

HERE=$(cd "$(dirname "$0")" && pwd -P)
SCRIPTS=$(cd "$HERE/../../skills/markdown-editor/scripts" && pwd -P)
TMP=$(cd "$(mktemp -d)" && pwd -P)
trap 'rm -rf "$TMP"' EXIT

PASS=0 FAIL=0 SKIP=0 GROUP=
OUT='' RC=0

if ! command -v markdownlint-cli2 >/dev/null 2>&1 && ! command -v npx >/dev/null 2>&1; then
  echo 'error: needs markdownlint-cli2 or npx (node)' >&2
  exit 2
fi

# --- helpers ---------------------------------------------------------------------

# check DESCRIPTION CMD...   PASS if CMD succeeds (CMD may use OUT and RC).
check() {
  local name=$1
  shift
  if "$@"; then
    PASS=$((PASS + 1)); echo "PASS: $GROUP: $name"
  else
    FAIL=$((FAIL + 1)); echo "FAIL: $GROUP: $name"
    printf '      rc=%s output: %s\n' "$RC" "$(printf '%s' "$OUT" | head -c 300 | tr '\n' '|')"
  fi
}

skip() { SKIP=$((SKIP + 1)); echo "SKIP: $GROUP: $1"; }

# run SCRIPT ARGS...   run a skill script in the current directory.
run() {
  local script=$1
  shift
  OUT=$("$SCRIPTS/$script" "$@" 2>&1)
  RC=$?
}

rc_is() { [ "$RC" -eq "$1" ]; }
out_has() { printf '%s' "$OUT" | grep -qF -- "$1"; }
out_lacks() { ! out_has "$1"; }

# Fixture files: bad_md has 5 lines and fixable issues, 3 lines once fixed.
bad_md() { printf '# T\n\n\n\nx\n' > "$1"; }
nlines() { wc -l < "$1" | tr -d ' '; }
is_untouched() { [ "$(nlines "$1")" -eq 5 ]; }
is_fixed() { [ "$(nlines "$1")" -eq 3 ]; }

# new_project NAME [git]   fresh directory under TMP, cd into it. A sibling
# "out.md" (bad_md) sits outside the project to detect writes beyond it.
new_project() {
  rm -rf "${TMP:?}/$1"
  mkdir -p "$TMP/$1/p"
  bad_md "$TMP/$1/out.md"
  cd "$TMP/$1/p" || exit 2
  if [ "${2:-}" = git ]; then git init -q .; fi
}
OUTSIDE=../out.md

# --- cases -----------------------------------------------------------------------

test_scope() {
  GROUP=scope
  new_project scope git
  printf 'globs: ["**/*.md"]\nignores: [".claude/**"]\n' > .markdownlint-cli2.yaml
  mkdir .claude; bad_md .claude/i.md; bad_md a.md; bad_md ../draft.md
  local sum
  sum=$(cksum < ../draft.md)

  run lint.sh --fix ../draft.md
  check 'outside path skipped' out_has 'skipped (not a project file)'
  check 'outside path: exit 0' rc_is 0
  check 'outside draft untouched' test "$sum" = "$(cksum < ../draft.md)"
  run lint.sh --fix .claude/i.md
  check 'config-ignored file skipped' out_has 'skipped (ignored by config)'
  check 'config-ignored file untouched' is_untouched .claude/i.md
  run lint.sh --fix a.md ../draft.md .claude/i.md
  check 'mixed: project file fixed' is_fixed a.md
  printf 'x\n' > notes.txt
  run lint.sh --fix notes.txt
  check 'non-Markdown skipped' out_has 'skipped (not a Markdown file)'
  run lint.sh nope.md
  check 'missing file: exit 2' rc_is 2
  bad_md b.md
  run lint.sh
  check 'config sweep without --fix reports issues' rc_is 1
  check 'config sweep leaves files alone' is_untouched b.md
  run lint.sh --fix
  check 'config sweep --fix fixes' is_fixed b.md
  check 'config sweep skips ignored dir' is_untouched .claude/i.md

  new_project scope-git git
  printf 'secret.md\n' > .gitignore; bad_md secret.md; bad_md tracked.md
  run lint.sh --fix secret.md
  check 'gitignored explicit file skipped' out_has 'skipped (not a project file)'
  run lint.sh --fix
  check 'sweep fixes unignored file' is_fixed tracked.md
  check 'sweep leaves gitignored file' is_untouched secret.md
}

test_symlinks() {
  GROUP=symlinks
  new_project sym git
  printf 'globs: ["**/*.md"]\n' > .markdownlint-cli2.yaml
  ln -s "$OUTSIDE" link.md
  run lint.sh --fix link.md
  check 'explicit outside symlink skipped' out_has 'skipped (not a project file)'
  check 'explicit outside symlink: target untouched' is_untouched "$OUTSIDE"
  run lint.sh --fix
  check 'config sweep --fix refused' rc_is 2
  check 'refusal names the symlink' out_has 'link.md'
  check 'sweep refusal: target untouched' is_untouched "$OUTSIDE"
  run lint.sh
  check 'read-only sweep still allowed' rc_is 1

  rm link.md; mkdir node_modules; ln -s ../"$OUTSIDE" node_modules/link.md
  printf 'globs: [":node_modules/link.md"]\n' > .markdownlint-cli2.yaml
  run lint.sh --fix
  check 'node_modules symlink selected by globs refused' rc_is 2
  check 'node_modules symlink: target untouched' is_untouched "$OUTSIDE"

  new_project sym-dir git
  printf 'globs: ["**/*.md"]\n' > .markdownlint-cli2.yaml
  mkdir ../shared; bad_md ../shared/s.md; ln -s ../shared docs
  run lint.sh --fix
  check 'outside directory symlink refused' rc_is 2
  check 'outside directory: target untouched' is_untouched ../shared/s.md
  run lint.sh --fix docs/s.md
  check 'file via outside directory skipped' out_has 'skipped (not a project file)'
  rm docs; mkdir real; bad_md real/r.md; ln -s real alias; ln -s real/r.md inlink.md
  run lint.sh --fix
  check 'in-project symlinks work' rc_is 0
  check 'in-project symlink target fixed' is_fixed real/r.md

  new_project sym-list git
  ln -s "$OUTSIDE" link.md; bad_md a.md
  run lint.sh --fix
  check 'list-mode sweep skips outside symlink' out_has 'skipped (not a project file): link.md'
  check 'list-mode sweep: target untouched' is_untouched "$OUTSIDE"
  check 'list-mode sweep fixes the rest' is_fixed a.md
}

# try_config NAME EXT CONTENT EXPECTED_RC [TEXT]   write the options file, run a
# --fix sweep, check exit code, message, and that ../out.md was never written.
try_config() {
  new_project cfg git
  printf '%s' "$3" > ".markdownlint-cli2.$2"
  bad_md in.md
  run lint.sh --fix
  check "$1: exit $4" rc_is "$4"
  [ -z "${5:-}" ] || check "$1: message" out_has "$5"
  check "$1: outside untouched" is_untouched "$OUTSIDE"
}

test_globs() {
  GROUP=globs
  local unsafe='config globs must stay inside the project'
  try_config 'parent glob' yaml $'globs: ["../out.md"]\n' 2 "$unsafe"
  try_config 'absolute glob' yaml $'globs:\n  - "**/*.md"\n  - "/etc/*.md"\n' 2 "$unsafe"
  try_config 'tilde glob' jsonc $'{ "globs": ["~/x.md"] }\n' 2 "$unsafe"
  try_config 'quoted key (jsonc)' jsonc $'{ "globs": ["../out.md"] }\n' 2 "$unsafe"
  try_config 'quoted key (yaml)' yaml $'\'globs\': [\'../out.md\']\n' 2 "$unsafe"
  try_config 'multi-line list' jsonc $'{\n  "globs": [\n    "a.md", // x\n    "../out.md"\n  ]\n}\n' 2 "$unsafe"
  try_config 'inline comment after real globs' yaml $'globs: ["**/*.md"] # ["../out.md"]\n' 0
  try_config 'globs only in an inline comment' yaml $'ignores: [] # globs: ["../out.md"]\n' 0
  try_config 'globs only in a quoted string' jsonc $'{ "ignores": ["globs: [\\"../x\\"]"] }\n' 0
  try_config 'computed cjs, unsafe' cjs $'const s = ["../out.md"];\nmodule.exports = { globs: s };\n' 2 "$unsafe"
  try_config 'computed cjs, safe' cjs $'const s = ["**/*.md"];\nmodule.exports = { globs: s };\n' 0
  try_config 'computed mjs, unsafe' mjs $'const s = [".." + "/out.md"];\nexport default { globs: s };\n' 2 "$unsafe"
  try_config 'cjs that throws' cjs $'throw new Error("x");\nmodule.exports = { globs: ["a.md"], fix: true };\n' 2 'cannot verify'
  try_config 'cjs globs not an array' cjs $'module.exports = { globs: "**/*.md" };\n' 2 'cannot verify'
  try_config 'yaml alias' yaml $'x: &g ["../out.md"]\nglobs: *g\n' 2 'cannot verify'
}

# try_fix NAME EXT CONTENT EXPECT   run a plain sweep (no --fix) next to an
# outside symlink: EXPECT "refused" when the config effectively enables fix.
try_fix() {
  new_project fix git
  printf '%s' "$3" > ".markdownlint-cli2.$2"
  ln -s "$OUTSIDE" link.md
  run lint.sh
  if [ "$4" = refused ]; then
    check "$1: refused" rc_is 2
    check "$1: names the cause" out_has 'refusing to fix'
  else
    check "$1: not refused" out_lacks 'refusing to fix'
  fi
  check "$1: outside untouched" is_untouched "$OUTSIDE"
}

test_effective_fix() {
  GROUP=fix
  try_fix 'bare true' yaml $'globs: ["**/*.md"]\nfix: true\n' refused
  try_fix 'quoted key (yaml)' yaml $'globs: ["**/*.md"]\n\'fix\': true\n' refused
  try_fix 'quoted key (jsonc)' jsonc $'{ "globs": ["**/*.md"], "fix": true }\n' refused
  try_fix 'non-boolean value' yaml $'globs: ["**/*.md"]\nfix: "false"\n' refused
  try_fix 'computed cjs' cjs $'module.exports = { globs: ["**/*.md"], fix: Boolean(1) };\n' refused
  try_fix 'computed mjs' mjs $'export default { globs: ["**/*.md"], fix: 1 === 1 };\n' refused
  try_fix 'unevaluable cjs' cjs $'throw 1;\nmodule.exports = { globs: ["**/*.md"] };\n' refused
  try_fix 'false' yaml $'globs: ["**/*.md"]\nfix: false\n' ok
  try_fix 'quoted false' jsonc $'{ "globs": ["**/*.md"], "fix": false }\n' ok
  try_fix 'false, true in a comment' yaml $'globs: ["**/*.md"]\nfix: false # fix: true\n' ok
  try_fix 'no fix key' yaml $'globs: ["**/*.md"]\n' ok
  try_fix 'computed false' cjs $'module.exports = { globs: ["**/*.md"], fix: false };\n' ok

  new_project fix-explicit git
  printf 'globs: ["**/*.md"]\nfix: true\n' > .markdownlint-cli2.yaml
  ln -s "$OUTSIDE" link.md; bad_md a.md
  run lint.sh a.md
  check 'explicit file with config fix: fixed' is_fixed a.md
  check 'explicit file with config fix: note shown' out_has 'note: config enables fix'
}

test_special_names() {
  GROUP=names
  new_project names git
  local n
  for n in 'notes!.md' 'a#b.md' '!lead.md' '#hash.md' 'br{a,b}.md' 'st*r.md' 'b[1] x.md' 'sp ace (1).md'; do
    bad_md "$n"
    run lint.sh --fix "$n"
    check "explicit $n" is_fixed "$n"
  done
  printf 'globs: ["**/*.md"]\n' > .markdownlint-cli2.yaml
  for n in 'notes!.md' '!lead.md' 'b[1] x.md'; do bad_md "$n"; done
  run lint.sh --fix
  check 'config sweep fixes special names' is_fixed '!lead.md'
  run lint.sh --fix 'b[1] x.md' '!lead.md'
  check 'explicit special names under a config' rc_is 0
}

test_no_progress() {
  GROUP=noProgress
  new_project np git
  printf 'noProgress: true\nglobs: ["**/*.md"]\nconfig:\n  MD041: true\n' > .markdownlint-cli2.yaml
  printf 'no heading\n' > bad.md
  run lint.sh bad.md
  check 'explicit: issue reported, exit 1' rc_is 1
  check 'explicit: diagnostics kept' out_has 'MD041'
  run lint.sh
  check 'sweep: exit 1' rc_is 1
  printf 'globs: [\n' > .markdownlint-cli2.yaml
  run lint.sh bad.md
  check 'broken config: exit 2' rc_is 2
}

test_no_git() {
  GROUP=no-git
  new_project nogit
  mkdir -p node_modules/m .hid docs/deep ../draft
  bad_md a.md; bad_md docs/b.md; bad_md node_modules/m/n.md; bad_md .hid/h.md
  bad_md docs/c.markdown; bad_md ../draft/issue.md
  run lint.sh --fix
  check 'sweep fixes project files' is_fixed docs/b.md
  check 'sweep covers .markdown' is_fixed docs/c.markdown
  check 'sweep leaves node_modules' is_untouched node_modules/m/n.md
  check 'sweep leaves dot-directories' is_untouched .hid/h.md
  run lint.sh --fix ../draft/issue.md
  check 'file outside the project skipped' out_has 'skipped (not a project file)'
  check 'draft untouched' is_untouched ../draft/issue.md
  run lint.sh --fix .hid/h.md
  check 'explicit file in a dot-directory is linted' is_fixed .hid/h.md

  new_project nogit-cfg
  printf 'config:\n  default: true\n' > .markdownlint-cli2.yaml
  mkdir -p docs/deep; bad_md a.md; bad_md docs/deep/d.md
  cd docs/deep || exit 2
  run lint.sh --fix ../../a.md
  check 'root found via parent config' is_fixed ../../a.md
  run lint.sh --fix ../../../out.md
  check 'outside the config-rooted project skipped' out_has 'skipped (not a project file)'
  check 'outside file untouched' is_untouched ../../../out.md
}

test_links() {
  GROUP=links
  if ! command -v lychee >/dev/null 2>&1; then
    skip 'lychee not installed'
  else
    new_project links git
    printf '[a](missing.md)\n' > 'b[1] x.md'; printf '# ok\n' > ok.md; printf '[a](missing.md)\n' > ../outside.md
    run check-links.sh ok.md
    check 'clean file: exit 0' rc_is 0
    run check-links.sh 'b[1] x.md'
    check 'broken link in special-name file: exit 1' rc_is 1
    run check-links.sh ../outside.md
    check 'outside file skipped' out_has 'skipped (not a project file)'
    run check-links.sh
    check 'sweep: exit 1' rc_is 1
    new_project links-nogit
    printf '[a](missing.md)\n' > a.md; mkdir node_modules; printf '[a](gone.md)\n' > node_modules/n.md
    run check-links.sh
    check 'no git: sweep finds broken link' rc_is 1
    check 'no git: sweep skips node_modules' out_lacks 'gone.md'
  fi
  # lychee missing must be distinguishable from success (exit 3).
  if (PATH=/usr/bin:/bin command -v lychee) >/dev/null 2>&1; then
    skip 'lychee found in /usr/bin'
  else
    new_project links-nolychee
    OUT=$(PATH=/usr/bin:/bin "$SCRIPTS/check-links.sh" 2>&1); RC=$?
    check 'lychee missing: exit 3' rc_is 3
    check 'lychee missing: says nothing was checked' out_has 'URLs were not checked'
  fi
}

test_setup() {
  GROUP=setup
  new_project setup
  run setup.sh
  check 'first run creates 3 files' test "$(printf '%s\n' "$OUT" | grep -c '^created:')" -eq 3
  run setup.sh
  check 'second run skips all' test "$(printf '%s\n' "$OUT" | grep -c '^skipped (exists):')" -eq 3
  check 'no workflow without the flag' test ! -e .github
  run setup.sh --github-actions
  check '--github-actions creates the workflow' out_has 'created: .github/workflows/check-markdown.yml'
  run setup.sh --github-actions
  check '--github-actions never overwrites' out_has 'skipped (exists): .github/workflows/check-markdown.yml'

  new_project setup-wf
  mkdir -p .github/workflows
  printf 'steps:\n- uses: lycheeverse/lychee-action@v2\n' > .github/workflows/links.yml
  run setup.sh --github-actions "$PWD"
  check 'existing lychee workflow: config exists' out_has 'skipped (config exists): .github/workflows/check-markdown.yml'
  new_project setup-cfg
  printf '{}' > .markdownlint.json
  run setup.sh
  check 'other markdownlint config: config exists' out_has 'skipped (config exists): .markdownlint-cli2.yaml'
  run setup.sh --bogus
  check 'unknown option: exit 2' rc_is 2
}

# --- main ------------------------------------------------------------------------

test_scope
test_symlinks
test_globs
test_effective_fix
test_special_names
test_no_progress
test_no_git
test_links
test_setup

printf '\n%s passed, %s failed, %s skipped\n' "$PASS" "$FAIL" "$SKIP"
[ "$FAIL" -eq 0 ]

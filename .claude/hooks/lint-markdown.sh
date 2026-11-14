#!/bin/sh
# PostToolUse hook (Edit|Write): lint and auto-fix an edited Markdown file with
# the markdown-editor skill's lint.sh, whose scope rules keep files outside the
# repo, ignored by its config or gitignored untouched.
#
# Silent on success and on "skipped"; on remaining issues or an environment
# error prints lint.sh's message to stderr and exits 2 so the agent sees it.
[ -n "$CLAUDE_PROJECT_DIR" ] || exit 0

file=$(node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{
  process.stdout.write(JSON.parse(s).tool_input?.file_path ?? "")})')

# Only Markdown files inside the project.
case "$file" in
  "$CLAUDE_PROJECT_DIR"/*.md) ;;
  *) exit 0 ;;
esac

cd "$CLAUDE_PROJECT_DIR" || exit 0
out=$("$CLAUDE_PROJECT_DIR"/skills/markdown-editor/scripts/lint.sh --fix -- \
  "$file" 2>&1) && exit 0

# Drop informational lines (skipped/ok/note); keep issues and errors.
echo "$out" | grep -Ev '^(skipped \(|ok: |note: )' >&2
exit 2

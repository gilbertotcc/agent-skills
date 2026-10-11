#!/bin/sh
# PostToolUse hook: lint an edited Markdown file. Silent on success; on
# failure, prints the remaining issues to stderr and exits 2 so the agent
# sees them.
file=$(node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{
  process.stdout.write(JSON.parse(s).tool_input?.file_path ?? "")})')

# Only Markdown files inside the project.
case "$file" in
  "$CLAUDE_PROJECT_DIR"/*.md) ;;
  *) exit 0 ;;
esac

cd "$CLAUDE_PROJECT_DIR" || exit 0
out=$(npx --yes markdownlint-cli2 "$file" 2>&1) && exit 0
echo "$out" | grep -v -e '^markdownlint-cli2 v' -e '^Finding:' \
  -e '^Linting:' >&2
exit 2

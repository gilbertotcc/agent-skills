# AGENTS.md

Portable, agent-agnostic skills in `skills/<name>/`, following the
[Agent Skills specification](https://agentskills.io/specification). Skills
must not depend on any specific AI agent.

## Writing skills

Use your agent's skill-authoring skill (e.g. `skill-creator`); these rules
take precedence. Keep consumers' token cost low:

- `description` ≤ ~200 chars: what it does, then when to use it.
- `SKILL.md` body ≤ ~150 lines; move rare cases to `references/`.
- Prefer `scripts/` over prose procedures (only output enters context).
- One or two short examples; no `README.md` duplicating `SKILL.md`.

## Development skills

Dev-only skills, not part of the collection. Skills pinned in
`skills-lock.json` are installed by the `skills` CLI in `.agents/skills/`
and linked into agent folders (e.g. `.claude/skills/`). Manage them only
via the CLI (`npx skills experimental_install --agent <agent>` to restore,
`npx skills update -p`). Other dev skills are authored in
`.claude/skills/` and edited directly. `.agents/` and `.claude/` are
excluded from lint and link checks; keep them so.

## Commits

Use `caveman-commit`, but always end with a `Co-Authored-By:` trailer naming
the AI agent or model.

## Checks

No build or tests; CI runs only these:

```sh
npx markdownlint-cli2 [file]   # lint, auto-fixes in place; wrap prose at 80
lychee --no-progress .         # links; skip URLs via .lycheeignore
```

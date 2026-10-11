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

`.claude/skills/` holds dev-only skills, not part of the collection. Skills
pinned in `skills-lock.json` are managed only via the `skills` CLI
(`npx skills experimental_install` to restore, `npx skills update -p`);
others are authored here and edited directly. `.claude/` is excluded from
lint and link checks; keep it so.

## Commits

Use `caveman-commit`, but always end with a `Co-Authored-By:` trailer naming
the AI agent or model.

## Checks

No build or tests; CI runs only these:

```sh
npx markdownlint-cli2 [file]   # lint, auto-fixes in place; wrap prose at 80
lychee --no-progress .         # links; skip URLs via .lycheeignore
```

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

Skills used to develop this repo, third-party or from `skills/`. Skills
pinned in `skills-lock.json` are installed by the `skills` CLI in
`.agents/skills/` and linked into agent folders (e.g. `.claude/skills/`).
Manage them only via the CLI
(`npx skills experimental_install --agent <agent>` to restore,
`npx skills update -p`); edit collection skills in `skills/`, never their
installed copies. Other dev skills are authored in
`.claude/skills/` and edited directly. `.agents/` and `.claude/` are
excluded from lint and link checks; keep them so.

## Commits and PRs

Use `caveman-commit`, but always end with a `Co-Authored-By:` trailer naming
the AI agent or model. Never include session links (remote control, web or
cloud sessions, session share URLs) in commits or PRs.

## Markdown

Create and edit Markdown with the `markdown-editor` skill (from
`skills/markdown-editor/`, installed as a dev skill; the CLI copies local
sources, so after editing it run
`npx skills experimental_install --force --agent <agent>`). Text for external
tools (issue, PR and comment bodies) is out of its scope: draft it outside
the repo, one line per paragraph.

## Checks

No build or tests; CI runs only these:

```sh
skills/markdown-editor/scripts/lint.sh [--fix] [file]  # lint; wrap prose at 80
skills/markdown-editor/scripts/check-links.sh [file]   # links; .lycheeignore
npx skills add . --list   # skills discoverable (when skills/ changes)
```

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
- One or two short examples; no `README.md` duplicating `SKILL.md`. The
  user-facing skill README is the exception.
- Every skill README states requirements and security notes, and
  `SKILL.md` declares requirements in frontmatter (`compatibility`,
  `metadata.requires-env`), as `.claude/rules/skill-readme.md` describes.
- Adding, renaming or removing a skill, or changing its `description`,
  updates the `README.md` Skills table.

## Development skills

Skills used to develop this repo. Third-party skills are pinned in
`skills-lock.json`, installed by the `skills` CLI in `.agents/skills/` and
linked into agent folders (e.g. `.claude/skills/`); manage them only via the
CLI (`npx skills experimental_install --agent <agent>` to restore,
`npx skills update -p`). Collection skills from `skills/` are symlinked
instead (`.agents/skills/<name>` and `.claude/skills/<name>` point to
`../../skills/<name>`), so there is one copy; edit them in `skills/`. Other
dev skills are authored in `.claude/skills/` and edited directly.
`.agents/` and `.claude/` are excluded from lint and link checks; keep them
so.

## Commits and PRs

Use `caveman-commit`, but always end with a `Co-Authored-By:` trailer naming
the AI agent or model. Never include session links (remote control, web or
cloud sessions, session share URLs) in commits or PRs.

## Markdown

Create and edit Markdown with the `markdown-editor` skill (a dev skill
linked from `skills/markdown-editor/`). Text for external tools (issue, PR
and comment bodies) is out of its scope: draft it outside the repo, one line
per paragraph.

## Checks

No build; CI runs the equivalent of these:

```sh
npx --yes markdownlint-cli2 [--fix]  # lint; wrap prose at 80
lychee --no-progress --hidden .      # links; .lycheeignore
npx skills add . --list              # skills discoverable (when skills/ changes)
.github/scripts/check-skills.sh      # SKILL.md rules (when skills/ changes)
tests/<skill>/run.sh                 # skill script tests (when the skill changes)
```

CI also runs the spec's `skills-ref validate` on each skill.

Links are also checked weekly; each broken URL gets one `broken-link` issue,
closed when the URL works again. Fix the link or add it to `.lycheeignore`.

Script tests are optional. When a skill has them, they live in
`tests/<skill>/`, outside `skills/`, so they don't ship with the skill,
and the skill gets its own `.github/workflows/test-<skill>.yml`, filtered
to `skills/<skill>/**` and `tests/<skill>/**`, so its tests run only when
they can be affected.

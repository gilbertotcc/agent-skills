# Agent skills

[![skills.sh](https://skills.sh/b/gilbertotcc/agent-skills)](https://skills.sh/gilbertotcc/agent-skills)

This repository provides a collection of skills for diverse AI-aided tasks.

They follow the
[Agent Skills specification](https://agentskills.io/specification) and are
designed to be portable and independent of any specific AI agent. If
vendor-specific details appear in a skill, they are mistakes worth reporting
or fixing, not exceptions to the portability principle.

The author wrote them during their personal exploration of AI capabilities.
They tested, refined, and iterated on them until the agent's behavior was good
enough to reuse the skill. Sharing them is the last phase of the process: even
if, in the AI era, all are creators, luckily many of them still consider
someone else's (mis)know-how valuable, worth reusing, adapting, and evolving.

> [!WARNING]
> These skills have been used and refined in real work, but their behavior
> has not been formally verified: review them before use, and use them at
> your own risk.

## Skills

| Skill                                      | Description                                                                          |
| ------------------------------------------ | ------------------------------------------------------------------------------------ |
| [cli-designer](skills/cli-designer/)       | Design, validate and extend CLIs following the Command Line Interface Guidelines.    |
| [markdown-editor](skills/markdown-editor/) | Write and edit a project's Markdown in its own markdownlint-cli2 style; check links. |

## Usage

Install the skills with [skills.sh](https://www.skills.sh/), which links
them where your agent looks for them:

```sh
npx skills add gilbertotcc/agent-skills                 # pick interactively
npx skills add gilbertotcc/agent-skills --skill <name>  # one skill
```

## Development

Although the skills are independent of any AI agent, this repository is
configured for developing them with Claude Code.

The skills are engineered around a few principles:

- **Portable:** they follow the Agent Skills specification and depend on no
  specific agent.
- **Cheap to load:** a short `description` and `SKILL.md` keep the token cost
  low; rare cases move to `references/`.
- **Scripts over prose:** procedures live in `scripts/`, so only their output
  enters the agent's context.
- **Testable scripts:** a skill's scripts can be tested; their tests live
  outside the skill and run in the skill's own CI workflow.
- **Declared requirements and security notes:** each skill's `README.md` and
  `SKILL.md` frontmatter state what it needs, and what it sends, runs or
  changes.

See [AGENTS.md](AGENTS.md) for the full authoring rules.

### Repository layout

- `skills/<name>/`: the published skills, each with its `SKILL.md`, a
  user-facing `README.md`, and optional `scripts/`, `references/` and
  `assets/`.
- `tests/<skill>/`: script tests, kept outside `skills/` so they don't ship
  with the skill; `.github/workflows/test-<skill>.yml` runs them.
- `.agents/skills/`: third-party skills used to develop this repository,
  installed by the `skills` CLI and pinned in `skills-lock.json`.
- `.claude/`: Claude Code's links to those skills, its rules, and any
  Claude-only development skills.

Collection skills used in development, such as `markdown-editor`, are
symlinked from `.agents/skills/<name>` and `.claude/skills/<name>` to
`../../skills/<name>`, so there is a single copy to edit.

### Setup

Agent skills used while developing this repository are managed with
[skills.sh](https://www.skills.sh/), pinned in `skills-lock.json` and
installed in `.agents/skills/`. To restore them for Claude Code:

```sh
npx skills experimental_install --agent claude-code
```

For another agent, replace `claude-code` with its name, so that `skills`
links the skills where that agent looks for them.

To try this repository's skills locally before publishing them:

```sh
npx skills add ./skills --agent claude-code
```

### Checks

CI runs these checks; run them locally before opening a pull request:

```sh
npx --yes markdownlint-cli2      # add --fix to auto-fix
lychee --no-progress --hidden .  # check links
npx skills add . --list          # every skill is discoverable
.github/scripts/check-skills.sh  # SKILL.md rules; needs yq v4
tests/<skill>/run.sh             # a skill's script tests
```

CI also validates each skill with `skills-ref validate skills/<name>`, the
specification's
[reference validator](https://github.com/agentskills/agentskills); see
[check-skills.yml](.github/workflows/check-skills.yml) for the pinned version.

## License

[MIT](LICENSE). Use, fork and adapt these skills freely. If you improve one or
find a problem, please open an issue or a pull request.

# Agent skills

This repository provides Gilberto’s agent skills for use in diverse AI-aided
tasks. These skills follow the
[Agent Skills specification](https://agentskills.io/specification) and are
designed to be portable and independent of any specific AI agent.

Although the author has used these skills—otherwise, he shouldn’t have created
them—their behavior has not been formally verified, so use at your own risk.

## Usage

Install the skills with [skills.sh](https://www.skills.sh/), which links
them where your agent looks for them:

```sh
npx skills add gilbertotcc/agent-skills                 # pick interactively
npx skills add gilbertotcc/agent-skills --skill <name>  # one skill
```

### Skills

| Skill | Description    |
| ----- | -------------- |
| —     | No skills yet. |

## Development

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

## Quality checks

```sh
npx markdownlint-cli2
lychee .
npx skills add . --list   # every skill is discoverable
```

## License

[MIT](LICENSE)

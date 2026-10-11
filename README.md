# Agent skills

This repository provides Gilberto’s agent skills for use in diverse AI-aided
tasks. These skills follow the
[Agent Skills specification](https://agentskills.io/specification) and are
designed to be portable and independent of any specific AI agent.

Although the author has used these skills—otherwise, he shouldn’t have created
them—their behavior has not been formally verified, so use at your own risk.

## Prerequisites

- [Node.js](https://nodejs.org/en/download) 22.20.0 or later, for the lint
  and skills CLIs.
- [lychee](https://github.com/lycheeverse/lychee#installation), for link
  checks.
- [Claude Code](https://code.claude.com/docs/en/setup) (optional), for the
  development skills and the Markdown lint hook.

## Usage

TODO: Add content.

## Development

Agent skills used while developing this repository are managed with
[skills.sh](https://www.skills.sh/) and pinned in `skills-lock.json`. To
restore them:

```sh
npx skills experimental_install
```

## Quality checks

```sh
npx markdownlint-cli2
lychee .
```

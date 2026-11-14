# markdown-editor

An agent skill to write and edit a project's Markdown files in its own
[markdownlint-cli2](https://github.com/DavidAnson/markdownlint-cli2/tree/v0.24.1)
style (or markdownlint's defaults), check links with
[lychee](https://github.com/lycheeverse/lychee/tree/lychee-v0.24.2), and set
up starter configs, including an optional GitHub Actions workflow. It never
touches Markdown outside the project or ignored by its configs, such as issue
or PR bodies being drafted. It works with or without git.

## Install

```sh
npx skills add gilbertotcc/agent-skills --skill markdown-editor
```

## Contents

| Path                                             | Purpose                                                  |
| ------------------------------------------------ | -------------------------------------------------------- |
| [scripts/lint.sh](scripts/lint.sh)               | Lint project Markdown; `--fix` to auto-fix.              |
| [scripts/check-links.sh](scripts/check-links.sh) | Check links with lychee.                                 |
| [scripts/setup.sh](scripts/setup.sh)             | Copy starter configs and CI workflow, never overwriting. |
| [assets/](assets/)                               | Starter lint, link-check and GitHub Actions configs.     |
| [references/](references/)                       | Link-fixing and citation guides.                         |

## Requirements and data use

- Bash, plus markdownlint-cli2 on PATH or Node.js with `npx` (the first run
  downloads it from npm). git is optional.
- Optional lychee for link checks; it sends a request to every URL it checks.
- No accounts or environment variables; nothing else leaves the machine.

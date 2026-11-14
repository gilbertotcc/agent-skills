# markdown-editor

An agent skill to write and edit a repository's Markdown files in its own
markdownlint-cli2 style (or markdownlint's defaults), check links with lychee,
and set up starter configs. It never touches Markdown outside the repository or
ignored by its configs, such as issue or PR bodies being drafted.

## Install

```sh
npx skills add gilbertotcc/agent-skills --skill markdown-editor
```

## Contents

| Path                                             | Purpose                                                                     |
| ------------------------------------------------ | --------------------------------------------------------------------------- |
| [scripts/lint.sh](scripts/lint.sh)               | Lint repository Markdown; `--fix` to auto-fix.                              |
| [scripts/check-links.sh](scripts/check-links.sh) | Check links with lychee.                                                    |
| [scripts/setup.sh](scripts/setup.sh)             | Copy starter configs without overwriting.                                   |
| [assets/](assets/)                               | Starter configs: `.markdownlint-cli2.yaml`, `lychee.toml`, `.lycheeignore`. |
| [references/](references/)                       | Link-fixing and citation guides.                                            |

## Requirements and data use

- Bash and git; markdownlint-cli2 on PATH, or Node.js with `npx` (the first
  run downloads it from npm) ([Anson, 2026]).
- Optional lychee ([lychee contributors, 2026]) for link checks; it sends a
  request to every URL it checks.
- No accounts or environment variables; nothing else leaves the machine.

## References

- [Anson, 2026] Anson, D. (2026). *markdownlint-cli2* (Version 0.24.1)
  [Computer software]. GitHub.
- [lychee contributors, 2026] lychee contributors. (2026). *lychee* (Version
  0.24.2) [Computer software]. GitHub.

[Anson, 2026]: https://github.com/DavidAnson/markdownlint-cli2/tree/v0.24.1
[lychee contributors, 2026]: https://github.com/lycheeverse/lychee/tree/lychee-v0.24.2

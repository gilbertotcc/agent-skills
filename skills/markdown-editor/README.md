# markdown-editor

An agent skill to write and edit a project's Markdown files in its own
[markdownlint-cli2](https://github.com/DavidAnson/markdownlint-cli2/tree/v0.24.1)
style (or markdownlint's defaults), check links with
[lychee](https://github.com/lycheeverse/lychee/tree/lychee-v0.24.2), and set
up starter configs, including an optional GitHub Actions workflow. Text
bound for external tools, such as issue or PR bodies, stays out of scope.

## Install

```sh
npx skills add gilbertotcc/agent-skills --skill markdown-editor
```

## Requirements and data use

- markdownlint-cli2 on PATH, or Node.js with `npx` (the first run
  downloads it from npm).
- Optional lychee for link checks; it sends a request to every URL it checks.
- No accounts or environment variables; nothing else leaves the machine.

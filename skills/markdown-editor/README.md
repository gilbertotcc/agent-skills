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

## Requirements

Install these yourself. The agent reports a missing tool, and installs it
only when you explicitly ask and its configuration (e.g. sandbox or
permission settings) allows it.

- **markdownlint-cli2** (required): install [Node.js](https://nodejs.org/)
  and `npx` runs it with no further step, or install it, e.g.

  ```sh
  brew install markdownlint-cli2     # macOS
  npm install -g markdownlint-cli2   # any platform with Node.js
  ```

- **lychee** (optional, for link checks): see the
  [lychee installation guide](https://lychee.cli.rs/guides/getting-started/),
  e.g.

  ```sh
  brew install lychee    # macOS
  cargo install lychee   # any platform with Rust
  ```

## Security & Privacy

- Data leaving the machine: through `npx`, the first run downloads
  markdownlint-cli2 from npm; lychee sends a request to every URL it
  checks. Nothing else leaves the machine.
- Credentials: none; no accounts or environment variables.
- Local side effects: `markdownlint-cli2 --fix` rewrites Markdown files in
  place. Setup, only when you ask, copies starter configs and an optional
  GitHub Actions workflow, and never overwrites existing files.

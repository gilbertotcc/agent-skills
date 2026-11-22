# markdown-editor

An agent skill that keeps a project's Markdown files consistently
formatted and their links reachable. Text bound for external
tools, such as issue or PR bodies and chat messages, stays out of scope.

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

- **curl** (optional, rechecks broken links): preinstalled on macOS, most
  Linux distributions and Windows 10 or later; else see
  [curl downloads](https://curl.se/download.html).

To run them by hand, from the project root:

```sh
npx --yes markdownlint-cli2 "**/*.md"   # lint every Markdown file
lychee --no-progress .                  # check links
```

## Security & Privacy

- Data leaving the machine:
  - npm: through `npx`, the first run downloads markdownlint-cli2; the
    optional starter GitHub Actions workflow does the same in CI.
  - Linked sites: lychee sends a request to every URL it checks. For a
    broken link, the agent rechecks only its HTTP status, without reading
    the page.
  - Web search: only with your consent, to find a replacement for a dead
    link. The agent treats results as untrusted and asks you to confirm
    any replacement.
  - Nothing else leaves the machine.
- Credentials: none; no accounts or environment variables.
- Local side effects: `markdownlint-cli2 --fix` rewrites Markdown files in
  place. Setup, only when you ask, copies starter configs and an optional
  GitHub Actions workflow (its actions pinned to commit SHAs), and never
  overwrites existing files.

## How it works

After each edit, the agent lints the file and fixes the content instead of
turning rules off. Once the content is final, it checks the links. It follows
the project's own configuration, or markdownlint's defaults if there is none.
When you ask, it can also set up starter configs and an optional GitHub
Actions workflow.

The author chose two tools, based on long experience with them and the use
cases they have handled in past projects:

- [markdownlint-cli2](https://github.com/DavidAnson/markdownlint-cli2/tree/v0.24.1)
  is a linter. It checks Markdown against style rules, such as heading
  order and line length, and can fix many problems automatically.
- [lychee](https://github.com/lycheeverse/lychee/tree/lychee-v0.24.2) is a
  link checker. It visits each link and reports the ones that no longer work.

## References

- What each lint rule checks and how to fix a reported issue:
  [markdownlint rules](https://github.com/DavidAnson/markdownlint/blob/v0.42.2/README.md)
- How to set rules, globs and ignored paths for a project:
  [markdownlint-cli2 configuration](https://github.com/DavidAnson/markdownlint-cli2#configuration)
- How to install and configure the link checker, and exclude links from
  it: [lychee](https://lychee.cli.rs/)

---
name: markdown-editor
description: >-
  Write and edit a project's Markdown files in its own markdownlint-cli2
  style and check their links. Use for project .md files, not for issue/PR
  bodies or other text bound for external tools.
license: MIT
compatibility: >-
  Needs markdownlint-cli2, or Node.js with npx (first run downloads it).
  lychee (link checks) is optional.
---

# Markdown editor

## Scope

The skill covers the project's own Markdown files. Run every command below
from the project root (the git top level, else the directory holding the
markdownlint or lychee config): the tools only read the root config, and
its ignores, from there.

Text bound for an external tool — an issue, PR or comment body, a chat
message, notes for the user — stays out of the workflow:

- draft it outside the project (a temporary or scratch directory) and
  pass it to the tool directly, e.g. `gh issue create --body-file <tmp>`;
- write one line per paragraph or list item: the project's line-length
  and other style rules apply only to its own files;
- don't lint or link-check it.

## Core principle: never invent a house style

Style comes from the project's
[markdownlint-cli2](https://github.com/DavidAnson/markdownlint-cli2/tree/v0.24.1)
config (`.markdownlint-cli2.*` or `.markdownlint.*`), else markdownlint's
defaults. Running the linter and fixing what it reports is enough; don't
apply a remembered style. markdownlint-cli2 is the only tool that rewrites
Markdown here: other formatters fight its rules.

## Workflow

After each change to a project `.md` file, before calling the task done:

```sh
npx --yes markdownlint-cli2 --no-globs --fix <file>  # 1. lint
lychee --no-progress <file>                          # 2. links
```

Use `markdownlint-cli2` directly when it is on PATH. `--no-globs` lints
just the given file instead of every file the config's `globs` select.

1. **Lint.** Exit 1 means issues remain that `--fix` can't fix: edit the
   file (rewrite the content, don't disable the rule) and rerun until it
   exits 0. "Linting: 0 files" means the config ignores the file.
2. **Check links**, once the content is final (network-bound). Fix or
   remove broken links; for links that look fine but fail, follow
   [references/broken-links.md](references/broken-links.md). If lychee is
   not installed, tell the user the links were not checked.
3. **Repeat** both steps if anything changed.

## Sweep the project

To check every project Markdown file at once (e.g. before a commit):

```sh
npx --yes markdownlint-cli2 --fix                     # config has globs
npx --yes markdownlint-cli2 --fix "**/*.md" "#node_modules"  # it doesn't
lychee --no-progress --extensions md .
```

Drop `--fix` to only report. If the config sets `fix: true`, every run
fixes in place, so review the diff. Report files checked, issues fixed and
issues left, then fix the rest as in the workflow.

## Set up linting and link checks

Only when the user asks, or agrees after finding no config. Copy the
starter configs from [assets/](assets/) into the project root, never over
an existing file, and skip a tool that already has any config:

| Asset                    | Target                                 | Skip if present               |
| ------------------------ | -------------------------------------- | ----------------------------- |
| `markdownlint-cli2.yaml` | `.markdownlint-cli2.yaml`              | any markdownlint config       |
| `lychee.toml`            | `lychee.toml`                          | `lychee.toml`/`.lycheeignore` |
| `lycheeignore`           | `.lycheeignore`                        | `lychee.toml`/`.lycheeignore` |
| `check-markdown.yml`     | `.github/workflows/check-markdown.yml` | a workflow running either     |

Offer the workflow only for a project on GitHub, and add it only if the
user agrees. Then tune the configs with the user: add vendored or generated
docs to `ignores` and `exclude_path` (regular expressions, not globs), and
adjust rules to match existing files.

## Writing content

Beyond what the linter enforces:

- Give every document exactly one top-level (`#`) heading.
- Tag fenced code blocks with their language (```` ```sh ````,
  ```` ```json ````) unless the config disables MD040.
- Use relative links for files in the same repository.
- Keep each emphasized span (`*...*`, `**...**`) on one line when
  wrapping prose; move the line break before or after it.
- Cite sources with the project's own convention (agent instructions such
  as `AGENTS.md`, contributing docs, existing files); if it has none, follow
  [references/citations.md](references/citations.md).
- Add a spelling or prose-style pass (e.g. British vs. American English)
  only when the project's config or agent instructions ask for one.

## Fixing what `--fix` leaves

The output names the rule and line (e.g. `README.md:12 MD013/line-length`).
Read that rule's entry in the
[markdownlint rules](https://github.com/DavidAnson/markdownlint/blob/v0.42.1/doc/Rules.md),
then edit the line: split long sentences, fix heading levels, add the
missing blank line or language tag.

## References

- [markdownlint-cli2 configuration](https://github.com/DavidAnson/markdownlint-cli2/tree/v0.24.1#configuration):
  config files, `globs`, `ignores`, `fix`.
- [lychee: excluding links](https://lychee.cli.rs/recipes/excluding-links/):
  `.lycheeignore` and `exclude_path`.

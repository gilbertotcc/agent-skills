---
name: markdown-editor
description: >-
  Write and edit a repository's Markdown files in its own markdownlint-cli2
  style and check their links. Use for repo .md files, not for issue/PR
  bodies or other text bound for external tools.
license: MIT
compatibility: >-
  Needs bash, git, and markdownlint-cli2 or Node.js with npx (first run
  downloads it). lychee is optional, for link checks.
---

# Markdown editor

Script paths are relative to this skill's directory.

## Scope

The skill covers Markdown files that belong to the repository: inside its
git work tree and not ignored by its markdownlint-cli2 or lychee config
(without a config, not ignored by git). The scripts enforce this and print
`skipped (...)` for any other path.

Text bound for an external tool — an issue, PR or comment body, a chat
message, notes for the user — stays out of the workflow:

- draft it outside the repository (a temporary or scratch directory) and
  pass it to the tool directly, e.g. `gh issue create --body-file <tmp>`;
- write one line per paragraph or list item: the repository's line-length
  and other style rules apply only to its own files;
- don't run this skill's scripts on it.

## Core principle: never invent a house style

Style comes from markdownlint-cli2 ([Anson, 2026b]), resolved in this order:

1. the repository's config (`.markdownlint-cli2.{jsonc,yaml,cjs,mjs}` or
   `.markdownlint.{jsonc,json,yaml,yml,cjs,mjs}`), which takes full
   precedence;
2. otherwise markdownlint's defaults ([Anson, 2026a]): ATX headings, 80-char
   lines, consistent list markers, blank lines around blocks, fenced code,
   one trailing newline.

Running the linter and fixing what it reports is enough; don't apply a
remembered style. markdownlint-cli2 is the only tool that rewrites Markdown
here: other formatters fight its rules (emphasis, list markers, blank lines).

## Workflow

After each change to a repository `.md` file, before calling the task done:

1. **Lint**: `scripts/lint.sh --fix <file>`. It applies the fixes it can
   and reports the rest (exit 1). Fix those by editing the file — rewrite
   the content, don't disable the rule — and rerun until it exits 0.
2. **Check links**, once the content is final (network-bound):
   `scripts/check-links.sh <file>`. Fix or remove broken links; for links
   that look fine but fail, follow
   [references/broken-links.md](references/broken-links.md). Exit 3 means
   lychee is missing: tell the user the URLs were not checked.
3. **Repeat** both steps if anything changed.

Exit 2 from either script is a usage or environment error (e.g. not in a
git repository, or neither markdownlint-cli2 nor npx available): relay its
message and install hint to the user instead of treating the check as
passed.

## Sweep the repository

To check every repository Markdown file at once (e.g. before a commit), run
the scripts without files:

```sh
scripts/lint.sh          # report only
scripts/lint.sh --fix    # apply fixes, report the rest
scripts/check-links.sh
```

With a config, the config's `globs` and `ignores` (markdownlint-cli2) and
`exclude_path` / `.lycheeignore` (lychee) choose the files; without one,
git-tracked and unignored `.md` files. A config with `fix: true` makes
every run fix in place (the script prints a `note:`); review the diff.
Report files checked, issues fixed and issues left, then fix the rest as in
the workflow.

## Set up linting and link checks

Only when the user asks, or agrees after a check finds no config:

```sh
scripts/setup.sh [dir]   # dir defaults to the git root
```

It copies the starter configs in [assets/](assets/) (80-char lines, ATX
headings, aligned tables, `.gitignore`-aware) and skips any file or tool
that already has a config, so it never overrides the repository's style.
Then tune them with the user: add vendored or generated docs to `ignores`
and `exclude_path`, and adjust rules to match existing files. See the
markdownlint-cli2 configuration docs ([Anson, 2026b]).

## Writing content

Beyond what the linter enforces:

- Give every document exactly one top-level (`#`) heading.
- Tag fenced code blocks with their language (```` ```sh ````,
  ```` ```json ````) unless the config disables MD040.
- Use relative links for files in the same repository.
- Cite sources with the repository's own convention (agent instructions such
  as `AGENTS.md`, contributing docs, existing files); if it has none, follow
  [references/citations.md](references/citations.md).
- Add a spelling or prose-style pass (e.g. British vs. American English)
  only when the repository's config or agent instructions ask for one.

## Fixing what `--fix` leaves

The output names the rule and line (e.g. `README.md:12 MD013/line-length`).
Read that rule's entry in the markdownlint rules ([Anson, 2026a]) for what
it expects, then edit the line: split long sentences, fix heading levels,
add the missing blank line or language tag.

## References

[Anson, 2026a] Anson, D. (2026). *markdownlint rules* (Version 0.42.1)
[Computer software documentation]. GitHub.

[Anson, 2026b] Anson, D. (2026). *markdownlint-cli2* (Version 0.24.1)
[Computer software]. GitHub.

[Anson, 2026a]: https://github.com/DavidAnson/markdownlint/blob/v0.42.1/doc/Rules.md
[Anson, 2026b]: https://github.com/DavidAnson/markdownlint-cli2/tree/v0.24.1#configuration

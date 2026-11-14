---
name: cli-designer
description: >-
  Design, validate and extend command-line interfaces with the Command Line
  Interface Guidelines (clig.dev). Use to define a command or subcommand,
  review a CLI, or suggest missing commands.
license: MIT
compatibility: >-
  Network access is optional: the skill reads clig.dev live and falls back
  to its bundled checklist.
---

# CLI designer

Design, review and extend a command-line interface following the
[Command Line Interface Guidelines](https://clig.dev/) (clig.dev). There are
three modes: **design** a command, **validate** a CLI, **suggest** commands.

## Guideline sources

When sources disagree, the higher one wins:

1. **Project guidelines.** Look for CLI rules in, or linked from,
   `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING*` or `docs/` (e.g.
   `docs/cli-guidelines.md`). Where a project rule conflicts with clig.dev,
   follow the project and say so.
2. **clig.dev, read live.** `https://clig.dev/llms.txt` is about 72 KB, so
   read only the sections the task needs. Headings are `### <Name>`, e.g.
   `Output`, `Errors`, `Arguments and flags`, `Interactivity`,
   `Subcommands`, `Configuration`, `Environment variables`:

   ```sh
   curl -sL https://clig.dev/llms.txt |
     awk '/^### (Output|Errors)/{p=1;print;next} /^##+ /{p=0} p'
   ```

   A web-fetch tool works too.
3. **Bundled checklist.** [references/checklist.md](references/checklist.md)
   is the list to walk through, and the fallback when the live guidelines
   can't be read. If that happens, tell the user.

Cite the source of each rule you apply (project file, clig.dev section, or
checklist). Don't restate clig.dev from memory.

## Before any mode

- Map the existing command tree: run `<cli> --help` (and the same per
  subcommand) if the tool is built and the call is harmless, or read the
  command definitions in the code.
- Identify the parsing library from the manifest (`pyproject.toml`,
  `go.mod`, `Cargo.toml`, `package.json`, `pom.xml`, `*.csproj`, `Gemfile`)
  and match its patterns and the CLI's existing naming.
- If the project has no CLI yet, propose a library from
  [references/libraries.md](references/libraries.md).

## Design a command

1. Work out what the operation needs: inputs, outputs, side effects, and
   whether it is destructive or slow.
2. Decide the interface, using the checklist sections Arguments and flags,
   Subcommands, Output and Interactivity:
   - the name and its place in the tree (keep the existing `noun verb` or
     `verb noun` order and verb set);
   - flags over positional arguments, standard flag names, and a long form
     for every flag;
   - the stdout/stderr split, `--json` or `--plain`, and exit codes;
   - confirmation, `--force`, `--dry-run` and `--no-input` for destructive
     or interactive commands;
   - how secrets get in (a file or stdin, never a flag or env var), and
     config precedence.
3. Deliver:
   - a synopsis;
   - draft `--help` text that starts with examples;
   - exit codes;
   - a short rationale citing the rules behind non-obvious choices.

   Implement it only when the user asks, in the project's library.

## Validate a CLI

1. Scope the review: the diff, the commands the user names, or the whole
   CLI when asked. Check the change itself, not the codebase in general.
2. Walk each checklist section against it. Where possible, observe real
   behavior with harmless calls only: `--help`, `--version`, no arguments,
   piping to `cat` (color and animation off), and checking which stream
   errors go to. Never run commands that change state.
3. Report, grouped by section, most severe first:
   - **Fail**: `file:line` (or the command run), what is wrong, the rule
     broken and where it comes from, and a suggested fix;
   - **N/A**: a whole section that doesn't apply, with one line on why;
   - passing items: don't list them.

## Suggest commands

1. Inventory the commands, flags and env vars the CLI has.
2. Compare them with the checklist's **(surface)** items and with
   consistency gaps, e.g. a noun missing a verb its siblings have
   (`list`/`get`/`create`/`delete`), a flag named differently across
   commands, or no machine-readable output.
3. Deliver a prioritized list. Each item has a synopsis, the reason with
   its rule, and the effort (flag only, new command, or breaking change).
   Mark breaking changes and suggest a deprecation path (see
   Future-proofing).

## Boundaries

- Report and propose first. Edit code only when the user asks after seeing
  the findings, then re-check only what changed.
- Keep proposals in the project's language, library and style. Never
  switch the parsing library unless asked.

## Example

Request: "Add a way to delete a bookmark" to a CLI with
`bookmarks list|get`.

````text
Synopsis: mycli bookmarks delete <id>... [--force] [--dry-run] [--json]

Delete one or more bookmarks.

Examples:
  mycli bookmarks delete 42
  mycli bookmarks list --json | jq -r '.[].id' | mycli bookmarks delete -

Options:
  -f, --force     Don't ask for confirmation (required without a TTY)
  -n, --dry-run   Show what would be deleted
      --json      Print deleted IDs as JSON
  -h, --help      Show this help

Exit codes: 0 deleted, 1 error, 2 usage error, 3 not found
Rationale: noun-verb like its siblings (Subcommands); asks y/N for a
moderate remote deletion, --force for scripts (Arguments and flags);
`-` reads IDs from stdin (Arguments and flags).
````

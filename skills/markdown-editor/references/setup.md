# Setup

Copy the starter configs from [assets/](../assets/) into the project root.
Never overwrite an existing file. Before copying anything, check once per
tool whether it already has any config, and skip that tool's rows if so
(copying `lychee.toml` must not make you skip `.lycheeignore`):

| Asset                    | Target                                 | Skip if present               |
| ------------------------ | -------------------------------------- | ----------------------------- |
| `markdownlint-cli2.yaml` | `.markdownlint-cli2.yaml`              | any markdownlint config       |
| `lychee.toml`            | `lychee.toml`                          | `lychee.toml`/`.lycheeignore` |
| `lycheeignore`           | `.lycheeignore`                        | `lychee.toml`/`.lycheeignore` |
| `check-markdown.yml`     | `.github/workflows/check-markdown.yml` | a workflow running either     |

Offer the workflow only for a project hosted on GitHub, and add it only if
the user agrees. It lints and checks links on changes to Markdown or the
configs. Its actions are pinned to commit SHAs, with the tag in a
comment; keep them pinned when updating, e.g. with Dependabot.

Then tune the configs with the user:

- add vendored or generated docs to `ignores` (globs; see the
  [markdownlint-cli2 configuration][mdl-config])
  and `exclude_path` (regular expressions, not globs; see
  [lychee: excluding links](https://lychee.cli.rs/recipes/excluding-links/));
- if the project installs agent skills, find where they live (e.g.
  `.agents/skills/`, or agent folders such as `.claude/skills/`; check the
  project, don't assume) and skip them in both configs: sweeps run lychee
  with `--hidden`, so dot-directories are checked too;
- skip locally excluded paths explicitly: lychee skips paths in
  `.gitignore`, `.git/info/exclude` and the global excludes file, but
  markdownlint-cli2's `gitignore: true` reads only `.gitignore` files, so
  add such paths to `ignores` or `.gitignore`;
- adjust rules to match the existing files.

[mdl-config]: https://github.com/DavidAnson/markdownlint-cli2/tree/v0.24.1#configuration
